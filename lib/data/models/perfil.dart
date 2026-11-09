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

/// Tabla Perfiles: Pid (= auth.users.id), Pnombre, Papellido, Pfecha_nacimiento,
/// Pdocumento_identidad, Pestado, Pfecha_creacion, Pfecha_actualizacion.
///
/// Campos extra SOLO para la UI (correo/celular vienen de auth.users;
/// fotoUrl vendrá de Supabase Storage más adelante).
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
    this.fotoUrl,
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
  final String? fotoUrl;

  String get nombreCompleto => '$nombre $apellido';
}
