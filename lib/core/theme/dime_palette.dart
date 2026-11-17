import 'package:flutter/material.dart';

import '../accessibility/accessibility.dart';

/// Extensión del tema que transporta el modo de color activo.
/// Al cambiar el modo, el tema cambia y todas las pantallas se redibujan.
class DimePalette extends ThemeExtension<DimePalette> {
  const DimePalette(this.mode);

  final ColorMode mode;

  @override
  DimePalette copyWith({ColorMode? mode}) => DimePalette(mode ?? this.mode);

  @override
  DimePalette lerp(ThemeExtension<DimePalette>? other, double t) =>
      other is DimePalette ? (t < 0.5 ? this : other) : this;

  @override
  bool operator ==(Object other) => other is DimePalette && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;
}
