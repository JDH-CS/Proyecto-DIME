import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/accessibility/accessibility.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../state/app_state.dart';
import '../widgets/chart_utils.dart';
import '../widgets/period_selector.dart';

class IngresosGastosSection extends StatefulWidget {
  const IngresosGastosSection({super.key});

  @override
  State<IngresosGastosSection> createState() => _IngresosGastosSectionState();
}

class _IngresosGastosSectionState extends State<IngresosGastosSection> {
  int _meses = 6;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppState>().ingresosVsGastos(_meses);
    final t = Theme.of(context).textTheme;

    // Colores según el modo de accesibilidad (verde/rojo, o azul/naranja para daltonismo)
    final colorIngreso = Accessibility.positive;
    final colorGasto = Accessibility.negative;

    final promIngresos = data.fold(0.0, (a, d) => a + d.ingresos) / data.length;
    final promGastos = data.fold(0.0, (a, d) => a + d.gastos) / data.length;
    final diferencia = promIngresos - promGastos;

    final maxY = data.fold(0.0, (m, d) => math.max(m, math.max(d.ingresos, d.gastos)));
    final interval = niceInterval(maxY);
    final topY = niceTop(maxY, interval);
    final barW = _meses == 12 ? 7.0 : (_meses == 6 ? 12.0 : 16.0);

    final bool ahorra = diferencia > 0.01;
    final bool excede = diferencia < -0.01;
    final String mensaje = ahorra
        ? 'En promedio, estás gastando menos de lo que ganas. ¡Sigue así!'
        : excede
            ? 'En promedio, estás gastando más de lo que ganas. ¡Ten cuidado!'
            : 'En promedio, estás gastando lo mismo que ganas. Intenta dejar un margen.';
    final Color colorMsg = ahorra
        ? colorIngreso
        : excede
            ? colorGasto
            : Colors.black54;
    final IconData iconoMsg = ahorra
        ? Icons.trending_up_rounded
        : excede
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        PeriodSelector(meses: _meses, onChanged: (v) => setState(() => _meses = v)),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresos vs Gastos',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('Comparación mensual',
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
                          getTitlesWidget: (v, meta) => Text(abbrMoney(v), style: axisStyle),
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
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                          return BarTooltipItem(
                            '$label\n${Fmt.moneda(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < data.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].ingresos,
                              width: barW,
                              color: colorIngreso,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: data[i].gastos,
                              width: barW,
                              color: colorGasto,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                children: [
                  LegendDot(color: colorIngreso, label: 'Ingresos'),
                  LegendDot(color: colorGasto, label: 'Gastos'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorMsg.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconoMsg, color: colorMsg),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(mensaje,
                          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(label: 'Ingreso prom.', value: Fmt.moneda(promIngresos)),
                  _Stat(label: 'Gasto prom.', value: Fmt.moneda(promGastos)),
                  _Stat(
                    label: 'Diferencia',
                    value: Fmt.monedaConSigno(diferencia),
                    color: colorMsg,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.labelMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}
