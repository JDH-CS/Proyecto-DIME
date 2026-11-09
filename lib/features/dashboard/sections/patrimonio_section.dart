import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/soft_card.dart';
import '../../../state/app_state.dart';
import '../widgets/chart_utils.dart';

class PatrimonioSection extends StatelessWidget {
  const PatrimonioSection({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppState>().patrimonio;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final inicio = data.first.valor;
    final actual = data.last.valor;
    final cambioTotal = actual - inicio;
    final cambioColor = cambioTotal > 0
        ? AppTheme.positive
        : cambioTotal < 0
            ? AppTheme.negative
            : Colors.black54;

    final minV = data.map((d) => d.valor).reduce(math.min);
    final maxV = data.map((d) => d.valor).reduce(math.max);
    final ultimo = data.length - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evolución del patrimonio neto',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text('Desde que empezaste a usar DIME',
                  style: t.bodySmall?.copyWith(color: Colors.black54)),
              const SizedBox(height: 20),
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    // Gráfica de línea (izquierda)
                    Expanded(
                      flex: 3,
                      child: LineChart(
                        LineChartData(
                          minY: math.max(0.0, minV - 400),
                          maxY: maxV + 400,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 28,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i < 0 || i > ultimo || (ultimo - i) % 3 != 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(Fmt.mesCorto(data[i].mes), style: axisStyle),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => Colors.black87,
                              getTooltipItems: (spots) => [
                                for (final s in spots)
                                  LineTooltipItem(
                                    '${Fmt.mesCorto(data[s.x.toInt()].mes)}\n${Fmt.moneda(s.y)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < data.length; i++)
                                  FlSpot(i.toDouble(), data[i].valor),
                              ],
                              isCurved: true,
                              curveSmoothness: 0.25,
                              barWidth: 3,
                              color: cs.primary,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: cs.primary.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Resumen textual (derecha)
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cambio de patrimonio neto',
                              style: t.labelMedium?.copyWith(color: Colors.black54)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Fmt.monedaConSigno(cambioTotal),
                              style: t.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cambioColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Patrimonio actual',
                              style: t.labelMedium?.copyWith(color: Colors.black54)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(Fmt.moneda(actual),
                                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cambio por mes (más reciente primero)
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Cambio por mes',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (final d in data.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(Fmt.mesLargo(d.mes),
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      _CambioIndicador(cambio: d.cambio),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CambioIndicador extends StatelessWidget {
  const _CambioIndicador({required this.cambio});

  final double cambio;

  @override
  Widget build(BuildContext context) {
    final IconData icono;
    final Color color;
    if (cambio > 0) {
      icono = Icons.arrow_upward_rounded;
      color = AppTheme.positive;
    } else if (cambio < 0) {
      icono = Icons.arrow_downward_rounded;
      color = AppTheme.negative;
    } else {
      icono = Icons.remove_rounded;
      color = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          Fmt.monedaConSigno(cambio),
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
