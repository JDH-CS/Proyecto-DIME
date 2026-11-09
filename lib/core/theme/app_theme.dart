import 'package:flutter/material.dart';

/// Tema Material 3 en ESCALA DE GRISES.
/// Cuando elijan la paleta final, cambien solo los valores de este archivo:
///  - [seed] y quiten `dynamicSchemeVariant` para que M3 genere la paleta completa.
///  - [chartShades] para los colores de gráficas / categorías.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF616161);
  static const Color background = Color(0xFFF4F4F4);

  /// Colores semánticos (pedidos explícitamente: verde/rojo en el dashboard).
  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);

  /// Tonos para categorías en gráficas (de oscuro a claro).
  static const List<Color> chartShades = [
    Color(0xFF1A1A1A),
    Color(0xFF3D3D3D),
    Color(0xFF5C5C5C),
    Color(0xFF7A7A7A),
    Color(0xFF959595),
    Color(0xFFAEAEAE),
    Color(0xFFC4C4C4),
    Color(0xFFD6D6D6),
    Color(0xFFE6E6E6),
  ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
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
        indicatorColor: Colors.black.withValues(alpha: 0.08),
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
