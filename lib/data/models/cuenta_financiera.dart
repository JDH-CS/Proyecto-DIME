/// Tabla cuentas_financieras.
class CuentaFinanciera {
  const CuentaFinanciera({
    required this.id,
    required this.conexionId,
    required this.identificadorExterno,
    required this.nombre,
    required this.tipo,
    required this.moneda,
    required this.saldoActual,
    required this.montoDisponible,
    required this.limiteCredito,
    required this.ultimaActualizacion,
  });

  final String id;
  final String conexionId;
  final String identificadorExterno; // account_id del banco
  final String nombre;
  final String tipo; // 'corriente' | 'ahorro' | 'tarjeta_credito'
  final String moneda;
  final double saldoActual;
  final double? montoDisponible;
  final double? limiteCredito;
  final DateTime? ultimaActualizacion;

  bool get esTarjeta => tipo == 'tarjeta_credito';

  String get tipoLabel => switch (tipo) {
        'ahorro' => 'Cuenta de ahorros',
        'tarjeta_credito' => 'Tarjeta de crédito',
        _ => 'Cuenta corriente',
      };

  factory CuentaFinanciera.fromMap(Map<String, dynamic> m) => CuentaFinanciera(
        id: m['cfid'] as String,
        conexionId: m['cfconexion_bancaria_id'] as String,
        identificadorExterno: m['cfidentificador_externo'] as String,
        nombre: m['cfnombre_cuenta'] as String,
        tipo: m['cftipo_cuenta'] as String,
        moneda: (m['cfmoneda'] as String).trim(),
        saldoActual: (m['cfsaldo_actual'] as num).toDouble(),
        montoDisponible: (m['cfmonto_disponible'] as num?)?.toDouble(),
        limiteCredito: (m['cflimite_credito'] as num?)?.toDouble(),
        ultimaActualizacion: m['cfultima_actualizacion'] == null
            ? null
            : DateTime.parse(m['cfultima_actualizacion'] as String).toLocal(),
      );
}
