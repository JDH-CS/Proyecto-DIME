import 'package:flutter/material.dart';

/// Asa de arrastre: cuadrícula de puntos de 2 columnas x 3 filas.
class DragGrip extends StatelessWidget {
  const DragGrip({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;

    Widget dot() => Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [dot(), const SizedBox(width: 4), dot()],
            ),
          ),
        ),
      ),
    );
  }
}
