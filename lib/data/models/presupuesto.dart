/// Tabla Presupuestos: PRid, PRusuario_id, PRnombre, PRfecha_inicio,
/// PRfecha_fin, PRmoneda, PRfecha_creacion, PRfecha_actualizacion.
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
}

/// Tabla Asignaciones Presupuestarias: APid, APpresupuesto_id, APcategoria_id,
/// APmonto_asignado, APfecha_creacion, APfecha_actualizacion.
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

  AsignacionPresupuestaria copyWith({double? montoAsignado}) => AsignacionPresupuestaria(
        id: id,
        presupuestoId: presupuestoId,
        categoriaId: categoriaId,
        montoAsignado: montoAsignado ?? this.montoAsignado,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: DateTime.now(),
      );
}
