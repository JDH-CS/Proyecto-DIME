import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/biometric_vault.dart';
import '../../core/utils/recovery_guard.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/dime_logo.dart';
import '../../data/services/dos_pasos_service.dart';
import '../../navigation/main_shell.dart';
import '../../state/app_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'two_factor_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _obscure = true;
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Inicia sesión en Supabase, descarga los datos y entra a la app.
  Future<void> _entrar(String email, String password, {bool guardarParaHuella = false}) async {
    setState(() => _cargando = true);
    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    try 
    {
      // Marca de "acceso a medias": si la app se cierra antes de terminar (por ejemplo,
      // entre la contraseña y el código de dos pasos), AuthGate cierra esa sesión al reabrir.
      await RecoveryGuard.marcar();
      final res = await supabase.auth.signInWithPassword(email: email, password: password);

      // Verificación en dos pasos: la contraseña fue correcta, pero falta el código del correo.
      // Se cierra la sesión del paso 1 y solo se abre de nuevo al verificar el código.
      if (await DosPasosService.activo(res.user!.id)) {
        await supabase.auth.signOut(scope: SignOutScope.local);
        await RecoveryGuard.limpiar();
        await DosPasosService.enviarCodigo(email);
        navigator.push(MaterialPageRoute(
          builder: (_) => TwoFactorScreen(
            email: email,
            passwordParaHuella: guardarParaHuella ? password : null,
          ),
        ));
        return;
      }

      await state.cargar();
      await RecoveryGuard.limpiar();
      if (guardarParaHuella) await BiometricVault.guardar(email, password);
      await cerrarTeclado();
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } 
    catch (e) 
    {
      await supabase.auth.signOut(scope: SignOutScope.local);
      await RecoveryGuard.limpiar();
      if (e is AuthException && e.message.toLowerCase().contains('email not confirmed')) 
      {
        navigator.push(MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: email,
            password: password,
            reenviarAlAbrir: true,
            ),
        ));
        return;
      }
      if (mounted) showSoon(context, mensajeAuth(e));
    } 
    finally 
    {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _iniciarSesion() {
    if (!_formKey.currentState!.validate()) return;
    _entrar(_emailCtrl.text.trim(), _passCtrl.text, guardarParaHuella: true);
  }

  Future<void> _loginConHuella() async {
    if (_cargando) return;
    final cred = await BiometricVault.leer();
    if (!mounted) return;
    if (cred == null) {
      showSoon(context, 'Inicia sesión con tu correo una vez para activar la huella.');
      return;
    }
    try {
      final soportado = await _localAuth.isDeviceSupported();
      final biometrias = await _localAuth.getAvailableBiometrics();
      if (!mounted) return;
      if (!soportado || biometrias.isEmpty) {
        showSoon(context, 'Este dispositivo no tiene huella o rostro configurado.');
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Verifica tu identidad para entrar a DIME',
        biometricOnly: true,
      );
      if (ok && mounted) await _entrar(cred.email, cred.password);
    } catch (_) {
      if (mounted) showSoon(context, 'No se pudo verificar tu identidad. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

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
                      onFieldSubmitted: (_) => _cargando ? null : _iniciarSesion(),
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
                        onPressed: _cargando
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(emailInicial: _emailCtrl.text.trim()),
                                )),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      child: _cargando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('Iniciar sesión'),
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
                      onPressed: _cargando ? null : _loginConHuella,
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
                          onPressed: _cargando
                              ? null
                              : () => Navigator.of(context).push(
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
