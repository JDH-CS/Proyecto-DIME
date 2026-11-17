import 'package:flutter/material.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/soft_card.dart';

/// Configuración → Accesibilidad: modo de color para daltonismo.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Accesibilidad')),
      body: SafeArea(
        child: ValueListenableBuilder<ColorMode>(
          valueListenable: Accessibility.modo,
          builder: (context, actual, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text('Modo de color',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  'Elige el tipo de daltonismo para adaptar los colores de toda la app: botones, tarjetas, fondo, textos, categorías y gráficas. El cambio se aplica al instante y se guarda en este dispositivo.',
                  style: t.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ),
              for (final modo in ColorMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OpcionModo(
                    modo: modo,
                    seleccionado: modo == actual,
                    onTap: () => Accessibility.establecer(modo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionModo extends StatelessWidget {
  const _OpcionModo({required this.modo, required this.seleccionado, required this.onTap});

  final ColorMode modo;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final paleta = Accessibility.paleta(modo);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: seleccionado ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(modo.titulo,
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Icon(
                  seleccionado ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: seleccionado ? cs.primary : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(modo.descripcion, style: t.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 12),
            // Vista previa de la paleta
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in paleta)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Vista previa de ingresos / gastos
            Row(
              children: [
                _Muestra(color: AppTheme.tonos(modo).t700, texto: 'App'),
                const SizedBox(width: 16),
                _Muestra(color: Accessibility.positivoDe(modo), texto: 'Ingresos'),
                const SizedBox(width: 16),
                _Muestra(color: Accessibility.negativoDe(modo), texto: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
