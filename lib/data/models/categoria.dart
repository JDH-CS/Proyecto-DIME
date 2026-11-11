/// Tabla categorias: cid, cusuario_id, cnombre, ctipo_categoria, ccolor,
/// cicono, ces_predeterminada, (corden), cfecha_creacion.
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

  final String id;
  final String usuarioId;
  final String nombre;
  final String tipoCategoria; // 'gasto' | 'ingreso'
  final int color; // ARGB
  final String icono; // clave de AppIcons
  final bool esPredeterminada;
  final DateTime fechaCreacion;

  factory Categoria.fromMap(Map<String, dynamic> m) => Categoria(
        id: m['cid'] as String,
        usuarioId: m['cusuario_id'] as String,
        nombre: m['cnombre'] as String,
        tipoCategoria: m['ctipo_categoria'] as String,
        color: colorDesdeHex(m['ccolor'] as String?),
        icono: (m['cicono'] as String?) ?? 'category',
        esPredeterminada: m['ces_predeterminada'] as bool,
        fechaCreacion: DateTime.parse(m['cfecha_creacion'] as String).toLocal(),
      );

  /// '#1E6FD9' -> 0xFF1E6FD9
  static int colorDesdeHex(String? hex) {
    if (hex == null || hex.length != 7) return 0xFF7A7A7A;
    return int.parse('FF${hex.substring(1)}', radix: 16);
  }

  /// 0xFF1E6FD9 -> '#1E6FD9'
  static String colorAHex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

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
