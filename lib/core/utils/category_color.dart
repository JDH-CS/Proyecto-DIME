import 'package:flutter/painting.dart';

import '../../data/models/categoria.dart';
import '../accessibility/accessibility.dart';

/// Punto único para obtener el color de una categoría.
/// Respeta el modo de color para daltonismo (Configuración → Accesibilidad).
class CategoryColors {
  CategoryColors._();

  static Color of(Categoria c) => Accessibility.categoria(Color(c.color));
}
