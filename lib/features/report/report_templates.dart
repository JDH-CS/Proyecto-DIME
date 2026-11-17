import 'report_data.dart';

/// Plantilla del informe: TEXTO PRE-ESCRITO con marcadores {variable}.
///
/// Para cambiar la redacción basta con editar estos textos. Los marcadores se
/// rellenan con [ReportData.variables]. Evita caracteres fuera del alfabeto
/// latino (por ejemplo, viñetas o guiones largos) porque el PDF usa la fuente
/// estándar Helvetica.
class ReportTemplates {
  ReportTemplates._();

  // ───────────── Encabezado ─────────────
  static const titulo = 'Informe financiero';
  static const subtitulo = 'Periodo: {periodo}';

  static const intro =
      'Este informe resume la actividad financiera de {nombre} durante {meses_texto} '
      '({desde} a {hasta}). Fue generado automáticamente por DIME el {fecha_generacion}.';

  // ───────────── Resumen ─────────────
  static const resumenGeneral =
      'En este periodo tus ingresos sumaron {ingresos_total} y tus gastos {gastos_total}. '
      'El promedio mensual fue de {ingresos_promedio} en ingresos y {gastos_promedio} en gastos.';

  static const resultadoAhorro =
      'Tu balance del periodo fue positivo: ahorraste {ahorro}, el {tasa_ahorro}% de tus ingresos.';
  static const resultadoDeficit =
      'Tu balance del periodo fue negativo: gastaste {ahorro} más de lo que ingresaste.';
  static const resultadoEquilibrio =
      'Tus ingresos y gastos estuvieron prácticamente equilibrados.';

  // ───────────── Gastos ─────────────
  static const categoriaPrincipal =
      'Tu mayor gasto fue {cat_top}, con {cat_top_monto} ({cat_top_pct}% del total de gastos).';
  static const comercioPrincipal =
      'El comercio donde más gastaste fue {com_top}: {com_top_monto} en {com_top_veces}.';

  // ───────────── Presupuesto del mes ─────────────
  static const presupuestoIntro =
      'Este mes llevas gastado {gastado_mes} de los {asignado_mes} que asignaste ({pct_ejecucion}%).';
  static const presupuestoExcedido =
      'Categorías que superaron su presupuesto este mes: {lista_excedidas}.';
  static const presupuestoOk = 'Ninguna categoría ha superado su presupuesto este mes.';

  // ───────────── Patrimonio ─────────────
  static const patrimonioTexto =
      'Tu patrimonio neto actual es {patrimonio_actual}. Durante el periodo cambió {patrimonio_cambio}.';
  static const patrimonioBaseBanco = 'Se calcula con los saldos de tu banco vinculado.';
  static const patrimonioBaseManual =
      'Se calcula con los ingresos y gastos registrados en DIME.';

  // ───────────── Observaciones ─────────────
  static const obsAhorroAlto =
      'Excelente: ahorraste más del 20% de tus ingresos. Considera destinar ese excedente a una meta de ahorro.';
  static const obsAhorroMedio =
      'Vas por buen camino: tu tasa de ahorro está entre el 10% y el 20% de tus ingresos.';
  static const obsAhorroBajo =
      'Tu margen de ahorro es bajo ({tasa_ahorro}%). Revisa tus categorías con mayor gasto para encontrar oportunidades.';
  static const obsDeficit =
      'Gastaste más de lo que ingresaste. Considera reducir gastos en {cat_top} y asignar tu dinero con más anticipación.';
  static const obsConcentracion =
      'Más del 40% de tus gastos se concentra en {cat_top}.';
  static const obsSinCategoria =
      'Tienes {n_sin_categoria} transacciones sin categoría por {monto_sin_categoria}. Clasificarlas hace tus informes más precisos.';
  static const obsExcedidas =
      'Hay {n_excedidas} categoría(s) por encima de su presupuesto este mes.';

  // ───────────── Sin datos / pie ─────────────
  static const sinDatos =
      'No hay transacciones registradas en este periodo. Cuando vincules tu banco o registres movimientos, '
      'tu informe mostrará aquí el resumen completo.';
  static const notaFinal =
      'Informe generado automáticamente por DIME con los datos registrados en tu cuenta. '
      'Es informativo y no constituye asesoría financiera.';

  // ───────────── Motor de plantilla ─────────────
  /// Reemplaza cada {variable} por su valor.
  static String render(String plantilla, Map<String, String> v) =>
      plantilla.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => v[m[1]] ?? '');

  /// Texto del balance según el resultado del periodo.
  static String resultado(ReportData d, Map<String, String> v) {
    if (d.ahorroNeto > 0.01) return render(resultadoAhorro, v);
    if (d.ahorroNeto < -0.01) return render(resultadoDeficit, v);
    return render(resultadoEquilibrio, v);
  }

  /// Observaciones automáticas según los datos del usuario.
  static List<String> observaciones(ReportData d, Map<String, String> v) {
    final lista = <String>[];

    if (d.ingresosTotal > 0) {
      if (d.ahorroNeto < -0.01) {
        lista.add(render(obsDeficit, v));
      } else if (d.tasaAhorro >= 20) {
        lista.add(render(obsAhorroAlto, v));
      } else if (d.tasaAhorro >= 10) {
        lista.add(render(obsAhorroMedio, v));
      } else {
        lista.add(render(obsAhorroBajo, v));
      }
    }
    if (d.porCategoria.isNotEmpty && d.porCategoria.first.pct >= 40) {
      lista.add(render(obsConcentracion, v));
    }
    if (d.excedidas.isNotEmpty) lista.add(render(obsExcedidas, v));
    if (d.sinCategoriaCantidad > 0) lista.add(render(obsSinCategoria, v));
    return lista;
  }
}
