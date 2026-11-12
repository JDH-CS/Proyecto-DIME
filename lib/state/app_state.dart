import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/constants/merchant_defaults.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/ids.dart';
import '../core/utils/ui_helpers.dart';
import '../data/models/categoria.dart';
import '../data/models/conexion_bancaria.dart';
import '../data/models/cuenta_financiera.dart';
import '../data/models/perfil.dart';
import '../data/models/presupuesto.dart';
import '../data/models/resumen.dart';
import '../data/models/transaccion.dart';
import '../data/repositories/dime_repository.dart';
import '../data/services/bank_api.dart';
import '../data/services/bank_token_store.dart';

enum CategoriaOrden {
  personalizado('Orden manual'),
  nombreAz('Nombre (A-Z)'),
  mayorPresupuesto('Mayor presupuesto'),
  mayorGasto('Mayor gasto'),
  porcentajeGastado('% gastado'),
  mayorDisponible('Más disponible');

  const CategoriaOrden(this.label);
  final String label;
}

/// Estado global (Provider). Los datos vienen de Supabase vía [DimeRepository]
/// y del banco simulado vía [BankApi].
///
/// Los cambios simples (categorías, asignaciones, transacciones manuales) se
/// aplican primero en pantalla y se guardan en Supabase en segundo plano, en
/// orden. Si algo falla, se recargan los datos reales.
class AppState extends ChangeNotifier {
  final DimeRepository _repo = DimeRepository();
  final BankApi _bank = BankApi();

  Perfil? _perfil;
  Presupuesto? _presupuesto;
  List<Categoria> _categorias = [];
  List<Categoria> _categoriasIngreso = [];
  List<Transaccion> _transacciones = [];
  List<AsignacionPresupuestaria> _asignaciones = [];
  ConexionBancaria? _conexion;
  List<CuentaFinanciera> _cuentas = [];
  Map<String, String> _reglas = {};
  CategoriaOrden _orden = CategoriaOrden.personalizado;
  Future<void> _cola = Future.value();
  bool _sincronizando = false;

  /// PENDIENTE: el patrimonio neto real saldrá de las cuentas financieras.
  /// Mientras tanto es una serie fija de demostración.
  static const List<double> _patrimonioDemo = [
    1200, 1650, 2300, 2150, 2700, 2700, 3250, 3100, 3800, 4300, 4950, 5750,
  ];

  // ───────────────────────── Carga ─────────────────────────
  Future<void> cargar() async {
    final d = await _repo.cargarTodo();
    _perfil = d.perfil;
    _presupuesto = d.presupuesto;
    _categorias = [...d.categorias];
    _categoriasIngreso = [...d.categoriasIngreso];
    _asignaciones = [...d.asignaciones];
    _transacciones = [...d.transacciones];
    _conexion = d.conexion;
    _cuentas = [...d.cuentas];
    _reglas = {...d.reglas};
    _orden = CategoriaOrden.personalizado;
    notifyListeners();
  }

  // ───────────────────────── Lectura ─────────────────────────
  bool get cargado => _perfil != null;
  Perfil get perfil => _perfil!;
  Presupuesto get presupuesto => _presupuesto!;
  CategoriaOrden get orden => _orden;
  UnmodifiableListView<Categoria> get categorias => UnmodifiableListView(_categorias);
  UnmodifiableListView<Categoria> get categoriasIngreso =>
      UnmodifiableListView(_categoriasIngreso);

  ConexionBancaria? get conexion => _conexion;
  UnmodifiableListView<CuentaFinanciera> get cuentas => UnmodifiableListView(_cuentas);
  bool get bancoVinculado => _conexion?.conectada ?? false;
  bool get sincronizando => _sincronizando;

  /// Movimientos de ingreso/gasto que todavía no tienen categoría.
  List<Transaccion> get transaccionesPendientes {
    final l = _transacciones
        .where((t) =>
            t.categoriaId == null &&
            (t.tipoTransaccion == 'gasto' || t.tipoTransaccion == 'ingreso'))
        .toList();
    l.sort((a, b) => a.fechaTransaccion.compareTo(b.fechaTransaccion));
    return l;
  }

  DateTime get mesActual {
    final n = DateTime.now();
    return DateTime(n.year, n.month);
  }

  /// Las 4 primeras categorías según el orden que el usuario eligió en "Categorías".
  List<Categoria> get prioridades => _categorias.take(4).toList();

