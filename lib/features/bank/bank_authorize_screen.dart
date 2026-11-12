import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/bank_logo.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/services/bank_api.dart';
import '../../state/app_state.dart';
import 'bank_flow.dart';

/// Paso 2: la "página del banco" simulada (inicio de sesión + consentimiento).
/// Es una simulación: cualquier usuario y contraseña con datos son aceptados.
class BankAuthorizeScreen extends StatefulWidget {
  const BankAuthorizeScreen({super.key, required this.banco});

  final BankInstitution banco;

  @override
  State<BankAuthorizeScreen> createState() => _BankAuthorizeScreenState();
}

class _BankAuthorizeScreenState extends State<BankAuthorizeScreen> {
  final _formKey = GlobalKey<FormState>();
  // Prellenado para agilizar la presentación (la pasarela es simulada).
  final _userCtrl = TextEditingController(text: 'usuario.demo');
  final _passCtrl = TextEditingController(text: 'demo1234');
  bool _obscure = true;
  bool _cargando = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _autorizar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final messenger = messengerKey.currentState;

    try {
      await state.vincularBanco(codigo: widget.banco.code, nombre: widget.banco.name);
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        showSoon(context, mensajeBanco(e));
      }
      return;
    }

    // Vinculado: importamos de una vez los movimientos y abrimos la revisión.
    if (mounted) await sincronizarYRevisar(context);

    navigator.popUntil((route) => route.isFirst);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${widget.banco.name} vinculado correctamente')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final banco = widget.banco;

    return PopScope(
      canPop: !_cargando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Autorizar acceso')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text('Conexión segura · Open Banking (simulado)',
                      style: t.labelMedium?.copyWith(color: Colors.black45)),
                ],
              ),
              const SizedBox(height: 20),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          BankLogo(logoKey: banco.logoKey, nombre: banco.name, size: 56),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(banco.name,
                                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                Text('Inicia sesión en tu banca en línea',
                                    style: t.bodySmall?.copyWith(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _userCtrl,
                        enabled: !_cargando,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => Validators.requerido(v, 'El usuario'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passCtrl,
                        enabled: !_cargando,
                        obscureText: _obscure,
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
                        validator: (v) => Validators.requerido(v, 'La contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DIME solicita permiso para:',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const _Permiso(Icons.account_balance_wallet_outlined, 'Ver tus cuentas y saldos'),
                    const _Permiso(Icons.receipt_long_outlined, 'Ver tus movimientos'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DIME no podrá hacer pagos ni transferencias. Puedes revocar el acceso cuando quieras.',
                            style: t.bodySmall?.copyWith(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _autorizar,
                child: _cargando
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Text('Autorizar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Permiso extends StatelessWidget {
  const _Permiso(this.icon, this.texto);

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black45),
        ],
      ),
    );
  }
}
