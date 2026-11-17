import 'package:flutter/material.dart';

import '../accessibility/accessibility.dart';

/// Tonos del tema de un modo de color (de más claro a más oscuro).
/// El modo Estándar usa la paleta de marca (basada en el logo); los modos de
/// daltonismo usan la misma escala de claridad con un tono que ese tipo de
/// visión distingue bien.
class DimeTonos {
  const DimeTonos({
    required this.t50,
    required this.t100,
    required this.t200,
    required this.t300,
    required this.t400,
    required this.t500,
    required this.t600,
    required this.t700,
    required this.t800,
    required this.t900,
    required this.t950,
    required this.fondo,
  });

  final Color t50, t100, t200, t300, t400, t500, t600, t700, t800, t900, t950;

  /// Fondo general de las pantallas (un tinte muy suave del tono).
  final Color fondo;
}

class AppTheme {
  AppTheme._();

  // ── Paleta de marca (basada en el logo) ──
  static const Color brand50 = Color(0xFFFEE7E9);
  static const Color brand100 = Color(0xFFFCBBC2);
  static const Color brand200 = Color(0xFFFA8F9B);
  static const Color brand300 = Color(0xFFF86374);
  static const Color brand400 = Color(0xFFF6374E);
  static const Color brand500 = Color(0xFFF40B27);
  static const Color brand600 = Color(0xFFC80920);
  static const Color brand700 = Color(0xFFA2081A); // color del logo
  static const Color brand800 = Color(0xFF700512);
  static const Color brand900 = Color(0xFF44030B);
  static const Color brand950 = Color(0xFF180104);

  static const Color seed = brand700;
  static const Color background = Color(0xFFFFF6F7);

  /// Colores semánticos del modo Estándar. En pantallas usa
  /// `Accessibility.positive` / `Accessibility.negative`, que respetan el modo.
  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);

  /// Colores de categorías y gráficas (modo Estándar).
  static const List<Color> chartShades = [
    Color(0xFFF9C80E), // amarillo
    Color(0xFFF28C28), // naranja
    Color(0xFF1E6FD9), // azul
    Color(0xFF2E9E5B), // verde
    Color(0xFF7B3FBF), // morado
    Color(0xFF14B8A6), // turquesa
    Color(0xFFE83E8C), // rosa
    Color(0xFF1F3A93), // azul marino
    Color(0xFF9ACD32), // lima
    Color(0xFF546E7A), // gris azulado
  ];

  // ───────────── Tonos por modo de color ─────────────

  /// Estándar: rojo de la marca.
  static const DimeTonos _estandar = DimeTonos(
    t50: brand50, t100: brand100, t200: brand200, t300: brand300,
    t400: brand400, t500: brand500, t600: brand600, t700: brand700,
    t800: brand800, t900: brand900, t950: brand950,
    fondo: background,
  );

  /// Protanopía: azul. (El rojo de la marca se ve como un verde oliva oscuro.)
  static const DimeTonos _protanopia = DimeTonos(
    t50: Color(0xFFE5EEFE), t100: Color(0xFFB6D0FF), t200: Color(0xFF8AB3FE),
    t300: Color(0xFF6399FF), t400: Color(0xFF4785FE), t500: Color(0xFF377AFE),
    t600: Color(0xFF1C5EE1), t700: Color(0xFF154CB7), t800: Color(0xFF0C337F),
    t900: Color(0xFF051D4D), t950: Color(0xFF01071C),
    fondo: Color(0xFFF6F9FE),
  );

  /// Deuteranopía: azul petróleo. (El rojo de la marca se ve como café oliva.)
  static const DimeTonos _deuteranopia = DimeTonos(
    t50: Color(0xFFDEF1FC), t100: Color(0xFF9CD8F8), t200: Color(0xFF4BC1F7),
    t300: Color(0xFF07AAE4), t400: Color(0xFF0398CD), t500: Color(0xFF088FC0),
    t600: Color(0xFF04759D), t700: Color(0xFF035E7F), t800: Color(0xFF013F58),
    t900: Color(0xFF002535), t950: Color(0xFF000A12),
    fondo: Color(0xFFF2FAFE),
  );

  /// Tritanopía: verde azulado (los tonos que mejor distingue, junto al rojo).
  static const DimeTonos _tritanopia = DimeTonos(
    t50: Color(0xFFDBF3F2), t100: Color(0xFF93DFDB), t200: Color(0xFF13CDC8),
    t300: Color(0xFF06B3AF), t400: Color(0xFF0DA09D), t500: Color(0xFF0C9793),
    t600: Color(0xFF007B78), t700: Color(0xFF026361), t800: Color(0xFF044341),
    t900: Color(0xFF002726), t950: Color(0xFF000B0B),
    fondo: Color(0xFFF2FBFA),
  );

  static DimeTonos tonos(ColorMode m) => switch (m) {
        ColorMode.estandar => _estandar,
        ColorMode.protanopia => _protanopia,
        ColorMode.deuteranopia => _deuteranopia,
        ColorMode.tritanopia => _tritanopia,
      };

  /// Tema del modo Estándar.
  static ThemeData get light => tema(ColorMode.estandar);

  /// Tema completo del modo de color: botones, tarjetas de color (como
  /// "Dinero para asignar"), fondo, textos, barra de navegación, etc.
  static ThemeData tema(ColorMode modo) {
    final c = tonos(modo);
    final negativo = Accessibility.negativoDe(modo);

    final scheme = ColorScheme.fromSeed(
      seedColor: c.t700,
      brightness: Brightness.light,
    ).copyWith(
      primary: c.t700,
      onPrimary: Colors.white,
      primaryContainer: c.t100,
      onPrimaryContainer: c.t900,
      secondary: c.t600,
      onSecondary: Colors.white,
      secondaryContainer: c.t100,
      onSecondaryContainer: c.t900,
      surface: Colors.white,
      onSurface: c.t950,
      onSurfaceVariant: c.t800,
      surfaceContainerHighest: c.t50, // fondo de los íconos de categoría
      outline: c.t200, // puntos de arrastre
      error: negativo,
    );

    OutlineInputBorder border(Color col, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: col, width: w),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: c.fondo,
      // Textos principales con el tono más oscuro del modo.
      textTheme: base.textTheme.apply(bodyColor: c.t950, displayColor: c.t950),
      appBarTheme: AppBarTheme(
        backgroundColor: c.fondo,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.black12),
        enabledBorder: border(Colors.black12),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(negativo),
        focusedErrorBorder: border(negativo, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          side: const BorderSide(color: Colors.black26),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
        height: 68,
        indicatorColor: c.t100,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: c.t950,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.black12, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.t900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
