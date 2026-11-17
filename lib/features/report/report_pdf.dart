import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/accessibility/accessibility.dart';
import '../../core/utils/formatters.dart';
import 'report_data.dart';
import 'report_templates.dart';

final _brand = PdfColor.fromHex('#A2081A');
final _brandSoft = PdfColor.fromHex('#FEE7E9');
final _ink = PdfColor.fromHex('#180104');
final _muted = PdfColors.grey700;

PdfColor _pdf(Color c) => PdfColor.fromInt(c.toARGB32());

double _niceTop(double v) {
  if (v <= 0) return 100;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final n = v / mag;
  final paso = n <= 1 ? 1 : (n <= 2 ? 2 : (n <= 5 ? 5 : 10));
  return paso * mag;
}

String _abrev(num v) {
  final a = v.abs();
  final signo = v < 0 ? '-' : '';
  if (a >= 1000) {
    final k = a / 1000;
    return '$signo\$${k.toStringAsFixed(k == k.roundToDouble() ? 0 : 1)}k';
  }
  return '$signo\$${a.toInt()}';
}

// ───────────── Bloques de texto ─────────────
pw.Widget _titulo(String texto) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brand),
      ),
    );

pw.Widget _parrafo(String texto) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(texto, style: pw.TextStyle(fontSize: 10, lineSpacing: 2, color: _ink)),
    );

pw.Widget _vineta(String texto) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('- ', style: pw.TextStyle(fontSize: 10, color: _brand)),
          pw.Expanded(
            child: pw.Text(texto, style: pw.TextStyle(fontSize: 10, lineSpacing: 2, color: _ink)),
          ),
        ],
      ),
    );

pw.Widget _kpi(String etiqueta, String valor, PdfColor color, {bool ultimo = false}) => pw.Expanded(
      child: pw.Container(
        margin: pw.EdgeInsets.only(right: ultimo ? 0 : 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _brandSoft,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(etiqueta, style: pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(
              valor,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );

pw.Widget _leyenda(List<(PdfColor, String)> items) => pw.Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final it in items)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(width: 9, height: 9, color: it.$1),
              pw.SizedBox(width: 4),
              pw.Text(it.$2, style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
      ],
    );

pw.Widget _celda(pw.Widget w) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: w,
    );

pw.Widget _txt(String t, {bool negrita = false, bool derecha = false, PdfColor? color}) => pw.Text(
      t,
      textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? _ink,
      ),
    );

pw.Widget _tabla({
  required List<String> encabezados,
  required List<List<pw.Widget>> filas,
  required Map<int, pw.TableColumnWidth> anchos,
  Set<int> derecha = const {},
}) {
  return pw.Table(
    columnWidths: anchos,
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _brandSoft),
        children: [
          for (var i = 0; i < encabezados.length; i++)
            _celda(_txt(encabezados[i], negrita: true, derecha: derecha.contains(i))),
        ],
      ),
      for (final f in filas) pw.TableRow(children: [for (final c in f) _celda(c)]),
    ],
  );
}

// ───────────── Gráficas ─────────────
pw.Widget _graficaIngresosGastos(ReportData d, PdfColor cIng, PdfColor cGas) {
  final labels = [for (final m in d.mensual) Fmt.mesCorto(m.mes)];
  final maxV = d.mensual.fold(0.0, (m, x) => math.max(m, math.max(x.ingresos, x.gastos)));
  final top = _niceTop(maxV);
  final ticks = [for (var i = 0; i <= 4; i++) top * i / 4];
  final w = d.mensual.length > 6 ? 8.0 : 14.0;

  return pw.SizedBox(
    height: 190,
    child: pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels, marginStart: 28, marginEnd: 28, ticks: true),
        yAxis: pw.FixedAxis(ticks, format: (v) => _abrev(v), divisions: true),
      ),
      datasets: [
        pw.BarDataSet(
          color: cIng,
          legend: 'Ingresos',
          width: w,
          offset: -(w / 2 + 1),
          data: [for (var i = 0; i < d.mensual.length; i++) pw.PointChartValue(i.toDouble(), d.mensual[i].ingresos)],
        ),
        pw.BarDataSet(
          color: cGas,
          legend: 'Gastos',
          width: w,
          offset: w / 2 + 1,
          data: [for (var i = 0; i < d.mensual.length; i++) pw.PointChartValue(i.toDouble(), d.mensual[i].gastos)],
        ),
      ],
    ),
  );
}

