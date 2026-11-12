/// Dirección del banco simulado (Mockoon).
///
/// Se puede cambiar sin tocar código con --dart-define:
///   flutter run --dart-define=BANK_API_URL=http://192.168.1.50:3000
///   flutter build apk --release --dart-define=BANK_API_URL=http://192.168.1.50:3000
///
/// Valores típicos:
///   Emulador de Android ......... http://10.0.2.2:3000   (valor por defecto)
///   Celular con USB + adb reverse  http://localhost:3000
///   Celular por Wi-Fi ........... http://IP-DE-TU-PC:3000
class BankApiConfig {
  BankApiConfig._();

  static const String baseUrl =
      String.fromEnvironment('BANK_API_URL', defaultValue: 'http://10.0.2.2:3000');
}
