import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/theme/app_theme.dart';
import '../data/mock_data.dart';
import '../data/models/categoria.dart';
import '../data/models/perfil.dart';
import '../data/models/presupuesto.dart';
import '../data/models/resumen.dart';
import '../data/models/transaccion.dart';

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

/// Estado global de la app (Provider + ChangeNotifier).
/// Más adelante, cada método se conecta a Supabase sin tocar las pantallas.
class AppState extends ChangeNotifier {
  AppState({
  required this._perfil,
  required List<Categoria> categorias,
  required List<Transaccion> transacciones,
  required this._presupuesto,
  required List<AsignacionPresupuestaria> asignaciones,
  required this._patrimonioBase,
})  : _categorias = [...categorias],
      _transacciones = [...transacciones],
      _asignaciones = [...asignaciones];

  factory AppState.mock() {
    final cats = MockData.categoriasGasto();
    return AppState(
      perfil: MockData.perfil(),
      categorias: cats,
      transacciones: MockData.transacciones(cats),
      presupuesto: MockData.presupuesto(),
      asignaciones: MockData.asignaciones(cats),
      patrimonioBase: MockData.patrimonioBase,
    );
  }

  Perfil _perfil;
  final List<Categoria> _categorias;
  final List<Transaccion> _transacciones;
  final Presupuesto _presupuesto;
  final List<AsignacionPresupuestaria> _asignaciones;
  final List<double> _patrimonioBase;
  CategoriaOrden _orden = CategoriaOrden.personalizado;

  // ───────────────────────── Lectura ─────────────────────────
  Perfil get perfil => _perfil;
  Presupuesto get presupuesto => _presupuesto;
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
    final meses = ultimosMeses(_patrimonioBase.length);
    return [
      for (var i = 0; i < meses.length; i++)
        PatrimonioMensual(
          mes: meses[i],
          valor: _patrimonioBase[i],
          cambio: i == 0 ? 0 : _patrimonioBase[i] - _patrimonioBase[i - 1],
        ),
    ];
  }

  // ───────────────────────── Acciones ─────────────────────────
  void actualizarPerfil(Perfil p) {
    _perfil = p;
    notifyListeners();
  }

  void reordenar(int oldIndex, int newIndex) 
  {
    final c = _categorias.removeAt(oldIndex);
    _categorias.insert(newIndex, c);
    _orden = CategoriaOrden.personalizado;
    notifyListeners();
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
  }

  void addCategoria({
    required String nombre,
    required String icono,
    required double montoAsignado,
    bool esPredeterminada = false,
  }) {
    final id = 'cat_${DateTime.now().microsecondsSinceEpoch}';
    _categorias.add(Categoria(
      id: id,
      usuarioId: _perfil.id,
      nombre: nombre,
      tipoCategoria: 'gasto',
      color: AppTheme.chartShades[_categorias.length % AppTheme.chartShades.length].toARGB32(),
      icono: icono,
      esPredeterminada: esPredeterminada,
      fechaCreacion: DateTime.now(),
    ));
    _setAsignacion(id, montoAsignado);
    notifyListeners();
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
    _setAsignacion(id, montoAsignado);
    notifyListeners();
  }

  void asignarMas(String categoriaId, double monto) 
  {
    if (monto <= 0) return;
    _setAsignacion(categoriaId, asignado(categoriaId) + monto);
    notifyListeners();
  }

  void eliminarCategoria(String id) {
    _categorias.removeWhere((c) => c.id == id);
    _asignaciones.removeWhere((a) => a.categoriaId == id);
    _transacciones.removeWhere((t) => t.categoriaId == id); // solo mock
    notifyListeners();
  }

  // ───────────────────────── Privado ─────────────────────────
  void _setAsignacion(String categoriaId, double monto) {
    final i = _asignaciones.indexWhere((a) => a.categoriaId == categoriaId);
    if (i == -1) {
      final now = DateTime.now();
      _asignaciones.add(AsignacionPresupuestaria(
        id: 'ap_$categoriaId',
        presupuestoId: _presupuesto.id,
        categoriaId: categoriaId,
        montoAsignado: monto,
        fechaCreacion: now,
        fechaActualizacion: now,
      ));
    } else {
      _asignaciones[i] = _asignaciones[i].copyWith(montoAsignado: monto);
    }
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
