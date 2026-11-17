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
  if (msg.contains('only request this after') || msg.contains('security purposes')) {
    return 'Espera un minuto antes de pedir otro código.';
  }
  if (msg.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos.';
  if (msg.contains('token has expired') || msg.contains('otp_expired') || msg.contains('invalid')) {
    if (msg.contains('otp') || msg.contains('token')) {
      return 'El código es incorrecto o ya expiró.';
    }
  }
  if (msg.contains('different from the old password') || msg.contains('same_password')) {
    return 'La nueva contraseña debe ser distinta a la actual.';
  }
  if (msg.contains('password should be at least') || msg.contains('weak_password')) {
    return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
  }
  if (msg.contains('socket') || msg.contains('host lookup') || msg.contains('network')) {
    return 'Sin conexión a internet.';
  }
  if (msg.contains('perfil')) return 'Tu usuario no tiene perfil en DIME.';
  return 'Ocurrió un error. Intenta de nuevo.';
}
