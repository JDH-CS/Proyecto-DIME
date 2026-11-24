import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/app_state.dart';
import '../accessibility/accessibility_screen.dart';
import '../account/account_screen.dart';
import '../auth/login_screen.dart';
import '../bank/bank_account_screen.dart';
import '../legal/terms_screen.dart';
import '../profile/profile_screen.dart';
import '../report/report_sheet.dart';
import '../support/support_screen.dart';
import 'two_factor_settings_screen.dart';

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

  void _abrir(BuildContext context, Widget pantalla) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final dosPasos = context.watch<AppState>().perfil.dosPasos;

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
                  onTap: () => _abrir(context, const ProfileScreen()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Administrar cuenta de DIME',
                  onTap: () => _abrir(context, const AccountScreen()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Administrar cuenta bancaria',
                  onTap: () => _abrir(context, const BankAccountScreen()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verificación en dos pasos',
                  subtitle: dosPasos ? 'Activada' : 'Desactivada',
                  onTap: () => _abrir(context, const TwoFactorSettingsScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SectionLabel('Funciones y preferencias'),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Generar informe financiero',
                  onTap: () => mostrarInformeSheet(context),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Accesibilidad',
                  onTap: () => _abrir(context, const AccessibilityScreen()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Ayuda y soporte',
                  onTap: () => _abrir(context, const SupportScreen()),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SettingsTile(
                  icon: Icons.gavel_rounded,
                  title: 'Términos y condiciones',
                  onTap: () => _abrir(context, const TermsScreen()),
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
  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: onTap == null
          ? const Text('Próximamente')
          : (subtitle == null ? null : Text(subtitle!)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
