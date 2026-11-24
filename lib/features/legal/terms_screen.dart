import 'package:flutter/material.dart';

import 'terms_text.dart';

/// Muestra los Términos y Condiciones. Con [mostrarAceptar] (desde el registro)
/// agrega el botón "He leído y acepto", que devuelve `true` al cerrar.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key, this.mostrarAceptar = false});

  final bool mostrarAceptar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Términos y condiciones')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text('Términos y Condiciones y Política de Privacidad de DIME',
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Versión ${TermsText.version} · Vigente desde el ${TermsText.vigencia}',
                      style: t.bodySmall?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: cs.onPrimaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            TermsText.aviso,
                            style: t.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final (titulo, parrafos) in TermsText.secciones) ...[
                    const SizedBox(height: 20),
                    Text(titulo, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    for (final p in parrafos) _Parrafo(p),
                  ],
                ],
              ),
            ),
            if (mostrarAceptar)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('He leído y acepto'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Parrafo extends StatelessWidget {
  const _Parrafo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45);
    if (!texto.startsWith('• ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: estilo),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: estilo),
          Expanded(child: Text(texto.substring(2), style: estilo)),
        ],
      ),
    );
  }
}
