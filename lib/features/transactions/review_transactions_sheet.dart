import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../data/models/categoria.dart';
import '../../data/models/cuenta_financiera.dart';
import '../../data/models/transaccion.dart';
import '../../state/app_state.dart';

/// Muestra, una por una, las transacciones sin categoría:
///  - Comercio reconocido: "Se asignará a [categoría], ¿aceptar?" o elegir otra.
///  - Comercio desconocido: pregunta la categoría y luego
///    "¿Quieres enlazar las transacciones de [comercio] con [categoría]?".
Future<void> revisarTransacciones(BuildContext context, List<Transaccion> lista) async {
  for (var i = 0; i < lista.length; i++) {
    if (!context.mounted) return;
    final seguir = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        top: false,
        child: _ReviewSheet(transaccion: lista[i], indice: i + 1, total: lista.length),
      ),
    );
    if (seguir != true) break; // cerrado con gesto o "Detener revisión"
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.transaccion, required this.indice, required this.total});

  final Transaccion transaccion;
  final int indice;
  final int total;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  bool _eligiendo = false; // el usuario pidió "elegir otra categoría"
  Categoria? _elegida; // categoría elegida, pendiente de "¿enlazar comercio?"

  void _asignar(Categoria c, {bool recordar = false}) {
    context.read<AppState>().asignarCategoriaTransaccion(
          widget.transaccion,
          c,
          recordar: recordar,
        );
    Navigator.pop(context, true);
  }

  void _elegir(Categoria c) {
    // Sin código de comercio no hay nada que enlazar: se asigna directo.
    if (widget.transaccion.codigoComercio == null) {
      _asignar(c);
    } else {
      setState(() => _elegida = c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final t = Theme.of(context).textTheme;
    final tx = widget.transaccion;

    final sugerida = s.sugerencia(tx);
    final opciones = tx.tipoTransaccion == 'ingreso' ? s.categoriasIngreso : s.categorias;
    final comercio = tx.nombreComercio ?? tx.descripcion;
    final cuenta = s.cuentaPorId(tx.cuentaFinancieraId);

    final titulo = widget.total == 1
        ? 'Hay una transacción nueva'
        : 'Transacción ${widget.indice} de ${widget.total}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _InfoTransaccion(tx: tx, cuenta: cuenta, comercio: comercio),
          const SizedBox(height: 20),

          if (_elegida != null) ...[
            // Paso: ¿enlazar el comercio con la categoría?
            Text(
              '¿Quieres enlazar las transacciones de $comercio con la categoría ${_elegida!.nombre}?',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Así las próximas se asignarán solas.',
              style: t.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _asignar(_elegida!, recordar: true),
              child: const Text('Sí, enlazar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _asignar(_elegida!),
              child: const Text('Solo esta vez'),
            ),
            TextButton(
              onPressed: () => setState(() => _elegida = null),
              child: const Text('Cambiar categoría'),
            ),
          ] else if (sugerida != null && !_eligiendo) ...[
            // Comercio reconocido: proponer la categoría.
            Text('Se asignará a la categoría', style: t.bodyMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                CategoryIconBox(icono: sugerida.icono, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(sugerida.nombre,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('¿Aceptar?', style: t.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => _asignar(sugerida), child: const Text('Aceptar')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _eligiendo = true),
              child: const Text('Elegir otra categoría'),
            ),
          ] else ...[
            // Comercio desconocido (o el usuario quiere elegir): lista de categorías.
            Text(
              sugerida == null
                  ? 'No reconocemos este comercio. ¿A qué categoría pertenece?'
                  : 'Elige la categoría:',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (opciones.isEmpty)
              Text('No tienes categorías disponibles. Crea una en la pestaña Categorías.',
                  style: t.bodySmall?.copyWith(color: Colors.black54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in opciones)
                    ActionChip(
                      avatar: Icon(AppIcons.of(c.icono), size: 18),
                      label: Text(c.nombre),
                      onPressed: () => _elegir(c),
                    ),
                ],
              ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Decidir después'),
              ),
              if (widget.indice < widget.total)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Detener revisión'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTransaccion extends StatelessWidget {
  const _InfoTransaccion({required this.tx, required this.cuenta, required this.comercio});

  final Transaccion tx;
  final CuentaFinanciera? cuenta;
  final String comercio;

  Widget _fila(BuildContext context, String etiqueta, String valor) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(etiqueta, style: t.bodySmall?.copyWith(color: Colors.black54)),
          ),
          Expanded(child: Text(valor, style: t.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esIngreso = tx.tipoTransaccion == 'ingreso';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(comercio,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Text(
                Fmt.monedaConSigno(esIngreso ? tx.monto : -tx.monto),
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: esIngreso ? AppTheme.positive : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fila(context, 'Código de comercio', tx.codigoComercio ?? '—'),
          _fila(context, 'Descripción', tx.descripcion),
          _fila(context, 'Fecha', Fmt.fecha(tx.fechaTransaccion)),
          if (cuenta != null) _fila(context, 'Cuenta', cuenta!.nombre),
        ],
      ),
    );
  }
}
