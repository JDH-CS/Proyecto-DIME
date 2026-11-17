import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/category_color.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../data/models/categoria.dart';
import '../../../state/app_state.dart';
import '../widgets/chart_utils.dart';
import '../widgets/period_selector.dart';

class GastosSection extends StatefulWidget {
  const GastosSection({super.key});

  @override
  State<GastosSection> createState() => _GastosSectionState();
}

class _GastosSectionState extends State<GastosSection> {
  int _meses = 6;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    final cats = s.categorias;
    final data = s.gastosMensuales(_meses);

    // Totales por categoría en el periodo
    final porCat = <String, double>{
      for (final c in cats)
        c.id: data.fold(0.0, (a, m) => a + (m.porCategoria[c.id] ?? 0)),
    };
    final total = porCat.values.fold(0.0, (a, b) => a + b);
    final promedio = total / _meses;
    final ranking = [...cats]..sort((a, b) => porCat[b.id]!.compareTo(porCat[a.id]!));

    final maxY = data.fold(0.0, (m, d) => math.max(m, d.total));
    final interval = niceInterval(maxY);
    final topY = niceTop(maxY, interval);

    // Secciones del pastel
    final sections = <PieChartSectionData>[
      for (final c in ranking)
        if ((porCat[c.id] ?? 0) > 0)
          PieChartSectionData(
            value: porCat[c.id]!,
            color: CategoryColors.of(c),
            radius: 34,
            showTitle: false,
          ),
    ];
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        color: Colors.black12,
        radius: 34,
        showTitle: false,
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        PeriodSelector(meses: _meses, onChanged: (v) => setState(() => _meses = v)),
        const SizedBox(height: 16),

        // ── Tendencias de gastos (barras apiladas por categoría) ──
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tendencias de gastos',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('Gasto mensual por categoría',
                  style: t.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    maxY: topY,
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: Colors.black12, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: interval,
                          getTitlesWidget: (v, meta) =>
                              Text(abbrMoney(v), style: axisStyle),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(Fmt.mesCorto(data[i].mes), style: axisStyle),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          '${Fmt.mesCorto(data[groupIndex].mes)}\n${Fmt.moneda(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < data.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].total,
                              width: _meses == 12 ? 14 : 22,
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                              rodStackItems: _stack(data[i].porCategoria, cats),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  for (final c in cats) LegendDot(color: CategoryColors.of(c), label: c.nombre),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Gastos totales (pastel + resumen) ──
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gastos totales',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gastos totales',
                            style: t.labelMedium?.copyWith(color: Colors.black54)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(Fmt.moneda(total),
                              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 16),
                        Text('Promedio por mes',
                            style: t.labelMedium?.copyWith(color: Colors.black54)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(Fmt.moneda(promedio),
                              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              // Lista descendente por gasto
              for (final c in ranking)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: CategoryColors.of(c),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.nombre,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        total > 0 ? '${((porCat[c.id]! / total) * 100).toStringAsFixed(0)}%' : '0%',
                        style: t.bodySmall?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 84,
                        child: Text(Fmt.moneda(porCat[c.id]!),
                            textAlign: TextAlign.right,
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<BarChartRodStackItem> _stack(Map<String, double> porCategoria, List<Categoria> cats) {
    final items = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final c in cats) {
      final v = porCategoria[c.id] ?? 0;
      if (v <= 0) continue;
      items.add(BarChartRodStackItem(from, from + v, CategoryColors.of(c)));
      from += v;
    }
    return items;
  }
}
