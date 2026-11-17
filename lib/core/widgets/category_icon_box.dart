import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

/// Cuadro con el ícono de una categoría.
/// Si se pasa [color], el fondo usa ese color (el de la categoría) y el ícono
/// toma blanco o negro según cuál contraste mejor.
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({super.key, required this.icono, this.size = 44, this.color});

  final String icono;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fondo = color ?? cs.surfaceContainerHighest;
    final frente = color == null
        ? cs.onSurface
        : (color!.computeLuminance() > 0.3 ? Colors.black87 : Colors.white);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(AppIcons.of(icono), size: size * 0.5, color: frente),
    );
  }
}
