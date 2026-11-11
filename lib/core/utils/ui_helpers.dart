import 'package:flutter/material.dart';

/// Permite mostrar SnackBars desde fuera de los widgets (p. ej. desde AppState).
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void showSoon(BuildContext context, [String msg = 'Disponible próximamente']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
