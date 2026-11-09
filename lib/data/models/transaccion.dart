/// Tabla Transacciones: Tid, Tusuario_id, Tcuenta_financiera_id, Tcategoria_id,
/// Tidentificador_externo, Tcodigo_comercio, Tdescripcion, Ttipo_transaccion,
/// Tmonto, Tfecha_transaccion, Torigen, Tfecha_registro, Tfecha_actualización.
class Transaccion {
  const Transaccion({
    required this.id,
    required this.usuarioId,
    required this.cuentaFinancieraId,
    required this.categoriaId,
    required this.identificadorExterno,
    required this.codigoComercio,
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
  final String cuentaFinancieraId;
  final String categoriaId;
  final String identificadorExterno;
  final String codigoComercio;
  final String descripcion;
  final String tipoTransaccion; // 'gasto' | 'ingreso'
  final double monto; // siempre positivo
  final DateTime fechaTransaccion;
  final String origen; // 'banco' | 'manual'
  final DateTime fechaRegistro;
  final DateTime fechaActualizacion;
}
