import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/biometric_vault.dart';
import '../../core/utils/recovery_guard.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../navigation/main_shell.dart';
import '../../state/app_state.dart';

enum _Paso { correo, codigo, nueva }

/// Recuperar contraseña con un código temporal enviado al correo:
/// 1) correo  2) código de 6 dígitos  3) crear nueva contraseña.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _correoKey = GlobalKey<FormState>();
  final _codigoKey = GlobalKey<FormState>();
  final _nuevaKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl = TextEditingController(text: widget.emailInicial);
  final _codigoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  _Paso _paso = _Paso.correo;
  bool _cargando = false;
  bool _obscure = true;
  int _segundos = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  String get _email => _emailCtrl.text.trim();

  void _iniciarEspera() {
    _timer?.cancel();
    setState(() => _segundos = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _segundos--;
        if (_segundos <= 0) t.cancel();
      });
    });
  }

  // ───────────── Paso 1: enviar código ─────────────
  Future<void> _enviarCodigo() async {
    if (_paso == _Paso.correo && !_correoKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await supabase.auth.resetPasswordForEmail(_email);
      if (!mounted) return;
      setState(() => _paso = _Paso.codigo);
      _iniciarEspera();
      showSoon(context, 'Si el correo está registrado, te enviamos un código.');
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ───────────── Paso 2: verificar código ─────────────
  Future<void> _verificarCodigo() async {
    if (!_codigoKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await RecoveryGuard.marcar();
      await supabase.auth.verifyOTP(
        email: _email,
        token: _codigoCtrl.text.trim(),
        type: OtpType.recovery,
      );
      if (mounted) setState(() => _paso = _Paso.nueva);
    } catch (e) {
      await RecoveryGuard.limpiar();
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ───────────── Paso 3: nueva contraseña ─────────────
  Future<void> _guardarNueva() async {
    if (!_nuevaKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final nueva = _passCtrl.text;

    try {
      await supabase.auth.updateUser(UserAttributes(password: nueva));
      await RecoveryGuard.limpiar();

      // Si la huella estaba activada con este correo, se actualiza la contraseña guardada.
      final cred = await BiometricVault.leer();
      if (cred != null && cred.email.toLowerCase() == _email.toLowerCase()) {
        await BiometricVault.guardar(_email, nueva);
      }

      await state.cargar();
      await cerrarTeclado();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Contraseña actualizada. ¡Bienvenido de nuevo!')));
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _salirSinTerminar() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin cambiar tu contraseña?'),
        content: const Text('Tendrás que pedir un nuevo código para volver a intentarlo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quedarme')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (salir != true) return;
    await supabase.auth.signOut(scope: SignOutScope.local);
    await RecoveryGuard.limpiar();
    if (mounted) Navigator.of(context).pop();
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final (titulo, subtitulo) = switch (_paso) {
      _Paso.correo => ('Recupera tu contraseña', 'Escribe tu correo y te enviaremos un código temporal.'),
      _Paso.codigo => ('Revisa tu correo', 'Ingresa el código de 6 dígitos que enviamos a $_email.'),
      _Paso.nueva => ('Crea tu nueva contraseña', 'Elige una contraseña nueva para entrar a DIME.'),
    };
    final numeroPaso = _paso.index + 1;

    return PopScope(
      canPop: _paso != _Paso.nueva,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _salirSinTerminar();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Paso $numeroPaso de 3',
                        style: t.labelMedium?.copyWith(color: Colors.black45)),
                    const SizedBox(height: 4),
                    Text(titulo, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(subtitulo, style: t.bodyMedium?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 28),
                    ..._contenido(t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(TextTheme t) {
    final cs = Theme.of(context).colorScheme;
    final spinner = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
    );

    switch (_paso) {
      case _Paso.correo:
        return [
          Form(
            key: _correoKey,
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: Validators.email,
              onFieldSubmitted: (_) => _cargando ? null : _enviarCodigo(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _enviarCodigo,
            child: _cargando ? spinner : const Text('Enviar código'),
          ),
        ];

      case _Paso.codigo:
        return [
          Form(
            key: _codigoKey,
            child: TextFormField(
              controller: _codigoCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 8),
              decoration: const InputDecoration(labelText: 'Código', counterText: ''),
              validator: (v) =>
                  (v == null || v.trim().length < 6) ? 'Ingresa el código de 6 dígitos' : null,
              onFieldSubmitted: (_) => _cargando ? null : _verificarCodigo(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _verificarCodigo,
            child: _cargando ? spinner : const Text('Verificar código'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_cargando || _segundos > 0) ? null : _enviarCodigo,
            child: Text(_segundos > 0 ? 'Reenviar código en $_segundos s' : 'Reenviar código'),
          ),
          TextButton(
            onPressed: _cargando
                ? null
                : () {
                    _timer?.cancel();
                    setState(() {
                      _paso = _Paso.correo;
                      _segundos = 0;
                    });
                  },
            child: const Text('Cambiar correo'),
          ),
        ];

      case _Paso.nueva:
        return [
          Form(
            key: _nuevaKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 8 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.passwordRegistro,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass2Ctrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
                  onFieldSubmitted: (_) => _cargando ? null : _guardarNueva(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cargando ? null : _guardarNueva,
            child: _cargando ? spinner : const Text('Guardar y entrar'),
          ),
        ];
    }
  }
}
