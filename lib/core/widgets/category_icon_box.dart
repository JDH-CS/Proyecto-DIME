import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({super.key, required this.icono, this.size = 44});

  final String icono;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(AppIcons.of(icono), size: size * 0.5, color: cs.onSurface),
    );
  }
}