pw.Widget _graficaPastel(ReportData d) {
  return pw.SizedBox(
    height: 170,
    child: pw.Chart(
      grid: pw.PieGrid(),
      datasets: [
        for (final c in d.porCategoria)
          pw.PieDataSet(
            value: c.monto,
            color: _pdf(c.color),
            legend: c.pct >= 6 ? '${c.pct.toStringAsFixed(0)}%' : '',
          ),
      ],
    ),
  );
}

pw.Widget _graficaPatrimonio(ReportData d) {
  final labels = [for (final p in d.patrimonio) Fmt.mesCorto(p.mes)];
  final vals = [for (final p in d.patrimonio) p.valor];
  final lo = vals.reduce(math.min);
  final hi = vals.reduce(math.max);
  final pad = math.max(50.0, (hi - lo) * 0.1);
  final ymin = lo - pad;
  final ymax = hi + pad;
  final ticks = [for (var i = 0; i <= 4; i++) ymin + (ymax - ymin) * i / 4];

  return pw.SizedBox(
    height: 170,
    child: pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(labels, marginStart: 24, marginEnd: 24, ticks: true),
        yAxis: pw.FixedAxis(ticks, format: (v) => _abrev(v), divisions: true),
      ),
      datasets: [
        pw.LineDataSet(
          color: _brand,
          isCurved: true,
          lineWidth: 2,
          drawSurface: true,
          data: [for (var i = 0; i < vals.length; i++) pw.PointChartValue(i.toDouble(), vals[i])],
        ),
      ],
    ),
  );
}

