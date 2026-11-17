import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Modos de color del app. [estandar] = colores originales de DIME.
enum ColorMode {
  estandar('Estándar', 'Los colores originales de DIME.'),
  protanopia('Protanopía', 'Dificultad con el rojo (los rojos se ven oscuros y se confunden con el verde).'),
  deuteranopia('Deuteranopía', 'Dificultad con el verde (el verde y el rojo se confunden).'),
  tritanopia('Tritanopía', 'Dificultad con el azul y el amarillo (el azul se confunde con el verde).');

  const ColorMode(this.titulo, this.descripcion);
  final String titulo;
  final String descripcion;
}

/// Colores accesibles de la app. Se guardan en el dispositivo.
///
/// Las paletas de categorías se diseñaron y comprobaron simulando cada tipo de
/// daltonismo (modelo de Machado et al. 2009) para que los 10 colores sigan
/// siendo distinguibles entre sí. Los colores de ingresos/gastos usan azul y
/// naranja en protanopía y deuteranopía, donde el verde y el rojo se confunden.
class Accessibility {
  Accessibility._();

  static final ValueNotifier<ColorMode> modo = ValueNotifier(ColorMode.estandar);
  static const _key = 'dime_color_mode';

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_key);
    modo.value = ColorMode.values.firstWhere(
      (m) => m.name == guardado,
      orElse: () => ColorMode.estandar,
    );
  }

  static Future<void> establecer(ColorMode nuevo) async {
    modo.value = nuevo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, nuevo.name);
  }

  // ───────────── Ingresos / gastos ─────────────
  static Color positivoDe(ColorMode m) => switch (m) {
        ColorMode.protanopia || ColorMode.deuteranopia => const Color(0xFF1565C0), // azul
        _ => const Color(0xFF2E7D32), // verde
      };

  static Color negativoDe(ColorMode m) => switch (m) {
        ColorMode.protanopia || ColorMode.deuteranopia => const Color(0xFFEF6C00), // naranja
        _ => const Color(0xFFC62828), // rojo
      };

  static Color get positive => positivoDe(modo.value);
  static Color get negative => negativoDe(modo.value);

  // ───────────── Categorías y gráficas ─────────────
  static const List<Color> _protanopia = [
    Color(0xFFAA00FF), Color(0xFFF9C80E), Color(0xFFD62728), Color(0xFF7F8C8D),
    Color(0xFFC2185B), Color(0xFF2E9E5B), Color(0xFFE377C2), Color(0xFF827717),
    Color(0xFFFB9A99), Color(0xFFE83E8C),
  ];

  static const List<Color> _deuteranopia = [
    Color(0xFF7B3FBF), Color(0xFFF9C80E), Color(0xFFC2185B), Color(0xFFE377C2),
    Color(0xFF4DAF4A), Color(0xFFFB9A99), Color(0xFF546E7A), Color(0xFFE83E8C),
    Color(0xFF9467BD), Color(0xFFA65628),
  ];

  static const List<Color> _tritanopia = [
    Color(0xFFFF69B4), Color(0xFF00C853), Color(0xFF7B3FBF), Color(0xFF1F77B4),
    Color(0xFFBCBD22), Color(0xFFBF360C), Color(0xFF827717), Color(0xFFB2DF8A),
    Color(0xFFFDBF6F), Color(0xFF7F8C8D),
  ];

  /// Paleta de 10 colores del modo (la estándar es AppTheme.chartShades).
  static List<Color> paleta(ColorMode m) => switch (m) {
        ColorMode.protanopia => _protanopia,
        ColorMode.deuteranopia => _deuteranopia,
        ColorMode.tritanopia => _tritanopia,
        ColorMode.estandar => AppTheme.chartShades,
      };

  /// Convierte el color guardado de una categoría (de la paleta estándar) en el
  /// color equivalente del modo activo. Si no pertenece a la paleta, no cambia.
  static Color categoria(Color base) {
    final m = modo.value;
    if (m == ColorMode.estandar) return base;
    final i = AppTheme.chartShades.indexWhere((c) => c.toARGB32() == base.toARGB32());
    if (i == -1) return base;
    final p = paleta(m);
    return p[i % p.length];
  }
}
