import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/categoria.dart';
import '../../state/app_state.dart';

/// Formulario para registrar a mano un gasto o un ingreso.
Future<void> showManualTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SafeArea(top: false, child: _ManualForm(host: context)),
  );
}

class _ManualForm extends StatefulWidget {
  const _ManualForm({required this.host});

  final BuildContext host;

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();

  String _tipo = 'gasto';
  Categoria? _categoria;
  bool _categoriaError = false;
  DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fechaCtrl.text = Fmt.fecha(_fecha);
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 1, hoy.month, hoy.day),
      lastDate: hoy,
      helpText: 'Fecha de la transacción',
    );
    if (f != null) {
      setState(() {
        _fecha = f;
        _fechaCtrl.text = Fmt.fecha(f);
      });
    }
  }

  void _guardar() {
    final valido = _formKey.currentState!.validate();
    if (_categoria == null) {
      setState(() => _categoriaError = true);
      return;
    }
    if (!valido) return;

    final hoy = DateTime.now();
    final esHoy = _fecha.year == hoy.year && _fecha.month == hoy.month && _fecha.day == hoy.day;
    final fecha = esHoy ? hoy : DateTime(_fecha.year, _fecha.month, _fecha.day, 12);
    final monto = double.parse(
      (double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0).toStringAsFixed(2),
    );

    context.read<AppState>().addTransaccionManual(
          tipo: _tipo,
          monto: monto,
          descripcion: _descCtrl.text.trim(),
          categoria: _categoria!,
          fecha: fecha,
        );

    final messenger = ScaffoldMessenger.of(widget.host);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(_tipo == 'gasto' ? 'Gasto registrado' : 'Ingreso registrado'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final opciones = _tipo == 'gasto' ? s.categorias : s.categoriasIngreso;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Agregar transacción',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'gasto', label: Text('Gasto')),
                  ButtonSegment(value: 'ingreso', label: Text('Ingreso')),
                ],
                selected: {_tipo},
                onSelectionChanged: (v) => setState(() {
                  _tipo = v.first;
                  _categoria = null; // las categorías cambian según el tipo
                  _categoriaError = false;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                validator: (v) {
                  final m = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (m == null || m <= 0) return 'Ingresa un monto mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej. Almuerzo, Pago de freelance...',
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Escribe una descripción' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _fechaCtrl,
                readOnly: true,
                onTap: _elegirFecha,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 18),
              Text('Categoría', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (opciones.isEmpty)
                Text('No tienes categorías de este tipo.',
                    style: t.bodySmall?.copyWith(color: Colors.black54))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in opciones)
                      ChoiceChip(
                        avatar: Icon(AppIcons.of(c.icono), size: 18),
                        label: Text(c.nombre),
                        selected: _categoria?.id == c.id,
                        onSelected: (_) => setState(() {
                          _categoria = c;
                          _categoriaError = false;
                        }),
                      ),
                  ],
                ),
              if (_categoriaError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Elige una categoría',
                      style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
