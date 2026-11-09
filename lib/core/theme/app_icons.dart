import 'package:flutter/material.dart';

/// Íconos genéricos disponibles para categorías.
/// En la BD (Categorias.Cicono) se guarda solo la clave (String).
class AppIcons {
  AppIcons._();

  static const Map<String, IconData> all = {
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'car': Icons.directions_car_rounded,
    'bolt': Icons.bolt_rounded,
    'movie': Icons.movie_rounded,
    'health': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'pets': Icons.pets_rounded,
    'flight': Icons.flight_rounded,
    'fitness': Icons.fitness_center_rounded,
    'phone': Icons.phone_android_rounded,
    'gift': Icons.card_giftcard_rounded,
    'coffee': Icons.local_cafe_rounded,
    'child': Icons.child_care_rounded,
    'work': Icons.work_rounded,
    'savings': Icons.savings_rounded,
  };

  static IconData of(String key) => all[key] ?? Icons.category_rounded;
}
