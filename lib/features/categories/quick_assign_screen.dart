import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/categoria.dart';
import '../../state/app_state.dart';

/// Asignación rápida: el usuario elige categorías de una en una y les asigna
/// presupuesto hasta que el dinero por asignar llegue a cero.
class QuickAssignScreen extends StatelessWidget {
  const QuickAssignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final restante = s.dineroParaAsignar;
    final terminado = restante <= 0.004;
    final cats = s.categorias;

    return Scaffold(
      appBar: AppBar(title: const Text('Asignar dinero')),
      body: SafeArea(
        child: Column(
          children: [
            // Contador fijo arriba
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SoftCard(
                color: cs.primary,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            terminado ? '¡Todo asignado!' : 'Dinero por asignar',
                            style: t.titleSmall?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Fmt.moneda(terminado ? 0 : restante),
                            style: t.headlineMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      terminado ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                      size: 36,
                      color: cs.onPrimary.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  terminado
                      ? 'Ya le diste un destino a cada dólar.'
                      : 'Toca una categoría para asignarle dinero.',
                  style: t.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                itemCount: cats.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = cats[i];
                  return SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    onTap: terminado ? null : () => _abrirAsignacion(context, c),
                    child: Row(
                      children: [
                        CategoryIconBox(icono: c.icono),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              Text('Asignado: ${Fmt.moneda(s.asignado(c.id))}',
                                  style: t.bodySmall?.copyWith(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: terminado ? Colors.black26 : cs.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: terminado
                    ? FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Listo'),
                      )
                    : OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Terminar más tarde'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _abrirAsignacion(BuildContext context, Categoria c) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SafeArea(top: false, child: _AssignSheet(categoria: c)),
  );
}

class _AssignSheet extends StatefulWidget {
  const _AssignSheet({required this.categoria});

  final Categoria categoria;

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? _parse(String? v) => double.tryParse((v ?? '').replaceAll(',', '.'));

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<AppState>();
    final monto = double.parse(_parse(_ctrl.text)!.toStringAsFixed(2));
    final messenger = ScaffoldMessenger.of(context);

    s.asignarMas(widget.categoria.id, monto);
    final quedan = s.dineroParaAsignar;

    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(quedan <= 0.004
            ? '¡Listo! Asignaste todo tu dinero.'
            : '${Fmt.moneda(monto)} para ${widget.categoria.nombre}. '
                'Te quedan ${Fmt.moneda(quedan)}.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = context.read<AppState>();
    final restante = s.dineroParaAsignar;
    final actual = s.asignado(widget.categoria.id);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CategoryIconBox(icono: widget.categoria.icono, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.categoria.nombre,
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Asignado ahora: ${Fmt.moneda(actual)}',
                            style: t.bodySmall?.copyWith(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Monto a añadir',
                  prefixText: '\$ ',
                  helperText: 'Disponible por asignar: ${Fmt.moneda(restante)}',
                ),
                validator: (v) {
                  final m = _parse(v);
                  if (m == null || m <= 0) return 'Ingresa un monto mayor a 0';
                  if (m > restante + 0.004) {
                    return 'Solo te quedan ${Fmt.moneda(restante)} por asignar';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _confirmar(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in const [10.0, 50.0, 100.0])
                    if (v < restante)
                      ActionChip(
                        label: Text('+\$${v.toInt()}'),
                        onPressed: () => _ctrl.text = v.toStringAsFixed(2),
                      ),
                  ActionChip(
                    avatar: const Icon(Icons.done_all_rounded, size: 18),
                    label: Text('Todo (${Fmt.moneda(restante)})'),
                    onPressed: () => _ctrl.text = restante.toStringAsFixed(2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _confirmar, child: const Text('Asignar')),
            ],
          ),
        ),
      ),
    );
  }
}