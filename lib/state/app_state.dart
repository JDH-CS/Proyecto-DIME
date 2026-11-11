import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/ids.dart';
import '../core/utils/ui_helpers.dart';
import '../data/models/categoria.dart';
import '../data/models/perfil.dart';
import '../data/models/presupuesto.dart';
import '../data/models/resumen.dart';
import '../data/models/transaccion.dart';
import '../data/repositories/dime_repository.dart';

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

/// Estado global (Provider). Los datos vienen de Supabase vía [DimeRepository].
///
/// Los cambios se aplican primero en pantalla (respuesta inmediata) y se guardan
/// en Supabase en segundo plano, en orden. Si algo falla, se recargan los datos reales.
class AppState extends ChangeNotifier {
  final DimeRepository _repo = DimeRepository();

  Perfil? _perfil;
  Presupuesto? _presupuesto;
  List<Categoria> _categorias = [];
  List<Transaccion> _transacciones = [];
  List<AsignacionPresupuestaria> _asignaciones = [];
  CategoriaOrden _orden = CategoriaOrden.personalizado;
  Future<void> _cola = Future.value();

  /// PENDIENTE: el patrimonio neto real saldrá de las cuentas financieras
  /// (Mockoon). Mientras tanto es una serie fija de demostración.
  static const List<double> _patrimonioDemo = [
    1200, 1650, 2300, 2150, 2700, 2700, 3250, 3100, 3800, 4300, 4950, 5750,
  ];

  // ───────────────────────── Carga ─────────────────────────
  /// Descarga todos los datos del usuario logueado.
  Future<void> cargar() async {
    final d = await _repo.cargarTodo();
    _perfil = d.perfil;
    _presupuesto = d.presupuesto;
    _categorias = [...d.categorias];
    _asignaciones = [...d.asignaciones];
    _transacciones = [...d.transacciones];
    _orden = CategoriaOrden.personalizado;
    notifyListeners();
  }

  // ───────────────────────── Lectura ─────────────────────────
  bool get cargado => _perfil != null;
  Perfil get perfil => _perfil!;
  Presupuesto get presupuesto => _presupuesto!;
  CategoriaOrden get orden => _orden;
  UnmodifiableListView<Categoria> get categorias => UnmodifiableListView(_categorias);

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

  // ───────────────────────── Acciones ─────────────────────────
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
