import 'package:flutter/material.dart' show Color, Colors;

import '../../core/utils/category_color.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/resumen.dart';
import '../../data/models/transaccion.dart';
import '../../state/app_state.dart';

class CategoriaGasto {
  const CategoriaGasto({
    required this.nombre,
    required this.monto,
    required this.pct,
    required this.color,
  });

  final String nombre;
  final double monto;
  final double pct; // 0..100
  final Color color;
}

class ComercioGasto {
  const ComercioGasto({required this.nombre, required this.monto, required this.veces});

  final String nombre;
  final double monto;
  final int veces;
}

class FilaPresupuesto {
  const FilaPresupuesto({required this.nombre, required this.asignado, required this.gastado});

  final String nombre;
  final double asignado;
  final double gastado;

  double get disponible => asignado - gastado;
  double get pct => asignado > 0 ? gastado / asignado * 100 : 0;
  bool get excedida => gastado > asignado + 0.004;
}

/// Todos los números del informe, calculados a partir de los datos del usuario.
class ReportData {
  const ReportData({
    required this.nombre,
    required this.meses,
    required this.desde,
    required this.hasta,
    required this.mensual,
    required this.ingresosTotal,
    required this.gastosTotal,
    required this.porCategoria,
    required this.sinCategoriaMonto,
    required this.sinCategoriaCantidad,
    required this.topComercios,
    required this.topGastos,
    required this.presupuesto,
    required this.patrimonio,
    required this.patrimonioDesdeBanco,
    required this.patrimonioActual,
  });

  final String nombre;
  final int meses;
  final DateTime desde;
  final DateTime hasta;
  final List<IngresoGastoMensual> mensual;
  final double ingresosTotal;
  final double gastosTotal;
  final List<CategoriaGasto> porCategoria;
  final double sinCategoriaMonto;
  final int sinCategoriaCantidad;
  final List<ComercioGasto> topComercios;
  final List<Transaccion> topGastos;
  final List<FilaPresupuesto> presupuesto;
  final List<PatrimonioMensual> patrimonio;
  final bool patrimonioDesdeBanco;
  final double patrimonioActual;

  bool get hayDatos => ingresosTotal > 0 || gastosTotal > 0;
  double get ahorroNeto => ingresosTotal - gastosTotal;
  double get tasaAhorro => ingresosTotal > 0 ? ahorroNeto / ingresosTotal * 100 : 0;
  double get promedioIngresos => ingresosTotal / meses;
  double get promedioGastos => gastosTotal / meses;
  double get patrimonioCambio => patrimonio.fold(0.0, (a, p) => a + p.cambio);
  List<FilaPresupuesto> get excedidas => presupuesto.where((f) => f.excedida).toList();
  double get asignadoMes => presupuesto.fold(0.0, (a, f) => a + f.asignado);
  double get gastadoMes => presupuesto.fold(0.0, (a, f) => a + f.gastado);

