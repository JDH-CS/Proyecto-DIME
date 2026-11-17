import '../../core/config/supabase_config.dart';
import '../models/categoria.dart';
import '../models/conexion_bancaria.dart';
import '../models/cuenta_financiera.dart';
import '../models/perfil.dart';
import '../models/presupuesto.dart';
import '../models/transaccion.dart';
import '../services/bank_api.dart';

class DatosUsuario {
  const DatosUsuario({
    required this.perfil,
    required this.categorias,
    required this.categoriasIngreso,
    required this.presupuesto,
    required this.asignaciones,
    required this.transacciones,
    required this.conexion,
    required this.cuentas,
    required this.reglas,
  });

  final Perfil perfil;
  final List<Categoria> categorias; // de gasto
  final List<Categoria> categoriasIngreso;
  final Presupuesto presupuesto;
  final List<AsignacionPresupuestaria> asignaciones;
  final List<Transaccion> transacciones;
  final ConexionBancaria? conexion;
  final List<CuentaFinanciera> cuentas;
  final Map<String, String> reglas; // código de comercio -> categoriaId
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

  static String _ahoraUtc() => DateTime.now().toUtc().toIso8601String();

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

    final ingRows = await supabase
        .from('categorias')
        .select()
        .eq('ctipo_categoria', 'ingreso')
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

    final conRow = await supabase
        .from('conexiones_bancarias')
        .select()
        .eq('cbusuario_id', user.id)
        .maybeSingle();

    var cuentas = <CuentaFinanciera>[];
    if (conRow != null) {
      final cuentaRows = await supabase
          .from('cuentas_financieras')
          .select()
          .eq('cfconexion_bancaria_id', conRow['cbid'] as String);
      cuentas = [for (final r in cuentaRows) CuentaFinanciera.fromMap(r)];
    }

    final reglaRows =
        await supabase.from('reglas_comercio').select('rccodigo_comercio, rccategoria_id');

