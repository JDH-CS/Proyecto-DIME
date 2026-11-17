import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda las credenciales en el almacén seguro del dispositivo (Android Keystore)
/// para poder iniciar sesión con huella. Solo se usa tras una autenticación biométrica.
class BiometricVault {
  BiometricVault._();

  static const _storage = FlutterSecureStorage();
  static const _kEmail = 'dime_bio_email';
  static const _kPass = 'dime_bio_pass';

  static Future<void> guardar(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPass, value: password);
  }

  static Future<({String email, String password})?> leer() async {
    final email = await _storage.read(key: _kEmail);
    final pass = await _storage.read(key: _kPass);
    if (email == null || pass == null) return null;
    return (email: email, password: pass);
  }

  /// Desactiva el inicio con huella en este dispositivo.
  static Future<void> borrar() async {
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPass);
  }
}
