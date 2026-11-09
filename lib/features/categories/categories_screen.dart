import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
          Expanded(
            child: cats.isEmpty
                ? const Center(child: Text('Aún no tienes categorías. ¡Añade la primera!'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    buildDefaultDragHandles: false,
                    itemCount: cats.length,
                    onReorderItem: context.read<AppState>().reordenar,
                    proxyDecorator: (child, index, animation) =>
                        Material(type: MaterialType.transparency, child: child),
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
    final cs = Theme.of(context).colorScheme;

    final asignado = s.asignado(categoria.id);
    final gastado = s.gastado(categoria.id);
    final pct = s.porcentajeGastado(categoria.id);
    final excedido = pct > 1;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 14),
      onTap: () => showCategoryFormSheet(context, editar: categoria),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(index: index, child: const DragGrip()),
              CategoryIconBox(icono: categoria.icono),
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
                  Text('gastado', style: t.labelSmall?.copyWith(color: Colors.black45)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: Colors.black12,
                    color: excedido ? AppTheme.negative : cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                if (excedido)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.negative),
                  ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: excedido ? AppTheme.negative : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
