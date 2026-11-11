class Presupuesto {
  const Presupuesto({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.moneda,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  final String id;
  final String usuarioId;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String moneda;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  factory Presupuesto.fromMap(Map<String, dynamic> m) => Presupuesto(
        id: m['prid'] as String,
        usuarioId: m['prusuario_id'] as String,
        nombre: m['prnombre'] as String,
        fechaInicio: DateTime.parse(m['prfecha_inicio'] as String),
        fechaFin: DateTime.parse(m['prfecha_fin'] as String),
        moneda: (m['prmoneda'] as String).trim(),
        fechaCreacion: DateTime.parse(m['prfecha_creacion'] as String).toLocal(),
        fechaActualizacion: DateTime.parse(m['prfecha_actualizacion'] as String).toLocal(),
      );
}

class AsignacionPresupuestaria {
  const AsignacionPresupuestaria({
    required this.id,
    required this.presupuestoId,
    required this.categoriaId,
    required this.montoAsignado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  final String id;
  final String presupuestoId;
  final String categoriaId;
  final double montoAsignado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  factory AsignacionPresupuestaria.fromMap(Map<String, dynamic> m) => AsignacionPresupuestaria(
        id: m['apid'] as String,
        presupuestoId: m['appresupuesto_id'] as String,
        categoriaId: m['apcategoria_id'] as String,
        montoAsignado: (m['apmonto_asignado'] as num).toDouble(),
        fechaCreacion: DateTime.parse(m['apfecha_creacion'] as String).toLocal(),
        fechaActualizacion: DateTime.parse(m['apfecha_actualizacion'] as String).toLocal(),
      );

  AsignacionPresupuestaria copyWith({double? montoAsignado}) => AsignacionPresupuestaria(
        id: id,
        presupuestoId: presupuestoId,
        categoriaId: categoriaId,
        montoAsignado: montoAsignado ?? this.montoAsignado,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
}
