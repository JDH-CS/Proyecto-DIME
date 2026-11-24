enum EstadoPerfil {
  activo,
  inactivo,
  suspendido;

  String get label => switch (this) {
        EstadoPerfil.activo => 'Activo',
        EstadoPerfil.inactivo => 'Inactivo',
        EstadoPerfil.suspendido => 'Suspendido',
      };
}

/// Tabla perfiles. El correo viene de auth.users (se pasa aparte).
/// [fotoRuta] es la ruta del archivo en Storage (pfoto_ruta);
/// [fotoUrl] es la URL firmada temporal para mostrarla.
class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.documentoIdentidad,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.correo,
    required this.celular,
    this.fotoRuta,
    this.fotoUrl,
    this.dosPasos = false,
  });

  final String id;
  final String nombre;
  final String apellido;
  final DateTime fechaNacimiento;
  final String documentoIdentidad;
  final EstadoPerfil estado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  final String correo;
  final String celular;
  final String? fotoRuta;
  final String? fotoUrl;

  /// Verificación en dos pasos por correo (columna p2fa_email).
  final bool dosPasos;

  String get nombreCompleto => '$nombre $apellido';

  factory Perfil.fromMap(Map<String, dynamic> m, {required String correo, String? fotoUrl}) => Perfil(
        id: m['pid'] as String,
        nombre: m['pnombre'] as String,
        apellido: m['papellido'] as String,
        fechaNacimiento: DateTime.parse(m['pfecha_nacimiento'] as String),
        documentoIdentidad: m['pdocumento_identidad'] as String,
        estado: EstadoPerfil.values.firstWhere(
          (e) => e.label == m['pestado'],
          orElse: () => EstadoPerfil.activo,
        ),
        fechaCreacion: DateTime.parse(m['pfecha_creacion'] as String).toLocal(),
        fechaActualizacion: DateTime.parse(m['pfecha_actualizacion'] as String).toLocal(),
        correo: correo,
        celular: (m['ptelefono'] as String?) ?? '—',
        fotoRuta: m['pfoto_ruta'] as String?,
        fotoUrl: fotoUrl,
        dosPasos: (m['p2fa_email'] as bool?) ?? false,
      );

  Perfil copyWith({
    String? nombre,
    String? apellido,
    DateTime? fechaNacimiento,
    String? celular,
    String? fotoRuta,
    String? fotoUrl,
    bool quitarFoto = false,
    bool? dosPasos,
  }) =>
      Perfil(
        id: id,
        nombre: nombre ?? this.nombre,
        apellido: apellido ?? this.apellido,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
        documentoIdentidad: documentoIdentidad,
        estado: estado,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: DateTime.now(),
        correo: correo,
        celular: celular ?? this.celular,
        fotoRuta: quitarFoto ? null : (fotoRuta ?? this.fotoRuta),
        fotoUrl: quitarFoto ? null : (fotoUrl ?? this.fotoUrl),
        dosPasos: dosPasos ?? this.dosPasos,
      );
}
