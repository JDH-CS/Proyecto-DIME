import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/bank_api_config.dart';
import '../../core/utils/ids.dart';

class BankApiException implements Exception {
  const BankApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Mensaje apto para el usuario a partir de cualquier error.
String mensajeBanco(Object e) =>
    e is BankApiException ? e.message : 'Ocurrió un error inesperado. Intenta de nuevo.';

class BankInstitution {
  const BankInstitution({required this.code, required this.name, required this.logoKey});

  final String code;
  final String name;
  final String logoKey;

  factory BankInstitution.fromJson(Map<String, dynamic> j) => BankInstitution(
        code: j['code'] as String,
        name: j['name'] as String,
        logoKey: (j['logo_key'] as String?) ?? (j['code'] as String).toLowerCase(),
      );
}

class BankTokens {
  const BankTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class BankAccountDto {
  const BankAccountDto({
    required this.accountId,
    required this.name,
    required this.type,
    required this.currency,
    required this.currentBalance,
    required this.availableBalance,
    required this.creditLimit,
  });

  final String accountId;
  final String name;
  final String type; // checking | savings | credit_card
  final String currency;
  final double currentBalance;
  final double? availableBalance;
  final double? creditLimit;

  /// Valor para cuentas_financieras.cftipo_cuenta
  String get tipoDb => switch (type) {
        'savings' => 'ahorro',
        'credit_card' => 'tarjeta_credito',
        _ => 'corriente',
      };

  factory BankAccountDto.fromJson(Map<String, dynamic> j) => BankAccountDto(
        accountId: j['account_id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        currency: (j['currency'] as String?) ?? 'USD',
        currentBalance: (j['current_balance'] as num).toDouble(),
        availableBalance: (j['available_balance'] as num?)?.toDouble(),
        creditLimit: (j['credit_limit'] as num?)?.toDouble(),
      );
}

class BankTransactionDto {
  const BankTransactionDto({
    required this.transactionId,
    required this.accountId,
    required this.merchantCode,
    required this.merchantName,
    required this.description,
    required this.type,
    required this.amount,
    required this.bookedAt,
  });

  final String transactionId;
  final String accountId;
  final String? merchantCode;
  final String? merchantName;
  final String description;
  final String type; // debit | credit
  final double amount;
  final DateTime bookedAt;

  /// Valor para transacciones.ttipo_transaccion
  String get tipoDb => type == 'credit' ? 'ingreso' : 'gasto';

  factory BankTransactionDto.fromJson(Map<String, dynamic> j) => BankTransactionDto(
        transactionId: j['transaction_id'] as String,
        accountId: j['account_id'] as String,
        merchantCode: j['merchant_code'] as String?,
        merchantName: j['merchant_name'] as String?,
        description: (j['description'] as String?) ?? (j['merchant_name'] as String?) ?? 'Movimiento',
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        bookedAt: DateTime.tryParse((j['booked_at'] as String?) ?? '') ?? DateTime.now(),
      );
}

class SyncResult {
  const SyncResult({required this.added, required this.nextCursor});

  final List<BankTransactionDto> added;
  final String? nextCursor;
}

/// Cliente HTTP del banco simulado (Mockoon).
class BankApi {
  BankApi({String? baseUrl, http.Client? client})
      : _base = (baseUrl ?? BankApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);
  static const clientId = 'dime-app';
  static const redirectUri = 'dime://oauth/callback';
  static const scope = 'accounts transactions';

  final String _base;
  final http.Client _client;

  // ───────────── Llamadas ─────────────
  Future<List<BankInstitution>> institutions() async {
    final data = await _send('GET', 'institutions') as Map<String, dynamic>;
    return [
      for (final j in data['institutions'] as List) BankInstitution.fromJson(j as Map<String, dynamic>),
    ];
  }

  /// OAuth paso 1: el usuario aprobó el acceso en la "página del banco".
  Future<String> authorize(String institutionCode) async {
    final state = nuevoUuid();
    final data = await _send('POST', 'oauth/authorize', body: {
      'institution_code': institutionCode,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
      'scope': scope,
    }) as Map<String, dynamic>;

    final devuelto = data['state'];
    if (devuelto is String && devuelto.isNotEmpty && devuelto != state) {
      throw const BankApiException('La respuesta del banco no coincide con la solicitud.');
    }
    return data['code'] as String;
  }

  /// OAuth paso 2: cambia el code por tokens.
  Future<BankTokens> exchangeCode(String code) async {
    final data = await _send('POST', 'oauth/token', body: {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'redirect_uri': redirectUri,
    }) as Map<String, dynamic>;
    return _tokens(data);
  }

  Future<BankTokens> refresh(String refreshToken) async {
    final data = await _send('POST', 'oauth/token', body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
    }) as Map<String, dynamic>;
    return _tokens(data);
  }

  Future<List<BankAccountDto>> accounts(String accessToken) async {
    final data = await _send('GET', 'accounts', token: accessToken) as Map<String, dynamic>;
    return [
      for (final j in data['accounts'] as List) BankAccountDto.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<SyncResult> sync(String accessToken, {String? cursor}) async {
    final data = await _send(
      'GET',
      'transactions/sync',
      token: accessToken,
      query: {if (cursor != null) 'cursor': cursor},
    ) as Map<String, dynamic>;
    return SyncResult(
      added: [
        for (final j in data['added'] as List) BankTransactionDto.fromJson(j as Map<String, dynamic>),
      ],
      nextCursor: data['next_cursor'] as String?,
    );
  }

  Future<void> revoke(String accessToken) async {
    await _send('POST', 'oauth/revoke', body: {'token': accessToken});
  }

  // ───────────── Interno ─────────────
  BankTokens _tokens(Map<String, dynamic> d) => BankTokens(
        accessToken: d['access_token'] as String,
        refreshToken: d['refresh_token'] as String,
      );

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_base/v1/$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    const sinConexion = BankApiException(
      'No se pudo conectar con el banco simulado. Verifica que Mockoon esté corriendo y que la dirección sea correcta.',
    );

    try {
      final res = method == 'GET'
          ? await _client.get(uri, headers: headers).timeout(_timeout)
          : await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? <String, dynamic>{}))
              .timeout(_timeout);

      dynamic data;
      if (res.body.isNotEmpty) data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      throw BankApiException(_mensajeDeError(data), res.statusCode);
    } on TimeoutException {
      throw const BankApiException('El banco simulado no respondió a tiempo.');
    } on SocketException {
      throw sinConexion;
    } on http.ClientException {
      throw sinConexion;
    } on FormatException {
      throw const BankApiException('Respuesta inesperada del banco simulado.');
    }
  }

  String _mensajeDeError(dynamic data) {
    if (data is Map) {
      if (data['error'] == 'invalid_grant') {
        return 'La conexión con el banco expiró. Vincula tu banco de nuevo.';
      }
      final d = data['error_description'] ?? data['error'];
      if (d != null) return d.toString();
    }
    return 'El banco simulado respondió con un error.';
  }
}