  /// Calcula el informe de los últimos [meses] meses (incluye el mes actual).
  static ReportData desdeEstado(AppState s, int meses) {
    final ahora = DateTime.now();
    final mensual = s.ingresosVsGastos(meses);
    final gastosPorMes = s.gastosMensuales(meses);

    final ingresosTotal = mensual.fold(0.0, (a, m) => a + m.ingresos);
    final gastosTotal = mensual.fold(0.0, (a, m) => a + m.gastos);

    // Gasto por categoría
    final temporales = <(String, double, Color)>[];
    var categorizado = 0.0;
    for (final c in s.categorias) {
      final monto = gastosPorMes.fold(0.0, (a, m) => a + (m.porCategoria[c.id] ?? 0));
      if (monto > 0) {
        temporales.add((c.nombre, monto, CategoryColors.of(c)));
        categorizado += monto;
      }
    }
    final sinCategoria = gastosTotal - categorizado;
    if (sinCategoria > 0.009) temporales.add(('Sin categoría', sinCategoria, Colors.grey));
    temporales.sort((a, b) => b.$2.compareTo(a.$2));
    final porCategoria = [
      for (final t in temporales)
        CategoriaGasto(
          nombre: t.$1,
          monto: t.$2,
          pct: gastosTotal > 0 ? t.$2 / gastosTotal * 100 : 0,
          color: t.$3,
        ),
    ];

    // Transacciones del periodo
    final gastos = s
        .transaccionesDelPeriodo(meses)
        .where((t) => t.tipoTransaccion == 'gasto')
        .toList();

    final comercios = <String, (double, int)>{};
    for (final t in gastos) {
      final nombre = (t.nombreComercio ?? t.descripcion).trim();
      final previo = comercios[nombre] ?? (0.0, 0);
      comercios[nombre] = (previo.$1 + t.monto, previo.$2 + 1);
    }
    final topComercios = [
      for (final e in comercios.entries)
        ComercioGasto(nombre: e.key, monto: e.value.$1, veces: e.value.$2),
    ]..sort((a, b) => b.monto.compareTo(a.monto));

    final topGastos = [...gastos]..sort((a, b) => b.monto.compareTo(a.monto));

    final sinCatTx = gastos.where((t) => t.categoriaId == null).toList();

    // Presupuesto del mes actual
    final presupuesto = <FilaPresupuesto>[];
    if (s.totalAsignado > 0) {
      for (final c in s.categorias) {
        final a = s.asignado(c.id);
        final g = s.gastado(c.id);
        if (a > 0 || g > 0) {
          presupuesto.add(FilaPresupuesto(nombre: c.nombre, asignado: a, gastado: g));
        }
      }
    }

    // Patrimonio neto (últimos [meses] meses)
    final pat = s.patrimonio;
    final recorte = pat.length > meses ? pat.sublist(pat.length - meses) : pat;

    return ReportData(
      nombre: s.perfil.nombreCompleto,
      meses: meses,
      desde: DateTime(ahora.year, ahora.month - (meses - 1), 1),
      hasta: ahora,
      mensual: mensual,
      ingresosTotal: ingresosTotal,
      gastosTotal: gastosTotal,
      porCategoria: porCategoria,
      sinCategoriaMonto: sinCategoria > 0.009 ? sinCategoria : 0,
      sinCategoriaCantidad: sinCatTx.length,
      topComercios: topComercios.take(5).toList(),
      topGastos: topGastos.take(5).toList(),
      presupuesto: presupuesto,
      patrimonio: recorte,
      patrimonioDesdeBanco: s.patrimonioDesdeBanco,
      patrimonioActual: pat.last.valor,
    );
  }

  /// Variables que rellenan los textos de la plantilla ({nombre}, {ingresos_total}, ...).
  Map<String, String> variables() {
    final top = porCategoria.isNotEmpty ? porCategoria.first : null;
    final com = topComercios.isNotEmpty ? topComercios.first : null;
    final ahora = DateTime.now();

    return {
      'nombre': nombre,
      'meses_texto': meses == 1 ? '1 mes' : (meses == 12 ? '1 año (12 meses)' : '$meses meses'),
      'periodo': meses == 1
          ? Fmt.mesLargo(hasta)
          : '${Fmt.mesLargo(desde)} a ${Fmt.mesLargo(hasta)}',
      'desde': Fmt.fecha(desde),
      'hasta': Fmt.fecha(hasta),
      'fecha_generacion': Fmt.fecha(ahora),
      'ingresos_total': Fmt.moneda(ingresosTotal),
      'gastos_total': Fmt.moneda(gastosTotal),
      'ingresos_promedio': Fmt.moneda(promedioIngresos),
      'gastos_promedio': Fmt.moneda(promedioGastos),
      'ahorro': Fmt.moneda(ahorroNeto.abs()),
      'tasa_ahorro': tasaAhorro.toStringAsFixed(0),
      'cat_top': top?.nombre ?? '-',
      'cat_top_monto': Fmt.moneda(top?.monto ?? 0),
      'cat_top_pct': (top?.pct ?? 0).toStringAsFixed(0),
      'com_top': com?.nombre ?? '-',
      'com_top_monto': Fmt.moneda(com?.monto ?? 0),
      'com_top_veces': com == null ? '-' : (com.veces == 1 ? '1 compra' : '${com.veces} compras'),
      'gastado_mes': Fmt.moneda(gastadoMes),
      'asignado_mes': Fmt.moneda(asignadoMes),
      'pct_ejecucion': asignadoMes > 0 ? (gastadoMes / asignadoMes * 100).toStringAsFixed(0) : '0',
      'n_excedidas': '${excedidas.length}',
      'lista_excedidas': excedidas.map((f) => f.nombre).join(', '),
      'n_sin_categoria': '$sinCategoriaCantidad',
      'monto_sin_categoria': Fmt.moneda(sinCategoriaMonto),
      'patrimonio_actual': Fmt.moneda(patrimonioActual),
      'patrimonio_cambio': Fmt.monedaConSigno(patrimonioCambio),
    };
  }
}
