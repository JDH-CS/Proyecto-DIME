import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/biometric_vault.dart';
import '../../state/app_state.dart';
import '../models/reporte_soporte.dart';

/// Operaciones de perfil, cuenta y soporte contra Supabase.
class CuentaService {
  CuentaService(this._state);

  final AppState _state;

  static const _bucket = 'avatars';

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ───────────── Perfil ─────────────
  Future<void> actualizarPerfil({
    required String nombre,
    required String apellido,
    required DateTime fechaNacimiento,
    required String telefono,
  }) async {
    final p = _state.perfil;
    await supabase.from('perfiles').update({
      'pnombre': nombre,
      'papellido': apellido,
      'pfecha_nacimiento': _fecha(fechaNacimiento),
      'ptelefono': telefono,
    }).eq('pid', p.id);

    _state.reemplazarPerfil(p.copyWith(
      nombre: nombre,
      apellido: apellido,
      fechaNacimiento: fechaNacimiento,
      celular: telefono,
    ));
  }

  Future<void> cambiarFoto(Uint8List bytes, String extension) async {
    final p = _state.perfil;
    var ext = extension.toLowerCase();
    if (ext != 'png' && ext != 'webp') ext = 'jpg';
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final ruta = '${p.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = supabase.storage.from(_bucket);

    await storage.uploadBinary(ruta, bytes, fileOptions: FileOptions(contentType: mime));
    await supabase.from('perfiles').update({'pfoto_ruta': ruta}).eq('pid', p.id);
    final url = await storage.createSignedUrl(ruta, 86400);

    final anterior = p.fotoRuta;
    if (anterior != null) {
      try {
        await storage.remove([anterior]);
      } catch (_) {}
    }
    _state.reemplazarPerfil(p.copyWith(fotoRuta: ruta, fotoUrl: url));
  }

  Future<void> quitarFoto() async {
    final p = _state.perfil;
    final ruta = p.fotoRuta;
    if (ruta == null) return;

    await supabase.from('perfiles').update({'pfoto_ruta': null}).eq('pid', p.id);
    try {
      await supabase.storage.from(_bucket).remove([ruta]);
    } catch (_) {}
    _state.reemplazarPerfil(p.copyWith(quitarFoto: true));
  }

  // ───────────── Cuenta ─────────────
  String get _email {
    final e = supabase.auth.currentUser?.email;
    if (e == null) throw const AuthException('No hay sesión activa');
    return e;
  }

  /// Verifica la contraseña actual, la cambia y actualiza la huella guardada.
  Future<void> cambiarContrasena({required String actual, required String nueva}) async {
    final email = _email;
    await supabase.auth.signInWithPassword(email: email, password: actual);
    await supabase.auth.updateUser(UserAttributes(password: nueva));

    final cred = await BiometricVault.leer();
    if (cred != null && cred.email.toLowerCase() == email.toLowerCase()) {
      await BiometricVault.guardar(email, nueva);
    }
  }

  /// Activa el inicio con huella en este dispositivo (verificando la contraseña).
  Future<void> activarHuella(String password) async {
    final email = _email;
    await supabase.auth.signInWithPassword(email: email, password: password);
    await BiometricVault.guardar(email, password);
  }

  // ───────────── Soporte ─────────────
  Future<void> enviarReporte({
    required String tipo,
    required String asunto,
    required String descripcion,
    required String correo,
  }) async {
    await supabase.from('reportes_soporte').insert({
      'rsusuario_id': _state.perfil.id,
      'rstipo_reporte': tipo,
      'rsasunto': asunto,
      'rsdescripcion': descripcion,
      'rscorreo_contacto': correo,
    });
  }

  Future<List<ReporteSoporte>> misReportes() async {
    final rows = await supabase
        .from('reportes_soporte')
        .select()
        .order('rsfecha_creacion', ascending: false);
    return [for (final r in rows) ReporteSoporte.fromMap(r)];
  }
}
