/// Tabla reportes_soporte.
class ReporteSoporte {
  const ReporteSoporte({
    required this.id,
    required this.tipo,
    required this.asunto,
    required this.descripcion,
    required this.correoContacto,
    required this.estado,
    required this.fechaCreacion,
  });

  final String id;
  final String tipo; // error | consulta | sugerencia
  final String asunto;
  final String descripcion;
  final String correoContacto;
  final String estado; // recibido | en revision | resuelto
  final DateTime fechaCreacion;

  String get tipoLabel => switch (tipo) {
        'error' => 'Error',
        'sugerencia' => 'Sugerencia',
        _ => 'Consulta',
      };

  String get estadoLabel => switch (estado) {
        'en revision' => 'En revisión',
        'resuelto' => 'Resuelto',
        _ => 'Recibido',
      };

  factory ReporteSoporte.fromMap(Map<String, dynamic> m) => ReporteSoporte(
        id: m['rsid'] as String,
        tipo: m['rstipo_reporte'] as String,
        asunto: m['rsasunto'] as String,
        descripcion: m['rsdescripcion'] as String,
        correoContacto: m['rscorreo_contacto'] as String,
        estado: m['rsestado'] as String,
        fechaCreacion: DateTime.parse(m['rsfecha_creacion'] as String).toLocal(),
      );
}
