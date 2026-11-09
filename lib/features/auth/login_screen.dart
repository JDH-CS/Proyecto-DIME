import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dime_logo.dart';
import '../../navigation/main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Prellenado para agilizar la demo. Quítalo si prefieres campos vacíos.
  final _emailCtrl = TextEditingController(text: 'peter.parker@gmail.com');
  final _passCtrl = TextEditingController(text: '12345678');
  bool _obscure = true;

  final _localAuth = LocalAuthentication();
  bool _autenticando = false;   

  Future<void> _loginConHuella() async {
    if (_autenticando) return;
    setState(() => _autenticando = true);
    try {
      final soportado = await _localAuth.isDeviceSupported();
      final biometrias = await _localAuth.getAvailableBiometrics();

      if (!soportado || biometrias.isEmpty) {
        if (mounted) {
          showSoon(context, 'Este dispositivo no tiene huella o rostro configurado.');
        }
        return;
      }

      final ok = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad para entrar a DIME',
        biometricOnly: true,
      );
      if (ok && mounted) _irAHome();
    } catch (_) {
      if (mounted) {
        showSoon(context, 'No se pudo verificar tu identidad. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _autenticando = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _irAHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _iniciarSesion() {
    // Mock: cualquier correo/contraseña con formato válido entra.
    if (_formKey.currentState!.validate()) _irAHome();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: DimeLogo(size: 84)),
                    const SizedBox(height: 16),
                    Text(
                      'DIME',
                      textAlign: TextAlign.center,
                      style: t.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '¡Bienvenido a DIME!',
                      textAlign: TextAlign.center,
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toma el control y asigna cada dólar con confianza',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _iniciarSesion(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.passwordLogin,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showSoon(context),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _iniciarSesion,
                      child: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o', style: t.bodySmall?.copyWith(color: Colors.black45)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _autenticando ? null : _loginConHuella,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Usar huella dactilar'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿No tienes una cuenta?', style: t.bodyMedium),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
