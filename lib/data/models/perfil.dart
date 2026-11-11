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

/// Tabla perfiles. El correo viene de auth.users (se pasa aparte);
/// fotoUrl se conectará a Supabase Storage más adelante.
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

  factory Perfil.fromMap(Map<String, dynamic> m, {required String correo}) => Perfil(
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
      );
}
