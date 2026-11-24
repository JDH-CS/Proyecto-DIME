import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/auth_errors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/services/dos_pasos_service.dart';
import '../../state/app_state.dart';

/// Configuración > Verificación en dos pasos.
/// Activar o desactivar pide confirmar con un código enviado al correo, para
/// comprobar que el correo funciona y que quien hace el cambio es el dueño.
class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  bool _cargando = false;

  Future<void> _cambiar(bool activar) async {
    final state = context.read<AppState>();
    final perfil = state.perfil;
    final email = perfil.correo;

    setState(() => _cargando = true);
    try {
      await DosPasosService.enviarCodigo(email);
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        showSoon(context, mensajeAuth(e));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _cargando = false);

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CodigoDialog(email: email, activar: activar),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _cargando = true);
    try {
      await DosPasosService.guardar(perfil.id, activar);
      state.reemplazarPerfil(state.perfil.copyWith(dosPasos: activar));
      if (mounted) {
        showSoon(
          context,
          activar
              ? 'Verificación en dos pasos activada'
              : 'Verificación en dos pasos desactivada',
        );
      }
    } catch (e) {
      if (mounted) showSoon(context, 'No se pudo guardar el cambio. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AppState>().perfil;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final activo = perfil.dosPasos;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificación en dos pasos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SwitchListTile(
              secondary: Icon(activo ? Icons.verified_user_rounded : Icons.shield_outlined),
              title: const Text('Código por correo al iniciar sesión',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(activo ? 'Activada' : 'Desactivada'),
              value: activo,
              onChanged: _cargando ? null : _cambiar,
            ),
          ),
          if (_cargando) const LinearProgressIndicator(),
          const SizedBox(height: 20),
          Text('¿Cómo funciona?', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Cada vez que inicies sesión, además de tu contraseña (o tu huella) te pediremos '
            'un código de 6 dígitos que enviaremos a ${perfil.correo}. Así, aunque alguien '
            'conozca tu contraseña, no podrá entrar sin acceso a tu correo.',
            style: t.bodyMedium?.copyWith(color: Colors.black54, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para activarla o desactivarla te enviaremos un código de confirmación.',
                  style: t.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodigoDialog extends StatefulWidget {
  const _CodigoDialog({required this.email, required this.activar});

  final String email;
  final bool activar;

  @override
  State<_CodigoDialog> createState() => _CodigoDialogState();
}

class _CodigoDialogState extends State<_CodigoDialog> {
  final _ctrl = TextEditingController();
  bool _verificando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_ctrl.text.trim().length < 6) {
      setState(() => _error = 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() {
      _verificando = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await DosPasosService.verificarCodigo(widget.email, _ctrl.text);
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificando = false;
          _error = mensajeAuth(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.activar ? 'Activar verificación' : 'Desactivar verificación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingresa el código que enviamos a ${widget.email}.'),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 6),
            decoration: InputDecoration(labelText: 'Código', errorText: _error),
            onSubmitted: (_) => _verificando ? null : _verificar(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verificando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _verificando ? null : _verificar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
