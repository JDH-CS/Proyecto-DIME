import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce errores de Supabase / red a mensajes para el usuario.
String mensajeAuth(Object e) {
  final msg = (e is AuthException ? e.message : e.toString()).toLowerCase();
  if (msg.contains('invalid login credentials')) return 'Correo o contraseña incorrectos.';
  if (msg.contains('already registered') || msg.contains('already been registered')) {
    return 'Ya existe una cuenta con ese correo.';
  }
  if (msg.contains('database error saving new user')) {
    return 'No se pudo crear la cuenta. Revisa que la cédula o pasaporte no esté ya registrado.';
  }
  if (msg.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos.';
  if (msg.contains('socket') || msg.contains('host lookup') || msg.contains('network')) {
    return 'Sin conexión a internet.';
  }
  if (msg.contains('perfil')) return 'Tu usuario no tiene perfil en DIME.';
  return 'Ocurrió un error. Intenta de nuevo.';
}
