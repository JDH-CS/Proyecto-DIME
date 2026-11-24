import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/biometric_vault.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';
import '../support/report_form_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

/// "Administrar cuenta de DIME": correo, contraseña y seguridad.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool? _huella; // null = cargando

  @override
  void initState() {
    super.initState();
    _cargarHuella();
  }

  Future<void> _cargarHuella() async {
    final cred = await BiometricVault.leer();
    final email = supabase.auth.currentUser?.email?.toLowerCase();
    if (mounted) {
      setState(() => _huella = cred != null && cred.email.toLowerCase() == email);
    }
  }

  Future<void> _cambiarHuella(bool activar) async {
    if (!activar) {
      await BiometricVault.borrar();
      if (mounted) {
        setState(() => _huella = false);
        showSoon(context, 'Inicio con huella desactivado en este dispositivo');
      }
      return;
    }

    final password = await _pedirContrasena();
    if (password == null || !mounted) return;

    final state = context.read<AppState>();
    try {
      await CuentaService(state).activarHuella(password);
      if (mounted) {
        setState(() => _huella = true);
        showSoon(context, 'Inicio con huella activado');
      }
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    }
  }

  Future<String?> _pedirContrasena() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirma tu contraseña'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Contraseña actual'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.isEmpty ? null : ctrl.text),
            child: const Text('Activar'),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().perfil;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta de DIME')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Etiqueta('Correo electrónico'),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, color: Colors.black54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(p.correo,
                        style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black26),
                ],
              ),
            ),
            _Etiqueta('Seguridad'),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: const Text('Cambiar contraseña',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded),
                    title: const Text('Iniciar sesión con huella',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Solo en este dispositivo'),
                    value: _huella ?? false,
                    onChanged: _huella == null ? null : _cambiarHuella,
                  ),
                ],
              ),
            ),
            _Etiqueta('Otros cambios'),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text('Cambiar correo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Escríbenos y lo gestionamos por correo'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReportFormScreen(
                      tipoInicial: 'consulta',
                      asuntoInicial: 'Solicitud de cambio de correo',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                title: Text('Eliminar mi cuenta',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    )),
                subtitle: const Text('Borra tu cuenta y todos tus datos de forma permanente'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54),
      ),
    );
  }
}
