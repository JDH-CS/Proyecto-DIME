import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Marca que hay una recuperación de contraseña a medias.
/// Si la app se cierra después de verificar el código pero antes de crear la
/// nueva contraseña, al volver a abrirla se cierra esa sesión temporal.
class RecoveryGuard {
  RecoveryGuard._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'dime_recovery_pending';

  static Future<void> marcar() => _storage.write(key: _key, value: '1');
  static Future<void> limpiar() => _storage.delete(key: _key);
  static Future<bool> pendiente() async => (await _storage.read(key: _key)) == '1';
}
