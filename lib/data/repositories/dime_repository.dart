import '../../core/config/supabase_config.dart';
import '../models/categoria.dart';
import '../models/perfil.dart';
import '../models/presupuesto.dart';
import '../models/transaccion.dart';

class DatosUsuario {
  const DatosUsuario({
    required this.perfil,
    required this.categorias,
    required this.presupuesto,
    required this.asignaciones,
    required this.transacciones,
  });

  final Perfil perfil;
  final List<Categoria> categorias;
  final Presupuesto presupuesto;
  final List<AsignacionPresupuestaria> asignaciones;
  final List<Transaccion> transacciones;
}

/// Único punto de acceso a las tablas de Supabase.
/// (RLS garantiza que cada consulta solo devuelve filas del usuario logueado.)
class DimeRepository {
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ───────────── Lectura ─────────────
  Future<DatosUsuario> cargarTodo() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('No hay sesión activa');

    final perfilRow =
        await supabase.from('perfiles').select().eq('pid', user.id).maybeSingle();
    if (perfilRow == null) throw StateError('El usuario no tiene perfil en la base de datos');

    final catRows = await supabase
        .from('categorias')
        .select()
        .eq('ctipo_categoria', 'gasto')
        .order('corden', ascending: true);

    final presupuesto = await _presupuestoDelMes(user.id);

    final asigRows = await supabase
        .from('asignaciones_presupuestarias')
        .select()
        .eq('appresupuesto_id', presupuesto.id);

    final hoy = DateTime.now();
    final desde = DateTime(hoy.year, hoy.month - 11, 1);
    final txRows = await supabase
        .from('transacciones')
        .select()
        .gte('tfecha_transaccion', desde.toUtc().toIso8601String())
        .order('tfecha_transaccion', ascending: true);

    return DatosUsuario(
      perfil: Perfil.fromMap(perfilRow, correo: user.email ?? ''),
      categorias: [for (final r in catRows) Categoria.fromMap(r)],
      presupuesto: presupuesto,
      asignaciones: [for (final r in asigRows) AsignacionPresupuestaria.fromMap(r)],
      transacciones: [for (final r in txRows) Transaccion.fromMap(r)],
    );
  }

  /// Devuelve el presupuesto que cubre hoy. Si no existe (cambió el mes),
  /// crea uno nuevo y copia las asignaciones del presupuesto anterior.
  Future<Presupuesto> _presupuestoDelMes(String userId) async {
    final hoy = DateTime.now();
    final hoyStr = _fecha(hoy);

    final actual = await supabase
        .from('presupuestos')
        .select()
        .lte('prfecha_inicio', hoyStr)
        .gte('prfecha_fin', hoyStr)
        .order('prfecha_inicio', ascending: false)
        .limit(1);
    if (actual.isNotEmpty) return Presupuesto.fromMap(actual.first);

    final inicio = DateTime(hoy.year, hoy.month, 1);
    final fin = DateTime(hoy.year, hoy.month + 1, 0);

    final previo = await supabase
        .from('presupuestos')
        .select('prid')
        .lt('prfecha_inicio', _fecha(inicio))
        .order('prfecha_inicio', ascending: false)
        .limit(1);

    final nuevo = await supabase
        .from('presupuestos')
        .insert({
          'prusuario_id': userId,
          'prnombre': 'Presupuesto de ${_meses[hoy.month - 1]} ${hoy.year}',
          'prfecha_inicio': _fecha(inicio),
          'prfecha_fin': _fecha(fin),
          'prmoneda': 'USD',
        })
        .select()
        .single();

    if (previo.isNotEmpty) {
      final anteriores = await supabase
          .from('asignaciones_presupuestarias')
          .select('apcategoria_id, apmonto_asignado')
          .eq('appresupuesto_id', previo.first['prid']);
      if (anteriores.isNotEmpty) {
        await supabase.from('asignaciones_presupuestarias').insert([
          for (final a in anteriores)
            {
              'appresupuesto_id': nuevo['prid'],
              'apcategoria_id': a['apcategoria_id'],
              'apmonto_asignado': a['apmonto_asignado'],
            },
        ]);
      }
    }
    return Presupuesto.fromMap(nuevo);
  }

  // ───────────── Escritura ─────────────
  Future<void> insertarCategoria(Categoria c, int orden) async {
    await supabase.from('categorias').insert({
      'cid': c.id,
      'cusuario_id': c.usuarioId,
      'cnombre': c.nombre,
      'ctipo_categoria': 'gasto',
      'ccolor': Categoria.colorAHex(c.color),
      'cicono': c.icono,
      'ces_predeterminada': c.esPredeterminada,
      'corden': orden,
    });
  }

  Future<void> actualizarCategoria(String id, {required String nombre, required String icono}) async {
    await supabase.from('categorias').update({'cnombre': nombre, 'cicono': icono}).eq('cid', id);
  }

  Future<void> eliminarCategoria(String id) async {
    await supabase.from('categorias').delete().eq('cid', id);
  }

  Future<void> guardarOrden(List<Categoria> categorias) async {
    await Future.wait([
      for (var i = 0; i < categorias.length; i++)
        supabase.from('categorias').update({'corden': i + 1}).eq('cid', categorias[i].id),
    ]);
  }

  Future<void> guardarAsignacion(String presupuestoId, String categoriaId, double monto) async {
    await supabase.from('asignaciones_presupuestarias').upsert(
      {
        'appresupuesto_id': presupuestoId,
        'apcategoria_id': categoriaId,
        'apmonto_asignado': double.parse(monto.toStringAsFixed(2)),
      },
      onConflict: 'appresupuesto_id,apcategoria_id',
    );
  }
}
