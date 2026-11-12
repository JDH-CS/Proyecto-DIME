/// Comercios que DIME "reconoce" de fábrica: código de comercio -> nombre de la
/// categoría sugerida. Si el usuario ya tiene una regla propia (reglas_comercio)
/// para ese código, la regla tiene prioridad.
class MerchantDefaults {
  MerchantDefaults._();

  static const Map<String, String> categoriaPorCodigo = {
    'REY': 'Alimentación',
    'NFLX': 'Suscripciones',
    'SPOT': 'Suscripciones',
    'UBER': 'Transporte',
    'PUMA': 'Transporte',
    'AMZN': 'Compras',
    'ARROCHA': 'Salud',
    'PAYROLL': 'Salario',
  };
}
