import 'package:flutter/material.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bank_logo.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/widgets/dime_logo.dart';
import '../../core/widgets/soft_card.dart';
import 'tour_prefs.dart';

class _Paso {
  const _Paso({
    required this.titulo,
    required this.texto,
    required this.ilustracion,
    this.pasos = const [],
  });

  final String titulo;
  final String texto;
  final Widget Function(BuildContext) ilustracion;
  final List<String> pasos;
}

/// Tour guiado para usuarios nuevos. Se muestra una vez por usuario y se puede
/// repetir desde Configuración → Ayuda y soporte.
class TourScreen extends StatefulWidget {
  const TourScreen({super.key, required this.userId, this.repeticion = false});

  final String userId;
  final bool repeticion;

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _controller = PageController();
  int _pagina = 0;

  static final List<_Paso> _pasos = [
    _Paso(
      titulo: '¡Bienvenido a DIME!',
      texto:
          'En un minuto te mostramos cómo tomar el control de tu dinero: darle un propósito a cada dólar y ver hacia dónde va.',
      ilustracion: (_) => const DimeLogo(size: 110),
    ),
    _Paso(
      titulo: 'Dinero para asignar',
      texto:
          'En la pantalla de Inicio, la tarjeta superior muestra el dinero que entró este mes y todavía no tiene destino. Tu meta es llevarlo a \$0 asignándolo a categorías.',
      ilustracion: (_) => const _IlusDinero(),
    ),
    _Paso(
      titulo: 'Crea tus categorías',
      texto: 'Las categorías son los "sobres" de tu dinero: comida, transporte, salud...',
      pasos: [
        'Ve a la pestaña Categorías.',
        'Toca "Añadir categoría" y elige una predeterminada o crea la tuya.',
        'Toca una tarjeta para editar su nombre, ícono o presupuesto.',
      ],
      ilustracion: (_) => const _IlusCategorias(),
    ),
    _Paso(
      titulo: 'Muévelas a tu manera',
      texto:
          'Arrastra una categoría desde la zona izquierda de la tarjeta, o mantenla presionada y muévela. Las 4 primeras son tus Principales prioridades en Inicio.',
      ilustracion: (_) => const _IlusArrastre(),
    ),
    _Paso(
      titulo: 'Asigna tu dinero',
      texto:
          'Toca "Asignar" en la tarjeta de Dinero para asignar. Elige categorías una por una y dile a DIME cuánto darle a cada una, hasta llegar a \$0.',
      ilustracion: (_) => const _IlusAsignar(),
    ),
    _Paso(
      titulo: 'Conecta tu banco',
      texto: 'DIME puede traer tus cuentas y movimientos automáticamente.',
      pasos: [
        'Ve a Configuración → Administrar cuenta bancaria (o toca "Actualizar transacciones" en Inicio).',
        'Elige tu banco y autoriza el acceso.',
        'Listo: DIME importa tus cuentas y tus movimientos.',
      ],
      ilustracion: (_) => const _IlusBanco(),
    ),
    _Paso(
      titulo: 'Actualiza y clasifica',
      texto:
          'Toca "Actualizar transacciones" → Automáticamente. Por cada movimiento nuevo, DIME te sugiere una categoría: acepta o elige otra. Si no reconoce el comercio, te pregunta y puede recordar tu elección.',
      ilustracion: (_) => const _IlusRevision(),
    ),
    _Paso(
      titulo: 'Agrega movimientos a mano',
      texto:
          'En "Actualizar transacciones" elige "Agregar manualmente" para registrar un gasto o un ingreso: monto, descripción, categoría y fecha.',
      ilustracion: (_) => const _IlusManual(),
    ),
    _Paso(
      titulo: 'Mira tu progreso',
      texto:
          'El Dashboard muestra tus gastos por categoría, tu patrimonio neto y tus ingresos contra gastos. En Configuración puedes generar un informe en PDF.',
      ilustracion: (_) => const _IlusDashboard(),
    ),
    _Paso(
      titulo: '¿Necesitas ayuda?',
      texto:
          'En Configuración encuentras Ayuda y soporte (preguntas frecuentes, reportes y este tour), Accesibilidad con modos de color para daltonismo y tu perfil.',
      ilustracion: (_) => const _IlusAyuda(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    await TourPrefs.marcarCompletado(widget.userId);
    if (mounted) Navigator.of(context).pop();
  }

  void _ir(int p) => _controller.animateToPage(
        p,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ultima = _pagina == _pasos.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _terminar();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Text('${_pagina + 1} de ${_pasos.length}',
                        style: t.labelLarge?.copyWith(color: Colors.black45)),
                    const Spacer(),
                    if (!ultima)
                      TextButton(onPressed: _terminar, child: const Text('Omitir')),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pasos.length,
                  onPageChanged: (i) => setState(() => _pagina = i),
                  itemBuilder: (context, i) {
                    final p = _pasos[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 190,
                            child: Center(child: p.ilustracion(context)),
                          ),
                          const SizedBox(height: 24),
                          Text(p.titulo,
                              textAlign: TextAlign.center,
                              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text(p.texto,
                              textAlign: TextAlign.center,
                              style: t.bodyLarge?.copyWith(color: Colors.black54, height: 1.4)),
                          if (p.pasos.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            for (var n = 0; n < p.pasos.length; n++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: cs.primary,
                                      child: Text('${n + 1}',
                                          style: TextStyle(
                                              color: cs.onPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(p.pasos[n], style: t.bodyMedium)),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Indicador + botones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pasos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _pagina ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _pagina ? cs.primary : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  children: [
                    if (_pagina > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _ir(_pagina - 1),
                          child: const Text('Atrás'),
                        ),
                      ),
                    if (_pagina > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: ultima ? _terminar : () => _ir(_pagina + 1),
                        child: Text(ultima ? (widget.repeticion ? 'Cerrar' : '¡Empezar!') : 'Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Ilustraciones ─────────────────────────
Color _color(int i) => Accessibility.categoria(AppTheme.chartShades[i % AppTheme.chartShades.length]);

class _IlusDinero extends StatelessWidget {
  const _IlusDinero();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      color: cs.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dinero para asignar',
              style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 6),
          Text('\$690.00',
              style: TextStyle(color: cs.onPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: cs.onPrimary, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Text('Asignar',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IlusCategorias extends StatelessWidget {
  const _IlusCategorias();

  @override
  Widget build(BuildContext context) {
    const items = [('Comida', 'restaurant'), ('Transporte', 'car'), ('Salud', 'health')];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 14,
          children: [
            for (var i = 0; i < items.length; i++)
              Column(
                children: [
                  CategoryIconBox(icono: items[i].$2, size: 56, color: _color(i)),
                  const SizedBox(height: 6),
                  Text(items[i].$1, style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 6),
              Text('Añadir categoría',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _IlusArrastre extends StatelessWidget {
  const _IlusArrastre();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 280,
        height: 78,
        child: Row(
          children: [
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                border: const Border(right: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drag_indicator_rounded, color: cs.primary),
                  Icon(Icons.swap_vert_rounded, size: 18, color: cs.primary),
                ],
              ),
            ),
            const SizedBox(width: 14),
            CategoryIconBox(icono: 'restaurant', size: 44, color: _color(1)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Alimentación', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IlusAsignar extends StatelessWidget {
  const _IlusAsignar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        );
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIconBox(icono: 'car', size: 38, color: _color(2)),
              const SizedBox(width: 10),
              const Text('Transporte', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [chip('+\$10'), chip('+\$50'), chip('+\$100')]),
          const SizedBox(height: 10),
          Text('Te quedan \$640.00',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _IlusBanco extends StatelessWidget {
  const _IlusBanco();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        BankLogo(logoKey: 'bgen', nombre: 'Banco General', size: 64),
        SizedBox(width: 12),
        Icon(Icons.link_rounded, size: 28),
        SizedBox(width: 12),
        BankLogo(logoKey: 'bac', nombre: 'BAC Credomatic', size: 64),
      ],
    );
  }
}

class _IlusRevision extends StatelessWidget {
  const _IlusRevision();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 270,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(child: Text('Amazon', style: TextStyle(fontWeight: FontWeight.w800))),
                Text('-\$45.99', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Se asignará a la categoría Compras. ¿Aceptar?',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: cs.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('Aceptar',
                        style: TextStyle(
                            color: cs.onPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Elegir otra',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IlusManual extends StatelessWidget {
  const _IlusManual();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: cs.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('Gasto',
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Ingreso', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('\$ 12.50', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IlusDashboard extends StatelessWidget {
  const _IlusDashboard();

  @override
  Widget build(BuildContext context) {
    final alturas = [0.45, 0.7, 0.55, 0.9, 0.65, 0.8];
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        width: 240,
        height: 110,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < alturas.length; i++)
              Container(
                width: 28,
                height: 110 * alturas[i],
                decoration: BoxDecoration(
                  color: _color(i),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IlusAyuda extends StatelessWidget {
  const _IlusAyuda();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget item(IconData i, String t) => Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(i, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text(t, style: const TextStyle(fontSize: 12)),
          ],
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(Icons.support_agent_rounded, 'Soporte'),
        const SizedBox(width: 16),
        item(Icons.picture_as_pdf_rounded, 'Informe'),
        const SizedBox(width: 16),
        item(Icons.accessibility_new_rounded, 'Accesibilidad'),
      ],
    );
  }
}
