/// Validadores de formularios (mensajes en español).
class Validators {
  Validators._();

  static String? requerido(String? v, [String campo = 'Este campo']) =>
      (v == null || v.trim().isEmpty) ? '$campo es obligatorio' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Correo electrónico inválido';
  }

  static String? passwordLogin(String? v) =>
      (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null;

  static String? passwordRegistro(String? v) {
    if (v == null || v.isEmpty) return 'Crea una contraseña';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  /// Cédula panameña: 8-123-4567, 1-23-456, PE-1-234, E-8-12345, N-12-123, 4PI-5-678...
  /// (Ajusta el regex si necesitan otro formato.)
  static String? cedulaPanama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu cédula';
    final ok = RegExp(r'^(?:PE|E|N|(?:[1-9]|1[0-3])(?:AV|PI)?)-\d{1,4}-\d{1,6}$')
        .hasMatch(v.trim().toUpperCase());
    return ok ? null : 'Formato inválido. Ej: 8-912-1456';
  }

  static String? pasaporte(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu pasaporte';
    final ok = RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(v.trim().toUpperCase());
    return ok ? null : 'Pasaporte inválido (6 a 12 letras o números)';
  }

  /// Celular panameño: 6XXX-XXXX
  static String? celularPanama(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu número de celular';
    return RegExp(r'^6\d{3}-\d{4}$').hasMatch(v.trim())
        ? null
        : 'Formato inválido. Ej: 6123-4567';
  }
}
