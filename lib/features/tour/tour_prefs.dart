import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda, por usuario y en este dispositivo, si ya vio el tour guiado.
class TourPrefs {
  TourPrefs._();

  static String _key(String userId) => 'dime_tour_done_$userId';

  static Future<bool> completado(String userId) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key(userId)) ?? false;
  }

  static Future<void> marcarCompletado(String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(userId), true);
  }

  /// Para volver a mostrar el tour (por ejemplo, al ensayar la presentación).
  static Future<void> reiniciar(String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(userId));
  }
}
