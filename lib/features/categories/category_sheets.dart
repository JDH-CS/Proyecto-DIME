import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/constants/category_templates.dart';
import '../../data/models/categoria.dart';
import '../../state/app_state.dart';

Future<void> _openSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(top: false, child: builder(ctx)),
  );
}

/// Paso 1 de "Añadir categoría": elegir una predeterminada o crear una personal.
Future<void> showAddCategorySheet(BuildContext context) {
  final existentes =
      context.read<AppState>().categorias.map((c) => c.nombre.toLowerCase()).toSet();
  final disponibles = CategoryTemplates.all
      .where((p) => !existentes.contains(p.$1.toLowerCase()))
      .toList();

  return _openSheet(context, (sheetCtx) {
    final t = Theme.of(sheetCtx).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Añadir categoría',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Elige una categoría predeterminada o crea la tuya.',
              style: t.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 16),
          if (disponibles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in disponibles)
                  ActionChip(
                    avatar: Icon(AppIcons.of(p.$2), size: 18),
                    label: Text(p.$1),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      showCategoryFormSheet(
                        context,
                        nombreInicial: p.$1,
                        iconoInicial: p.$2,
                        esPredeterminada: true,
                      );
                    },
                  ),
              ],
            )
          else
            Text('Ya agregaste todas las categorías predeterminadas.',
                style: t.bodySmall?.copyWith(color: Colors.black54)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetCtx);
                showCategoryFormSheet(context);
              },
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Crear categoría personal'),
            ),
          ),
        ],
      ),
    );
  });
}

/// Selector de la categoría a editar (menú de 3 puntos).
Future<void> showEditPickerSheet(BuildContext context) {
  final cats = context.read<AppState>().categorias;
  final state = context.read<AppState>();

  return _openSheet(context, (sheetCtx) {
    final t = Theme.of(sheetCtx).textTheme;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editar categoría',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Selecciona la categoría que quieres modificar.',
                  style: t.bodyMedium?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
        for (final c in cats)
          ListTile(
            leading: CategoryIconBox(icono: c.icono, size: 40),
            title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Asignado: ${Fmt.moneda(state.asignado(c.id))}'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () {
              Navigator.pop(sheetCtx);
              showCategoryFormSheet(context, editar: c);
            },
          ),
      ],
    );
  });
}

/// Formulario para crear / editar una categoría.
Future<void> showCategoryFormSheet(
  BuildContext context, {
  Categoria? editar,
  String? nombreInicial,
  String? iconoInicial,
  bool esPredeterminada = false,
}) {
  return _openSheet(
    context,
    (_) => _CategoryForm(
      host: context,
      editar: editar,
      nombreInicial: nombreInicial,
      iconoInicial: iconoInicial,
      esPredeterminada: esPredeterminada,
    ),
  );
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({
    required this.host,
    this.editar,
    this.nombreInicial,
    this.iconoInicial,
    this.esPredeterminada = false,
  });

  final BuildContext host; // contexto de la pantalla (para SnackBars)
  final Categoria? editar;
  final String? nombreInicial;
  final String? iconoInicial;
  final bool esPredeterminada;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _monto;
  late String _icono;

  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    _nombre = TextEditingController(text: e?.nombre ?? widget.nombreInicial ?? '');
    final asignado = e == null ? 0.0 : context.read<AppState>().asignado(e.id);
    _monto = TextEditingController(text: e == null ? '' : asignado.toStringAsFixed(2));
    _icono = e?.icono ?? widget.iconoInicial ?? 'shopping';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  double _parseMonto() => double.tryParse(_monto.text.replaceAll(',', '.')) ?? 0;

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<AppState>();
    final nombre = _nombre.text.trim();

    if (_editando) {
      s.editarCategoria(widget.editar!.id,
          nombre: nombre, icono: _icono, montoAsignado: _parseMonto());
    } else {
      s.addCategoria(
        nombre: nombre,
        icono: _icono,
        montoAsignado: _parseMonto(),
        esPredeterminada: widget.esPredeterminada,
      );
    }
    Navigator.pop(context);
    showSoon(widget.host, _editando ? 'Categoría actualizada' : 'Categoría añadida');
  }

  Future<void> _eliminar() async 
  {
    final messenger = ScaffoldMessenger.of(widget.host);
    final navigator = Navigator.of(context);
    final state = context.read<AppState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: const Text(
            'Se eliminará la categoría, su presupuesto y sus transacciones de prueba.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    state.eliminarCategoria(widget.editar!.id);
    navigator.pop();
    messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Categoría eliminada')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final state = context.read<AppState>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_editando ? 'Editar categoría' : 'Nueva categoría',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'Nombre', counterText: ''),
                validator: (v) {
                  final nombre = v?.trim() ?? '';
                  if (nombre.isEmpty) return 'Ingresa un nombre';
                  final repetido = state.categorias.any((c) =>
                      c.id != widget.editar?.id &&
                      c.nombre.toLowerCase() == nombre.toLowerCase());
                  return repetido ? 'Ya existe una categoría con ese nombre' : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _monto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Presupuesto mensual asignado',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return double.tryParse(v.replaceAll(',', '.')) == null ? 'Monto inválido' : null;
                },
              ),
              const SizedBox(height: 18),
              Text('Ícono', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in AppIcons.all.entries)
                    GestureDetector(
                      onTap: () => setState(() => _icono = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _icono == e.key ? cs.primary : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(e.value,
                            color: _icono == e.key ? cs.onPrimary : cs.onSurface),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _guardar,
                child: Text(_editando ? 'Guardar cambios' : 'Añadir categoría'),
              ),
              if (_editando) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _eliminar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar categoría'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
