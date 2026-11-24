import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_errors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';
import '../auth/login_screen.dart';

/// Configuración > Administrar cuenta de DIME > Eliminar mi cuenta.
/// Encuesta de salida (motivo anónimo) + confirmación con contraseña.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _otro = 'Otro';
  static const _motivos = [
    'Ya no necesito llevar un presupuesto',
    'La app es difícil de usar',
    'No tiene las funciones que necesito',
    'Me preocupa la privacidad de mis datos',
    'Prefiero otra app o método',
    'Solo creé la cuenta para probar',
    _otro,
  ];

  final _formKey = GlobalKey<FormState>();
  final _otroCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _motivo;
  bool _mostrarMotivoError = false;
  bool _obscure = true;
  bool _cargando = false;

  @override
  void dispose() {
    _otroCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    setState(() => _mostrarMotivoError = _motivo == null);
    final formOk = _formKey.currentState!.validate();
    if (_motivo == null || !formOk) return;

    final cs = Theme.of(context).colorScheme;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 32),
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se borrarán para siempre tu perfil, categorías, presupuestos, transacciones, '
          'la conexión bancaria y tu foto. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _cargando = true);
    final state = context.read<AppState>();
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await CuentaService(state).eliminarCuenta(
        password: _passCtrl.text,
        motivo: _motivo!,
        comentario: _motivo == _otro ? _otroCtrl.text.trim() : null,
      );
      await cerrarTeclado();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Tu cuenta fue eliminada. Te enviamos un correo de confirmación.'),
        ));
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        final msg = mensajeAuth(e);
        showSoon(
          context,
          msg == 'Correo o contraseña incorrectos.' ? 'La contraseña es incorrecta.' : msg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar mi cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Icon(Icons.sentiment_dissatisfied_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 12),
              Text('Lamentamos que te vayas',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Antes de irte, ¿nos cuentas por qué? Tu respuesta es anónima y nos ayuda a mejorar DIME.',
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // ── Motivo ──
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RadioGroup<String>(
                  groupValue: _motivo,
                  onChanged: (v) {
                    if (_cargando) return;
                    setState(() {
                      _motivo = v;
                      _mostrarMotivoError = false;
                    });
                  },
                  child: Column(
                    children: [
                      for (final m in _motivos)
                        RadioListTile<String>(
                          value: m,
                          title: Text(m),
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ),
              if (_mostrarMotivoError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Text('Elige un motivo',
                      style: t.bodySmall?.copyWith(color: cs.error)),
                ),
              if (_motivo == _otro) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otroCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos tu motivo',
                    hintText: 'Tu opinión nos ayuda a mejorar',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (_motivo == _otro && (v == null || v.trim().isEmpty))
                      ? 'Escribe tu motivo'
                      : null,
                ),
              ],
              const SizedBox(height: 20),

              // ── Qué se borra ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: cs.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se borrarán de forma permanente tu perfil, categorías, presupuestos, '
                        'transacciones, la conexión bancaria y tu foto. Si quieres conservar tu '
                        'información, genera antes tu informe financiero en PDF desde Configuración.',
                        style: t.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Confirmación ──
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                enabled: !_cargando,
                decoration: InputDecoration(
                  labelText: 'Confirma tu contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
                onPressed: _cargando ? null : _eliminar,
                child: _cargando
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onError),
                      )
                    : const Text('Eliminar mi cuenta permanentemente'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar, quiero quedarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
