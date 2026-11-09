import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Intervalo "bonito" para el eje Y (múltiplos de 100).
double niceInterval(double maxY) {
  final raw = maxY / 4;
  return math.max(100.0, (raw / 100).ceil() * 100.0);
}

/// Tope del eje Y alineado al intervalo.
double niceTop(double maxY, double interval) =>
    math.max(1, (maxY / interval).ceil()) * interval;

/// $850, $1.2k...
String abbrMoney(double v) =>
    v >= 1000 ? '\$${(v / 1000).toStringAsFixed(1)}k' : '\$${v.toInt()}';

const TextStyle axisStyle = TextStyle(fontSize: 10, color: Colors.black54);

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
