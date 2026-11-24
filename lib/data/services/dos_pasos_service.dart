import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';

/// Verificación en dos pasos (2FA) por correo electrónico.
///
/// Paso 1: correo + contraseña (signInWithPassword).
/// Paso 2: un código de un solo uso enviado al correo (signInWithOtp + verifyOTP).
/// La preferencia se guarda en perfiles.p2fa_email, así aplica en cualquier dispositivo.
class DosPasosService {
  DosPasosService._();

  /// ¿El usuario de la sesión actual tiene la verificación en dos pasos activa?
  static Future<bool> activo(String userId) async {
    try {
      final row = await supabase
          .from('perfiles')
          .select('p2fa_email')
          .eq('pid', userId)
          .maybeSingle();
      return (row?['p2fa_email'] as bool?) ?? false;
    } catch (e) {
      // Si la columna aún no existe (no se ejecutó el SQL 08), no bloquea el acceso.
      debugPrint('No se pudo leer p2fa_email: $e');
      return false;
    }
  }

  /// Envía un código de 6 dígitos al correo (plantilla "Magic Link" de Supabase).
  static Future<void> enviarCodigo(String email) =>
      supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);

  /// Verifica el código. Si es correcto, Supabase abre la sesión.
  static Future<void> verificarCodigo(String email, String codigo) => supabase.auth.verifyOTP(
        email: email,
        token: codigo.trim(),
        type: OtpType.email,
      );

  static Future<void> guardar(String userId, bool activo) =>
      supabase.from('perfiles').update({'p2fa_email': activo}).eq('pid', userId);
}
