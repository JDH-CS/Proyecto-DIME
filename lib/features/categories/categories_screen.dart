import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/utils/category_color.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/categoria.dart';
import '../../state/app_state.dart';
import 'category_sheets.dart';
import 'drag_grip.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cats = s.categorias;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              if (v == 'editar') showEditPickerSheet(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Editar categoría'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(child: _SortDropdown(value: s.orden, onChanged: s.ordenarPor)),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => showAddCategorySheet(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Añadir categoría'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Arrastra desde el lado izquierdo, o mantén presionada una tarjeta, para reordenar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
              ),
            ),
          ),
          Expanded(
            child: cats.isEmpty
                ? const Center(child: Text('Aún no tienes categorías. ¡Añade la primera!'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    buildDefaultDragHandles: false,
                    itemCount: cats.length,
                    onReorderStart: (_) => HapticFeedback.mediumImpact(),
                    onReorderItem: context.read<AppState>().reordenar,
                    proxyDecorator: (child, index, animation) => AnimatedBuilder(
                      animation: animation,
                      child: child,
                      builder: (context, c) {
                        final t = Curves.easeOut.transform(animation.value);
                        return Transform.scale(
                          scale: 1 + 0.03 * t,
                          child: Material(type: MaterialType.transparency, child: c),
                        );
                      },
                    ),
                    itemBuilder: (context, i) => Padding(
                      key: ValueKey(cats[i].id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoriaCard(index: i, categoria: cats[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final CategoriaOrden value;
  final ValueChanged<CategoriaOrden> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CategoriaOrden>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          selectedItemBuilder: (_) => [
            for (final o in CategoriaOrden.values)
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ordenar por:',
                        style: t.labelSmall?.copyWith(color: Colors.black54)),
                    Text(o.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
          items: [
            for (final o in CategoriaOrden.values)
              DropdownMenuItem(value: o, child: Text(o.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({required this.index, required this.categoria});

  final int index;
  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;

    final color = CategoryColors.of(categoria);
    final asignado = s.asignado(categoria.id);
    final gastado = s.gastado(categoria.id);
    final pct = s.porcentajeGastado(categoria.id);
    final excedido = pct > 1;

    return SoftCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Zona de arrastre: ocupa toda la altura de la tarjeta y NO abre la edición.
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  border: const Border(right: BorderSide(color: Colors.black12)),
                ),
                child: const DragGrip(),
              ),
            ),

            // ── Resto de la tarjeta: tocar = editar, mantener presionado = arrastrar.
            Expanded(
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: InkWell(
                  onTap: () => showCategoryFormSheet(context, editar: categoria),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CategoryIconBox(icono: categoria.icono, color: color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(categoria.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  Text('Asignado: ${Fmt.moneda(asignado)}',
                                      style: t.bodySmall?.copyWith(color: Colors.black54)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(Fmt.moneda(gastado),
                                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                Text('gastado',
                                    style: t.labelSmall?.copyWith(color: Colors.black45)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: pct.clamp(0.0, 1.0).toDouble(),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor: color.withValues(alpha: 0.18),
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (excedido)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.warning_amber_rounded,
                                    size: 16, color: Accessibility.negative),
                              ),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: t.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: excedido ? Accessibility.negative : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
