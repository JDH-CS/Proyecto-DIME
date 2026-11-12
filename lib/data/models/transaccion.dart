/// Tabla transacciones. Los campos opcionales coinciden con los NULL de la BD.
class Transaccion {
  const Transaccion({
    required this.id,
    required this.usuarioId,
    required this.cuentaFinancieraId,
    required this.categoriaId,
    required this.identificadorExterno,
    required this.codigoComercio,
    required this.nombreComercio,
    required this.descripcion,
    required this.tipoTransaccion,
    required this.monto,
    required this.fechaTransaccion,
    required this.origen,
    required this.fechaRegistro,
    required this.fechaActualizacion,
  });

  final String id;
  final String usuarioId;
  final String? cuentaFinancieraId;
  final String? categoriaId; // null = sin clasificar
  final String? identificadorExterno;
  final String? codigoComercio;
  final String? nombreComercio;
  final String descripcion;
  final String tipoTransaccion; // 'ingreso' | 'gasto' | 'transferencia' | 'otro'
  final double monto; // siempre positivo
  final DateTime fechaTransaccion;
  final String origen; // 'bancario' | 'manual'
  final DateTime fechaRegistro;
  final DateTime fechaActualizacion;

  factory Transaccion.fromMap(Map<String, dynamic> m) => Transaccion(
        id: m['tid'] as String,
        usuarioId: m['tusuario_id'] as String,
        cuentaFinancieraId: m['tcuenta_financiera_id'] as String?,
        categoriaId: m['tcategoria_id'] as String?,
        identificadorExterno: m['tidentificador_externo'] as String?,
        codigoComercio: m['tcodigo_comercio'] as String?,
        nombreComercio: m['tnombre_comercio'] as String?,
        descripcion: m['tdescripcion'] as String,
        tipoTransaccion: m['ttipo_transaccion'] as String,
        monto: (m['tmonto'] as num).toDouble(),
        fechaTransaccion: DateTime.parse(m['tfecha_transaccion'] as String).toLocal(),
        origen: m['torigen'] as String,
        fechaRegistro: DateTime.parse(m['tfecha_registro'] as String).toLocal(),
        fechaActualizacion: DateTime.parse(m['tfecha_actualizacion'] as String).toLocal(),
      );

  /// Copia con otra categoría (null = sin clasificar).
  Transaccion conCategoria(String? nuevaCategoriaId) => Transaccion(
        id: id,
        usuarioId: usuarioId,
        cuentaFinancieraId: cuentaFinancieraId,
        categoriaId: nuevaCategoriaId,
        identificadorExterno: identificadorExterno,
        codigoComercio: codigoComercio,
        nombreComercio: nombreComercio,
        descripcion: descripcion,
        tipoTransaccion: tipoTransaccion,
        monto: monto,
        fechaTransaccion: fechaTransaccion,
        origen: origen,
        fechaRegistro: fechaRegistro,
        fechaActualizacion: DateTime.now(),
      );

  /// Copia sin categoría (cuando se elimina su categoría).
  Transaccion sinCategoria() => conCategoria(null);
}
