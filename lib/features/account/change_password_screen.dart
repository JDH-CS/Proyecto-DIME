import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_errors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _cargando = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    try {
      await CuentaService(state).cambiarContrasena(
        actual: _actualCtrl.text,
        nueva: _nuevaCtrl.text,
      );
      navigator.pop();
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
    } catch (e) {
      if (mounted) {
        final msg = mensajeAuth(e);
        showSoon(
          context,
          msg == 'Correo o contraseña incorrectos.' ? 'La contraseña actual es incorrecta.' : msg,
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _actualCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: Validators.passwordLogin,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nuevaCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    helperText: 'Mínimo 8 caracteres',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    final base = Validators.passwordRegistro(v);
                    if (base != null) return base;
                    if (v == _actualCtrl.text) return 'Debe ser distinta a la actual';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (v) => v != _nuevaCtrl.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _cargando ? null : _guardar,
                  child: _cargando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Text('Guardar contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
