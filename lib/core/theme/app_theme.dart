import 'package:flutter/material.dart';

/// Tema Material 3 en ESCALA DE GRISES.
/// Cuando elijan la paleta final, cambien solo los valores de este archivo:
///  - [seed] 
///  - [chartShades] para los colores de gráficas / categorías.
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
  
  // Fondo derivado de brand50 (más suave para no cansar la vista).
  // Podemos usar este o el color exacto de la paleta que es brand50.
  static const Color background = Color(0xFFFFF6F7);

  /// Colores semánticos (verde/rojo en el dashboard).
  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);

  /// Colores de categorías y gráficas: sólidos y sin relación con la marca.
  /// El orden alterna tonos para que las porciones vecinas del pastel contrasten.
  static const List<Color> chartShades = 
  [
    Color(0xFF1E6FD9), // azul
    Color(0xFFF28C28), // naranja
    Color(0xFF2E9E5B), // verde
    Color(0xFF7B3FBF), // morado
    Color(0xFFF9C80E), // amarillo
    Color(0xFF14B8A6), // turquesa
    Color(0xFF8D5524), // marrón
    Color(0xFF1F3A93), // azul marino
    Color(0xFF9ACD32), // lima
    Color(0xFF546E7A), // gris azulado
  ];

  static ThemeData get light 
  {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand700,
      onPrimary: Colors.white,
      primaryContainer: brand100,
      onPrimaryContainer: brand900,
      secondary: brand600,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: brand950,
      onSurfaceVariant: brand800,
      surfaceContainerHighest: brand50, // fondo de los íconos de categoría
      outline: brand200,                // puntos de arrastre
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
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
        errorBorder: border(negative),
        focusedErrorBorder: border(negative, 1.6),
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
        indicatorColor: brand100,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.black12, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
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
