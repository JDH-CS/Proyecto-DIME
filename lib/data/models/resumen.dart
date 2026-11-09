/// Modelos de solo lectura calculados para el Dashboard.
class GastoMensual {
  const GastoMensual({required this.mes, required this.porCategoria});

  final DateTime mes;
  final Map<String, double> porCategoria; // categoriaId -> monto

  double get total => porCategoria.values.fold(0.0, (a, b) => a + b);
}

class IngresoGastoMensual {
  const IngresoGastoMensual({required this.mes, required this.ingresos, required this.gastos});

  final DateTime mes;
  final double ingresos;
  final double gastos;
}

class PatrimonioMensual {
  const PatrimonioMensual({required this.mes, required this.valor, required this.cambio});

  final DateTime mes;
  final double valor;
  final double cambio; // vs. mes anterior (0 en el primer mes)
}
