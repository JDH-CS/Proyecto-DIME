/// Tabla conexiones_bancarias (máximo una por usuario).
class ConexionBancaria {
  const ConexionBancaria({
    required this.id,
    required this.usuarioId,
    required this.codigoInstitucion,
    required this.nombreInstitucion,
    required this.estado,
    required this.fechaAutorizacion,
    required this.ultimaSincronizacion,
    required this.fechaCreacion,
  });

  final String id;
  final String usuarioId;
  final String codigoInstitucion; // BGEN, BAC, ...
  final String nombreInstitucion;
  final String estado; // 'pendiente' | 'conectada' | 'revocada'
  final DateTime? fechaAutorizacion;
  final DateTime? ultimaSincronizacion;
  final DateTime fechaCreacion;

  bool get conectada => estado == 'conectada';

  /// La clave del logo coincide con el código en minúsculas (assets/banks/bgen.png).
  String get logoKey => codigoInstitucion.toLowerCase();

  static DateTime? _fecha(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

  factory ConexionBancaria.fromMap(Map<String, dynamic> m) => ConexionBancaria(
        id: m['cbid'] as String,
        usuarioId: m['cbusuario_id'] as String,
        codigoInstitucion: m['cbcodigo_institucion'] as String,
        nombreInstitucion: m['cbnombre_institucion'] as String,
        estado: m['cbestado'] as String,
        fechaAutorizacion: _fecha(m['cbfecha_autorizacion']),
        ultimaSincronizacion: _fecha(m['cbultima_sincronizacion']),
        fechaCreacion: DateTime.parse(m['cbfecha_creacion'] as String).toLocal(),
      );

  ConexionBancaria copyWith({String? estado, DateTime? ultimaSincronizacion}) => ConexionBancaria(
        id: id,
        usuarioId: usuarioId,
        codigoInstitucion: codigoInstitucion,
        nombreInstitucion: nombreInstitucion,
        estado: estado ?? this.estado,
        fechaAutorizacion: fechaAutorizacion,
        ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
        fechaCreacion: fechaCreacion,
      );
}