// ───────────── Documento ─────────────
Future<Uint8List> generarInformePdf(ReportData d) async {
  final v = d.variables();
  final cIng = _pdf(Accessibility.positive);
  final cGas = _pdf(Accessibility.negative);

  final doc = pw.Document(title: 'Informe financiero DIME', author: 'DIME');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 40),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(
                'DIME - ${ReportTemplates.titulo} de ${d.nombre}',
                style: pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generado por DIME', style: pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        // Banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(color: _brand, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DIME', style: pw.TextStyle(fontSize: 11, color: PdfColors.white, letterSpacing: 3)),
              pw.SizedBox(height: 6),
              pw.Text(
                ReportTemplates.titulo,
                style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              ),
              pw.SizedBox(height: 4),
              pw.Text(d.nombre, style: pw.TextStyle(fontSize: 12, color: PdfColors.white)),
              pw.Text(
                ReportTemplates.render(ReportTemplates.subtitulo, v),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        _parrafo(ReportTemplates.render(ReportTemplates.intro, v)),

        if (!d.hayDatos) ...[
          pw.SizedBox(height: 10),
          _parrafo(ReportTemplates.sinDatos),
        ] else ...[
          // Resumen
          _titulo('Resumen del periodo'),
          pw.Row(
            children: [
              _kpi('Ingresos', Fmt.moneda(d.ingresosTotal), cIng),
              _kpi('Gastos', Fmt.moneda(d.gastosTotal), cGas),
              _kpi(
                'Ahorro neto',
                Fmt.monedaConSigno(d.ahorroNeto),
                d.ahorroNeto >= 0 ? cIng : cGas,
              ),
              _kpi('Tasa de ahorro', '${d.tasaAhorro.toStringAsFixed(0)}%', _ink, ultimo: true),
            ],
          ),
          pw.SizedBox(height: 10),
          _parrafo(ReportTemplates.render(ReportTemplates.resumenGeneral, v)),
          _parrafo(ReportTemplates.resultado(d, v)),

          // Ingresos vs gastos
          _titulo('Ingresos vs gastos por mes'),
          _graficaIngresosGastos(d, cIng, cGas),
          pw.SizedBox(height: 6),
          _leyenda([(cIng, 'Ingresos'), (cGas, 'Gastos')]),

          // Gastos por categoría
          if (d.porCategoria.isNotEmpty) ...[
            _titulo('Gastos por categoría'),
            _graficaPastel(d),
            pw.SizedBox(height: 8),
            _tabla(
              encabezados: ['Categoría', '% del total', 'Monto'],
              anchos: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.6),
              },
              derecha: {1, 2},
              filas: [
                for (final c in d.porCategoria)
                  [
                    pw.Row(children: [
                      pw.Container(width: 9, height: 9, color: _pdf(c.color)),
                      pw.SizedBox(width: 6),
                      pw.Expanded(child: _txt(c.nombre)),
                    ]),
                    _txt('${c.pct.toStringAsFixed(1)}%', derecha: true),
                    _txt(Fmt.moneda(c.monto), derecha: true, negrita: true),
                  ],
              ],
            ),
            pw.SizedBox(height: 8),
            _parrafo(ReportTemplates.render(ReportTemplates.categoriaPrincipal, v)),
          ],

          // Comercios y gastos mayores
          if (d.topComercios.isNotEmpty) ...[
            _titulo('Dónde más gastaste'),
            _tabla(
              encabezados: ['Comercio o concepto', 'Compras', 'Monto'],
              anchos: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.6),
              },
              derecha: {1, 2},
              filas: [
                for (final c in d.topComercios)
                  [
                    _txt(c.nombre),
                    _txt('${c.veces}', derecha: true),
                    _txt(Fmt.moneda(c.monto), derecha: true, negrita: true),
                  ],
              ],
            ),
            pw.SizedBox(height: 8),
            _parrafo(ReportTemplates.render(ReportTemplates.comercioPrincipal, v)),
          ],
          if (d.topGastos.isNotEmpty) ...[
            _titulo('Mayores gastos individuales'),
            _tabla(
              encabezados: ['Fecha', 'Descripción', 'Monto'],
              anchos: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(3.4),
                2: const pw.FlexColumnWidth(1.6),
              },
              derecha: {2},
              filas: [
                for (final t in d.topGastos)
                  [
                    _txt(Fmt.fecha(t.fechaTransaccion)),
                    _txt((t.nombreComercio ?? t.descripcion)),
                    _txt(Fmt.moneda(t.monto), derecha: true, negrita: true),
                  ],
              ],
            ),
          ],

          // Presupuesto del mes
          if (d.presupuesto.isNotEmpty) ...[
            _titulo('Presupuesto del mes actual'),
            _parrafo(ReportTemplates.render(ReportTemplates.presupuestoIntro, v)),
            pw.SizedBox(height: 4),
            _tabla(
              encabezados: ['Categoría', 'Asignado', 'Gastado', 'Disponible', '%'],
              anchos: {
                0: const pw.FlexColumnWidth(2.6),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(0.9),
              },
              derecha: {1, 2, 3, 4},
              filas: [
                for (final f in d.presupuesto)
                  [
                    _txt(f.nombre),
                    _txt(Fmt.moneda(f.asignado), derecha: true),
                    _txt(Fmt.moneda(f.gastado), derecha: true),
                    _txt(Fmt.moneda(f.disponible),
                        derecha: true, negrita: true, color: f.excedida ? cGas : null),
                    _txt('${f.pct.toStringAsFixed(0)}%', derecha: true),
                  ],
              ],
            ),
            pw.SizedBox(height: 8),
            _parrafo(ReportTemplates.render(
              d.excedidas.isEmpty ? ReportTemplates.presupuestoOk : ReportTemplates.presupuestoExcedido,
              v,
            )),
          ],

          // Patrimonio
          _titulo('Patrimonio neto'),
          _parrafo(
            '${ReportTemplates.render(ReportTemplates.patrimonioTexto, v)} '
            '${d.patrimonioDesdeBanco ? ReportTemplates.patrimonioBaseBanco : ReportTemplates.patrimonioBaseManual}',
          ),
          if (d.patrimonio.length >= 2) ...[
            pw.SizedBox(height: 6),
            _graficaPatrimonio(d),
          ],

          // Observaciones
          ...() {
            final obs = ReportTemplates.observaciones(d, v);
            if (obs.isEmpty) return <pw.Widget>[];
            return <pw.Widget>[
              _titulo('Observaciones'),
              for (final o in obs) _vineta(o),
            ];
          }(),
        ],

        pw.SizedBox(height: 22),
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
        pw.Text(ReportTemplates.notaFinal, style: pw.TextStyle(fontSize: 8, color: _muted)),
      ],
    ),
  );

  return doc.save();
}
