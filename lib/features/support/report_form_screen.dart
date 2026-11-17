import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';

/// Formulario para enviar un reporte, consulta o sugerencia al equipo.
/// Devuelve `true` al cerrarse si el reporte se envió.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.tipoInicial = 'error', this.asuntoInicial = ''});

  final String tipoInicial;
  final String asuntoInicial;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _asuntoCtrl = TextEditingController(text: widget.asuntoInicial);
  final _descCtrl = TextEditingController();
  late final TextEditingController _correoCtrl =
      TextEditingController(text: supabase.auth.currentUser?.email ?? '');
  late String _tipo = widget.tipoInicial;
  bool _enviando = false;

  static const _tipos = [
    ('error', 'Error', Icons.bug_report_outlined),
    ('consulta', 'Consulta', Icons.help_outline_rounded),
    ('sugerencia', 'Sugerencia', Icons.lightbulb_outline_rounded),
  ];

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _descCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final correo = _correoCtrl.text.trim();

    try {
      await CuentaService(state).enviarReporte(
        tipo: _tipo,
        asunto: _asuntoCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        correo: correo,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 36),
          title: const Text('¡Reporte enviado!'),
          content: Text('Nuestro equipo lo revisará y te responderá por correo a $correo.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
        ),
      );
      navigator.pop(true);
    } catch (_) {
      if (mounted) showSoon(context, 'No se pudo enviar el reporte. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Enviar un reporte')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¿Qué tipo de reporte es?',
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (valor, etiqueta, icono) in _tipos)
                      ChoiceChip(
                        avatar: Icon(icono, size: 18),
                        label: Text(etiqueta),
                        selected: _tipo == valor,
                        onSelected: (_) => setState(() => _tipo = valor),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _asuntoCtrl,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Asunto', counterText: ''),
                  validator: (v) => Validators.requerido(v, 'El asunto'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos qué pasó',
                    alignLabelWithHint: true,
                    hintText: 'Describe el problema o tu solicitud con el mayor detalle posible.',
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Escribe una descripción';
                    if (s.length < 10) return 'Cuéntanos un poco más (mínimo 10 caracteres)';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo de contacto',
                    helperText: 'Te responderemos a este correo',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Text('Enviar reporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
