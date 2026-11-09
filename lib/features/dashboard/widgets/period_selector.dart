import 'package:flutter/material.dart';

/// Botón segmentado para cambiar el periodo en vista (3, 6 o 12 meses).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.meses, required this.onChanged});

  final int meses;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Periodo',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54)),
        const Spacer(),
        SegmentedButton<int>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: 3, label: Text('3M')),
            ButtonSegment(value: 6, label: Text('6M')),
            ButtonSegment(value: 12, label: Text('12M')),
          ],
          selected: {meses},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}
