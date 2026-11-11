import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://lsyoripdmiekaoygokai.supabase.co';

  // Publishable key (sb_publishable_...). NUNCA poner aquí la secret key.
  static const String publishableKey = 'sb_publishable_gRsbRnNno-Gt_FydqVLm6Q_Nm83ZMr6';
}

/// Acceso rápido al cliente: supabase.auth, supabase.from('tabla')...
SupabaseClient get supabase => Supabase.instance.client;