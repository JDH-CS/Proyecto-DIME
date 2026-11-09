/// Tabla Categorias: Cid, Cusuario_id, Cnombre, Ctipo_categoria, Ccolor,
/// Cicono, Ces_predeterminada, Cfecha_creacion.
class Categoria {
  const Categoria({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.tipoCategoria,
    required this.color,
    required this.icono,
    required this.esPredeterminada,
    required this.fechaCreacion,
  });

  final String id; // Cid
  final String usuarioId; // Cusuario_id
  final String nombre; // Cnombre
  final String tipoCategoria; // Ctipo_categoria: 'gasto' | 'ingreso'
  final int color; // Ccolor (ARGB)
  final String icono; // Cicono (clave de AppIcons)
  final bool esPredeterminada; // Ces_predeterminada
  final DateTime fechaCreacion; // Cfecha_creacion

  Categoria copyWith({String? nombre, String? icono}) => Categoria(
        id: id,
        usuarioId: usuarioId,
        nombre: nombre ?? this.nombre,
        tipoCategoria: tipoCategoria,
        color: color,
        icono: icono ?? this.icono,
        esPredeterminada: esPredeterminada,
        fechaCreacion: fechaCreacion,
      );
}
