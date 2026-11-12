import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'bank_api.dart';

/// Guarda los tokens del banco en el almacén seguro del dispositivo
/// (la base de datos no tiene columnas para tokens, y no deben estar ahí).
class BankTokenStore {
  BankTokenStore._();

  static const _storage = FlutterSecureStorage();

  static String _key(String userId) => 'dime_bank_tokens_$userId';

  static Future<void> guardar(String userId, BankTokens t) => _storage.write(
        key: _key(userId),
        value: jsonEncode({'at': t.accessToken, 'rt': t.refreshToken}),
      );

  static Future<BankTokens?> leer(String userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return BankTokens(accessToken: m['at'] as String, refreshToken: m['rt'] as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> borrar(String userId) => _storage.delete(key: _key(userId));
}
