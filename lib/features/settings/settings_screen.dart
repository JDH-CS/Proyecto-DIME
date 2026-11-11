import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/widgets/soft_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    // Scope local: cierra la sesión del dispositivo sin depender de la red.
    await supabase.auth.signOut(scope: SignOutScope.local);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionLabel('Gestión de cuenta y perfil'),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Administrar perfil',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                const _SettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Administrar cuenta de DIME',
                ),
                const Divider(indent: 16, endIndent: 16),
                const _SettingsTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Administrar cuenta bancaria',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SectionLabel('Funciones y preferencias'),
          const SoftCard(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Generar informe financiero',
                ),
                Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accesibilidad',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
      ),
    );
  }
}

/// Si [onTap] es null, la fila queda deshabilitada.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: onTap == null ? const Text('Próximamente') : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