    return DatosUsuario(
      perfil: await _perfilConFoto(perfilRow, user.email ?? ''),
      categorias: [for (final r in catRows) Categoria.fromMap(r)],
      categoriasIngreso: [for (final r in ingRows) Categoria.fromMap(r)],
      presupuesto: presupuesto,
      asignaciones: [for (final r in asigRows) AsignacionPresupuestaria.fromMap(r)],
      transacciones: [for (final r in txRows) Transaccion.fromMap(r)],
      conexion: conRow == null ? null : ConexionBancaria.fromMap(conRow),
      cuentas: cuentas,
      reglas: {
        for (final r in reglaRows)
          r['rccodigo_comercio'] as String: r['rccategoria_id'] as String,
      },
    );
  }

  Future<Perfil> _perfilConFoto(Map<String, dynamic> row, String correo) async 
  {
    final ruta = row['pfoto_ruta'] as String?;
    String? url;
    if (ruta != null) {
      try {
        url = await supabase.storage.from('avatars').createSignedUrl(ruta, 86400);
      } catch (_) {}
    }
    return Perfil.fromMap(row, correo: correo, fotoUrl: url);
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

  // ───────────── Categorías y presupuesto ─────────────
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

  // ───────────── Conexión bancaria ─────────────
  /// Crea la conexión del usuario o la reactiva si ya existía (máx. una por usuario).
  Future<ConexionBancaria> guardarConexion({
    required String usuarioId,
    required String codigo,
    required String nombre,
  }) async {
    final row = await supabase
        .from('conexiones_bancarias')
        .upsert(
          {
            'cbusuario_id': usuarioId,
            'cbcodigo_institucion': codigo,
            'cbnombre_institucion': nombre,
            'cbestado': 'conectada',
            'cbfecha_autorizacion': _ahoraUtc(),
          },
          onConflict: 'cbusuario_id',
        )
        .select()
        .single();
    return ConexionBancaria.fromMap(row);
  }

  Future<List<CuentaFinanciera>> guardarCuentas(
    String conexionId,
    List<BankAccountDto> cuentas,
  ) async {
    final ahora = _ahoraUtc();
    final rows = await supabase
        .from('cuentas_financieras')
        .upsert(
          [
            for (final c in cuentas)
              {
                'cfconexion_bancaria_id': conexionId,
                'cfidentificador_externo': c.accountId,
                'cfnombre_cuenta': c.name,
                'cftipo_cuenta': c.tipoDb,
                'cfmoneda': c.currency,
                'cfsaldo_actual': c.currentBalance,
                'cfmonto_disponible': c.availableBalance,
                'cflimite_credito': c.creditLimit,
                'cfultima_actualizacion': ahora,
              },
          ],
          onConflict: 'cfconexion_bancaria_id,cfidentificador_externo',
        )
        .select();
    return [for (final r in rows) CuentaFinanciera.fromMap(r)];
  }

  Future<void> marcarSincronizacion(String conexionId) async {
    await supabase
        .from('conexiones_bancarias')
        .update({'cbultima_sincronizacion': _ahoraUtc()}).eq('cbid', conexionId);
  }

  Future<void> revocarConexion(String conexionId) async {
    await supabase.from('conexiones_bancarias').update({'cbestado': 'revocada'}).eq('cbid', conexionId);
  }

  // ───────────── Transacciones ─────────────
  /// Último transaction_id del banco que ya guardamos (el "cursor" de sincronización).
  Future<String?> ultimoCursor() async {
    final rows = await supabase
        .from('transacciones')
        .select('tidentificador_externo')
        .eq('torigen', 'bancario')
        .order('tidentificador_externo', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['tidentificador_externo'] as String?;
  }

  /// Inserta los movimientos del banco ignorando los que ya existían.
  /// Devuelve SOLO los realmente nuevos (sin categoría todavía).
  Future<List<Transaccion>> insertarTransaccionesBanco(
    String usuarioId,
    Map<String, String> cuentaIdPorExterno,
    List<BankTransactionDto> dtos,
  ) async {
    final filas = <Map<String, dynamic>>[];
    for (final d in dtos) {
      final cuentaId = cuentaIdPorExterno[d.accountId];
      if (cuentaId == null) continue;
      final descripcion = d.description.length > 150 ? d.description.substring(0, 150) : d.description;
      filas.add({
        'tusuario_id': usuarioId,
        'tcuenta_financiera_id': cuentaId,
        'tidentificador_externo': d.transactionId,
        'tcodigo_comercio': d.merchantCode,
        'tnombre_comercio': d.merchantName,
        'tdescripcion': descripcion,
        'ttipo_transaccion': d.tipoDb,
        'tmonto': d.amount,
        'tfecha_transaccion': d.bookedAt.toUtc().toIso8601String(),
        'torigen': 'bancario',
      });
    }
    if (filas.isEmpty) return [];

    final rows = await supabase
        .from('transacciones')
        .upsert(
          filas,
          onConflict: 'tcuenta_financiera_id,tidentificador_externo',
          ignoreDuplicates: true,
        )
        .select();
    return [for (final r in rows) Transaccion.fromMap(r)];
  }

  Future<void> insertarTransaccionManual(Transaccion t) async {
    await supabase.from('transacciones').insert({
      'tid': t.id,
      'tusuario_id': t.usuarioId,
      'tcategoria_id': t.categoriaId,
      'tdescripcion': t.descripcion,
      'ttipo_transaccion': t.tipoTransaccion,
      'tmonto': double.parse(t.monto.toStringAsFixed(2)),
      'tfecha_transaccion': t.fechaTransaccion.toUtc().toIso8601String(),
      'torigen': 'manual',
    });
  }

  Future<void> asignarCategoria(String transaccionId, String? categoriaId) async {
    await supabase
        .from('transacciones')
        .update({'tcategoria_id': categoriaId}).eq('tid', transaccionId);
  }

  Future<void> guardarRegla({
    required String usuarioId,
    required String codigo,
    required String? nombre,
    required String categoriaId,
  }) async {
    await supabase.from('reglas_comercio').upsert(
      {
        'rcusuario_id': usuarioId,
        'rccodigo_comercio': codigo,
        'rcnombre_comercio': nombre,
        'rccategoria_id': categoriaId,
      },
      onConflict: 'rcusuario_id,rccodigo_comercio',
    );
  }
}