  double asignado(String categoriaId) => _asignaciones
      .where((a) => a.categoriaId == categoriaId)
      .fold(0.0, (s, a) => s + a.montoAsignado);

  double gastado(String categoriaId) => _suma(mesActual, 'gasto', categoriaId);

  double disponible(String categoriaId) => asignado(categoriaId) - gastado(categoriaId);

  double porcentajeGastado(String categoriaId) {
    final a = asignado(categoriaId);
    return a <= 0 ? 0 : gastado(categoriaId) / a;
  }

  double get totalAsignado => _categorias.fold(0.0, (s, c) => s + asignado(c.id));
  double get totalGastado => _categorias.fold(0.0, (s, c) => s + gastado(c.id));
  double get ingresosMes => _suma(mesActual, 'ingreso');

  /// Dinero que entró este mes y aún no está asignado a ninguna categoría.
  double get dineroParaAsignar => ingresosMes - totalAsignado;

  Categoria? categoriaPorId(String? id) {
    if (id == null) return null;
    for (final c in _categorias) {
      if (c.id == id) return c;
    }
    for (final c in _categoriasIngreso) {
      if (c.id == id) return c;
    }
    return null;
  }

  CuentaFinanciera? cuentaPorId(String? id) {
    if (id == null) return null;
    for (final c in _cuentas) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Categoría sugerida para una transacción: primero la regla del usuario
  /// (comercio -> categoría), luego los comercios conocidos de fábrica.
  Categoria? sugerencia(Transaccion t) {
    final codigo = t.codigoComercio;
    if (codigo == null) return null;

    final reglaId = _reglas[codigo];
    final porRegla = categoriaPorId(reglaId);
    if (porRegla != null) return porRegla;

    final nombre = MerchantDefaults.categoriaPorCodigo[codigo];
    if (nombre == null) return null;
    final lista = t.tipoTransaccion == 'ingreso' ? _categoriasIngreso : _categorias;
    for (final c in lista) {
      if (c.nombre.toLowerCase() == nombre.toLowerCase()) return c;
    }
    return null;
  }

  // ───────────────────────── Dashboard ─────────────────────────
  List<DateTime> ultimosMeses(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) => DateTime(now.year, now.month - (n - 1 - i)));
  }

  List<GastoMensual> gastosMensuales(int meses) => [
        for (final m in ultimosMeses(meses))
          GastoMensual(
            mes: m,
            porCategoria: {for (final c in _categorias) c.id: _suma(m, 'gasto', c.id)},
          ),
      ];

  List<IngresoGastoMensual> ingresosVsGastos(int meses) => [
        for (final m in ultimosMeses(meses))
          IngresoGastoMensual(
            mes: m,
            ingresos: _suma(m, 'ingreso'),
            gastos: _suma(m, 'gasto'),
          ),
      ];

  List<PatrimonioMensual> get patrimonio {
    final meses = ultimosMeses(_patrimonioDemo.length);
    return [
      for (var i = 0; i < meses.length; i++)
        PatrimonioMensual(
          mes: meses[i],
          valor: _patrimonioDemo[i],
          cambio: i == 0 ? 0 : _patrimonioDemo[i] - _patrimonioDemo[i - 1],
        ),
    ];
  }

  // ───────────────────────── Categorías ─────────────────────────
  void reordenar(int oldIndex, int newIndex) {
    // newIndex ya viene ajustado (onReorderItem).
    final c = _categorias.removeAt(oldIndex);
    _categorias.insert(newIndex, c);
    _orden = CategoriaOrden.personalizado;
    notifyListeners();

    final snapshot = [..._categorias];
    _encolar(() => _repo.guardarOrden(snapshot));
  }

  void ordenarPor(CategoriaOrden o) {
    _orden = o;
    switch (o) {
      case CategoriaOrden.personalizado:
        break;
      case CategoriaOrden.nombreAz:
        _categorias.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      case CategoriaOrden.mayorPresupuesto:
        _categorias.sort((a, b) => asignado(b.id).compareTo(asignado(a.id)));
      case CategoriaOrden.mayorGasto:
        _categorias.sort((a, b) => gastado(b.id).compareTo(gastado(a.id)));
      case CategoriaOrden.porcentajeGastado:
        _categorias.sort((a, b) => porcentajeGastado(b.id).compareTo(porcentajeGastado(a.id)));
      case CategoriaOrden.mayorDisponible:
        _categorias.sort((a, b) => disponible(b.id).compareTo(disponible(a.id)));
    }
    notifyListeners();

    if (o != CategoriaOrden.personalizado) {
      final snapshot = [..._categorias];
      _encolar(() => _repo.guardarOrden(snapshot));
    }
  }

  void addCategoria({
    required String nombre,
    required String icono,
    required double montoAsignado,
    bool esPredeterminada = false,
  }) {
    final cat = Categoria(
      id: nuevoUuid(),
      usuarioId: _perfil!.id,
      nombre: nombre,
      tipoCategoria: 'gasto',
      color: AppTheme.chartShades[_categorias.length % AppTheme.chartShades.length].toARGB32(),
      icono: icono,
      esPredeterminada: esPredeterminada,
      fechaCreacion: DateTime.now(),
    );
    _categorias.add(cat);
    _setAsignacionLocal(cat.id, montoAsignado);
    final orden = _categorias.length;
    final presId = _presupuesto!.id;
    notifyListeners();

    _encolar(() async {
      await _repo.insertarCategoria(cat, orden);
      await _repo.guardarAsignacion(presId, cat.id, montoAsignado);
    });
  }

  void editarCategoria(
    String id, {
    required String nombre,
    required String icono,
    required double montoAsignado,
  }) {
    final i = _categorias.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _categorias[i] = _categorias[i].copyWith(nombre: nombre, icono: icono);
    _setAsignacionLocal(id, montoAsignado);
    final presId = _presupuesto!.id;
    notifyListeners();

    _encolar(() async {
      await _repo.actualizarCategoria(id, nombre: nombre, icono: icono);
      await _repo.guardarAsignacion(presId, id, montoAsignado);
    });
  }

  /// Suma [monto] al presupuesto que ya tiene la categoría (asignación rápida).
  void asignarMas(String categoriaId, double monto) {
    if (monto <= 0) return;
    final nuevo = asignado(categoriaId) + monto;
    _setAsignacionLocal(categoriaId, nuevo);
    final presId = _presupuesto!.id;
    notifyListeners();

    _encolar(() => _repo.guardarAsignacion(presId, categoriaId, nuevo));
  }

  void eliminarCategoria(String id) {
    _categorias.removeWhere((c) => c.id == id);
    _asignaciones.removeWhere((a) => a.categoriaId == id);
    // En la BD las transacciones quedan "sin clasificar" (tcategoria_id = null).
    _transacciones = [
      for (final t in _transacciones) t.categoriaId == id ? t.sinCategoria() : t,
    ];
    notifyListeners();

    _encolar(() => _repo.eliminarCategoria(id));
  }

  // ───────────────────────── Transacciones ─────────────────────────
  /// Asigna una categoría a una transacción. Si [recordar] es true, guarda la
  /// regla "este comercio -> esta categoría" para las próximas veces.
  void asignarCategoriaTransaccion(Transaccion t, Categoria c, {bool recordar = false}) {
    final i = _transacciones.indexWhere((x) => x.id == t.id);
    if (i != -1) _transacciones[i] = _transacciones[i].conCategoria(c.id);

    final codigo = t.codigoComercio;
    final nombreComercio = t.nombreComercio;
    final uid = _perfil!.id;
    if (recordar && codigo != null) _reglas[codigo] = c.id;
    notifyListeners();

    _encolar(() async {
      await _repo.asignarCategoria(t.id, c.id);
      if (recordar && codigo != null) {
        await _repo.guardarRegla(
          usuarioId: uid,
          codigo: codigo,
          nombre: nombreComercio,
          categoriaId: c.id,
        );
      }
    });
  }

  void addTransaccionManual({
    required String tipo, // 'gasto' | 'ingreso'
    required double monto,
    required String descripcion,
    required Categoria categoria,
    required DateTime fecha,
  }) {
    final now = DateTime.now();
    final t = Transaccion(
      id: nuevoUuid(),
      usuarioId: _perfil!.id,
      cuentaFinancieraId: null,
      categoriaId: categoria.id,
      identificadorExterno: null,
      codigoComercio: null,
      nombreComercio: null,
      descripcion: descripcion,
      tipoTransaccion: tipo,
      monto: monto,
      fechaTransaccion: fecha,
      origen: 'manual',
      fechaRegistro: now,
      fechaActualizacion: now,
    );
    _transacciones.add(t);
    notifyListeners();

    _encolar(() => _repo.insertarTransaccionManual(t));
  }

  // ───────────────────────── Banco simulado ─────────────────────────
  /// Flujo OAuth simulado completo: autorizar -> token -> cuentas -> guardar en Supabase.
  Future<void> vincularBanco({required String codigo, required String nombre}) async {
    final uid = _perfil!.id;
    final authCode = await _bank.authorize(codigo);
    final tokens = await _bank.exchangeCode(authCode);
    final cuentasDto = await _bank.accounts(tokens.accessToken);

    await BankTokenStore.guardar(uid, tokens);
    final conexion = await _repo.guardarConexion(usuarioId: uid, codigo: codigo, nombre: nombre);
    final cuentas = await _repo.guardarCuentas(conexion.id, cuentasDto);

    _conexion = conexion;
    _cuentas = cuentas;
    notifyListeners();
  }

  /// Pide al banco los movimientos nuevos y los guarda sin categoría.
  /// Devuelve solo los que realmente son nuevos.
  Future<List<Transaccion>> sincronizarBanco() async {
    final conexion = _conexion;
    if (conexion == null || !conexion.conectada) {
      throw const BankApiException('No hay un banco vinculado.');
    }
    if (_sincronizando) return [];
    _sincronizando = true;
    notifyListeners();

    try {
      final uid = _perfil!.id;
      final cursor = await _repo.ultimoCursor();
      final res = await _conTokenValido((token) => _bank.sync(token, cursor: cursor));

      final porExterno = {for (final c in _cuentas) c.identificadorExterno: c.id};
      final nuevas = await _repo.insertarTransaccionesBanco(uid, porExterno, res.added);
      await _repo.marcarSincronizacion(conexion.id);

      _transacciones.addAll(nuevas);
      _conexion = conexion.copyWith(ultimaSincronizacion: DateTime.now());
      return nuevas;
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  /// Revoca el acceso: avisa al banco (si responde), marca la conexión como
  /// revocada y borra los tokens del dispositivo.
  Future<void> desvincularBanco() async {
    final conexion = _conexion;
    if (conexion == null) return;
    final uid = _perfil!.id;

    try {
      await _conTokenValido((token) => _bank.revoke(token));
    } catch (_) {
      // Si el banco simulado no responde, igual desvinculamos de nuestro lado.
    }
    await _repo.revocarConexion(conexion.id);
    await BankTokenStore.borrar(uid);

    _conexion = conexion.copyWith(estado: 'revocada');
    notifyListeners();
  }

  /// Ejecuta [op] con el access token; si el banco responde 401, renueva el
  /// token con el refresh token y reintenta una vez.
  Future<T> _conTokenValido<T>(Future<T> Function(String token) op) async {
    final uid = _perfil!.id;
    var tokens = await BankTokenStore.leer(uid);
    if (tokens == null) {
      throw const BankApiException(
        'No encontramos tu sesión bancaria en este dispositivo. Vincula tu banco de nuevo.',
      );
    }
    try {
      return await op(tokens.accessToken);
    } on BankApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      tokens = await _bank.refresh(tokens.refreshToken);
      await BankTokenStore.guardar(uid, tokens);
      return await op(tokens.accessToken);
    }
  }

  // ───────────────────────── Privado ─────────────────────────
  void _setAsignacionLocal(String categoriaId, double monto) {
    final i = _asignaciones.indexWhere((a) => a.categoriaId == categoriaId);
    if (i == -1) {
      final now = DateTime.now();
      _asignaciones.add(AsignacionPresupuestaria(
        id: nuevoUuid(),
        presupuestoId: _presupuesto!.id,
        categoriaId: categoriaId,
        montoAsignado: monto,
        fechaCreacion: now,
        fechaActualizacion: now,
      ));
    } else {
      _asignaciones[i] = _asignaciones[i].copyWith(montoAsignado: monto);
    }
  }

  /// Ejecuta las escrituras a Supabase una tras otra, en el orden en que se pidieron.
  void _encolar(Future<void> Function() op) {
    _cola = _cola.then((_) async {
      try {
        await op();
      } catch (e) {
        debugPrint('Error al guardar en Supabase: $e');
        messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('No se pudo guardar el cambio. Se restauraron tus datos.'),
          ));
        try {
          await cargar();
        } catch (_) {}
      }
    });
  }

  double _suma(DateTime mes, String tipo, [String? categoriaId]) {
    var total = 0.0;
    for (final t in _transacciones) {
      if (t.tipoTransaccion != tipo) continue;
      if (t.fechaTransaccion.year != mes.year || t.fechaTransaccion.month != mes.month) continue;
      if (categoriaId != null && t.categoriaId != categoriaId) continue;
      total += t.monto;
    }
    return total;
  }
}
