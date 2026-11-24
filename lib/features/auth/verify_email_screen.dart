import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/biometric_vault.dart';
import '../../core/utils/ui_helpers.dart';
import '../../navigation/main_shell.dart';
import '../../state/app_state.dart';

/// Confirma el correo de una cuenta nueva con el código de 6 dígitos
/// que Supabase envía al registrarse. Al confirmarlo, entra directo a la app.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.password,
    this.reenviarAlAbrir = false,
  });

  final String email;

  /// Si se conoce (registro o login), se guarda para la huella al confirmar.
  final String? password;

  /// true cuando se llega desde el login: se pide un código nuevo al abrir.
  final bool reenviarAlAbrir;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();

  bool _cargando = false;
  int _segundos = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.reenviarAlAbrir) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reenviar());
    } else {
      _iniciarEspera(); // el código del registro acaba de enviarse
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _reenviar() async {
    setState(() => _cargando = true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: widget.email);
      if (!mounted) return;
      _iniciarEspera();
      showSoon(context, 'Te enviamos un código nuevo.');
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);

    try {
      // Confirma el correo y abre la sesión en un solo paso.
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: _codigoCtrl.text.trim(),
        type: OtpType.signup,
      );
      await state.cargar();
      final password = widget.password;
      if (password != null) await BiometricVault.guardar(widget.email, password);

      // Sin SnackBar aquí: el usuario nuevo ve de inmediato el tour de bienvenida.
      await cerrarTeclado();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final spinner = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
    );

    return Scaffold(
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
                  Icon(Icons.mark_email_unread_outlined, size: 56, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Confirma tu correo',
                      style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Ingresa el código de 6 dígitos que enviamos a ${widget.email}. '
                    'Si no lo ves, revisa la carpeta de spam.',
                    style: t.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
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
                      onFieldSubmitted: (_) => _cargando ? null : _verificar(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _cargando ? null : _verificar,
                    child: _cargando ? spinner : const Text('Confirmar y entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: (_cargando || _segundos > 0) ? null : _reenviar,
                    child: Text(_segundos > 0 ? 'Reenviar código en $_segundos s' : 'Reenviar código'),
                  ),
                  TextButton(
                    onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
