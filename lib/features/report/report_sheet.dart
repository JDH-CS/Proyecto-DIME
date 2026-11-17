import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/app_state.dart';
import 'report_data.dart';
import 'report_pdf.dart';

/// Menú para elegir el periodo y generar el informe en PDF.
Future<void> mostrarInformeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SafeArea(top: false, child: _ReportSheet(host: context)),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.host});

  final BuildContext host;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _opciones = [
    (1, '1 mes', 'Solo el mes actual'),
    (3, '3 meses', 'Los últimos 3 meses'),
    (6, '6 meses', 'Los últimos 6 meses'),
    (12, '1 año', 'Los últimos 12 meses'),
  ];

  int _meses = 3;
  bool _generando = false;

  String _rango(int meses) {
    final ahora = DateTime.now();
    final desde = DateTime(ahora.year, ahora.month - (meses - 1), 1);
    return meses == 1 ? Fmt.mesLargo(ahora) : '${Fmt.mesLargo(desde)} a ${Fmt.mesLargo(ahora)}';
  }

  Future<void> _generar() async {
    setState(() => _generando = true);
    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(widget.host);

    try {
      final datos = ReportData.desdeEstado(state, _meses);
      final bytes = await generarInformePdf(datos);
      final h = DateTime.now();
      final nombre =
          'Informe_DIME_${h.year}-${h.month.toString().padLeft(2, '0')}-${h.day.toString().padLeft(2, '0')}.pdf';

      // Abre el menú del sistema: guardar en Archivos / Drive, compartir, etc.
      await Printing.sharePdf(bytes: bytes, filename: nombre);
      if (mounted) navigator.pop();
    } catch (e) {
      debugPrint('Error al generar el informe: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('No se pudo generar el informe. Intenta de nuevo.')));
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Generar informe financiero',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Elige el periodo. El informe incluye resumen, gráficas, gastos por categoría, presupuesto, patrimonio neto y observaciones.',
            style: t.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          for (final (meses, titulo, sub) in _opciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _meses == meses ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SoftCard(
                  onTap: _generando ? null : () => setState(() => _meses = meses),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titulo,
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text('$sub · ${_rango(meses)}',
                                style: t.bodySmall?.copyWith(color: Colors.black54)),
                          ],
                        ),
                      ),
                      Icon(
                        _meses == meses
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _meses == meses ? cs.primary : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _generando ? null : _generar,
            icon: _generando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label: Text(_generando ? 'Generando...' : 'Generar PDF'),
          ),
        ],
      ),
    );
  }
}
