import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Permite mostrar SnackBars desde fuera de los widgets (p. ej. desde AppState).
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void showSoon(BuildContext context, [String msg = 'Disponible próximamente']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Cierra el teclado y espera a que termine su animación.
///
/// Se llama antes de cambiar a otra pantalla desde un formulario: si el teclado
/// sigue abierto al reemplazar la ruta, Android puede dejar reservado su espacio
/// (viewInsets) y la pantalla siguiente se dibuja recortada en la mitad superior.
Future<void> cerrarTeclado() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await Future<void>.delayed(const Duration(milliseconds: 300));
}
