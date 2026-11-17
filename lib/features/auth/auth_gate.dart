import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/recovery_guard.dart';
import '../../navigation/main_shell.dart';
import '../../state/app_state.dart';
import 'login_screen.dart';

/// Pantalla de arranque: si ya hay sesión guardada, carga los datos y entra
/// directo a la app; si no, muestra el Login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _inicio = _iniciar();

  Future<bool> _iniciar() async {
    // Recuperación de contraseña interrumpida: no se entra sin crear la nueva contraseña.
    if (await RecoveryGuard.pendiente()) {
      await supabase.auth.signOut(scope: SignOutScope.local);
      await RecoveryGuard.limpiar();
      return false;
    }

    if (supabase.auth.currentSession == null) return false;
    try {
      if (!mounted) return false;
      await context.read<AppState>().cargar();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _inicio,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == true ? const MainShell() : const LoginScreen();
      },
    );
  }
}
