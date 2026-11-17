import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/utils/category_color.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/widgets/dime_logo.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/categoria.dart';
import '../../state/app_state.dart';
import '../bank/bank_flow.dart';
import '../categories/quick_assign_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/review_transactions_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pendientes = s.transaccionesPendientes;

    final porAsignar = s.dineroParaAsignar;
    final mensaje = porAsignar > 0
        ? 'Aún no has asignado este dinero a ninguna categoría.'
        : porAsignar == 0
            ? 'Todo tu dinero tiene un destino. ¡Buen trabajo!'
            : 'Asignaste más de lo que has recibido este mes.';

    final asignado = s.totalAsignado;
    final gastado = s.totalGastado;
    final maxV = math.max(asignado, gastado);
    final denom = maxV <= 0 ? 1.0 : maxV;
    final pctGastado = asignado <= 0 ? 0.0 : gastado / asignado;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [DimeLogo(size: 32), SizedBox(width: 10), Text('DIME')],
        ),
        actions: [
          Text('¡Hola, ${s.perfil.nombre}!',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: ProfileAvatar(perfil: s.perfil, radius: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1) Dinero para asignar
          SoftCard(
            color: cs.primary,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 20, color: cs.onPrimary.withValues(alpha: 0.75)),
                    const SizedBox(width: 8),
                    Text('Dinero para asignar',
                        style: t.titleSmall?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Fmt.moneda(porAsignar),
                  style: t.displaySmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(mensaje,
                    style: t.bodySmall?.copyWith(color: cs.onPrimary.withValues(alpha: 0.7))),
                if (porAsignar > 0.004) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.onPrimary,
                        foregroundColor: cs.primary,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuickAssignScreen()),
                      ),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Asignar'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Aviso de transacciones sin categoría
          if (pendientes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pendientes.length == 1
                          ? '1 transacción sin categoría'
                          : '${pendientes.length} transacciones sin categoría',
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => revisarTransacciones(context, pendientes),
                    child: const Text('Revisar'),
                  ),
                ],
              ),
            ),
          ],

          // 2) Principales prioridades
          const SectionTitle(
            'Principales prioridades',
            subtitle: 'Tus primeras 4 categorías y lo que te queda disponible',
          ),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < s.prioridades.length; i++) ...[
                  if (i > 0) const Divider(),
                  _PrioridadRow(categoria: s.prioridades[i]),
                ],
                if (s.prioridades.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aún no tienes categorías.'),
                  ),
              ],
            ),
          ),

          // 3) Flujo mensual
          SectionTitle('Flujo mensual', subtitle: Fmt.mesLargo(DateTime.now())),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FlowBar(
                  label: 'Total asignado',
                  value: asignado,
                  fraction: asignado / denom,
                  color: cs.primary,
                ),
                const SizedBox(height: 18),
                _FlowBar(
                  label: 'Total gastado',
                  value: gastado,
                  fraction: gastado / denom,
                  color: Colors.black45,
                ),
                const SizedBox(height: 16),
                Text(
                  'Has gastado el ${(pctGastado * 100).toStringAsFixed(0)}% de lo que asignaste.',
                  style: t.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),

          // 4) Actualizar transacciones
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => mostrarOpcionesActualizar(context),
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Actualizar transacciones'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              s.bancoVinculado
                  ? 'Banco vinculado: ${s.conexion!.nombreInstitucion}'
                  : 'Aún no has vinculado tu banco',
              style: t.bodySmall?.copyWith(color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de una categoría prioritaria, con los mismos colores que en Categorías.
class _PrioridadRow extends StatelessWidget {
  const _PrioridadRow({required this.categoria});

  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    final color = CategoryColors.of(categoria);
    final disp = s.disponible(categoria.id);
    final pct = s.porcentajeGastado(categoria.id).clamp(0.0, 1.0).toDouble();
    final excedido = disp < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CategoryIconBox(icono: categoria.icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(categoria.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (excedido) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Accessibility.negative),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: color.withValues(alpha: 0.18),
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.moneda(disp),
                style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: excedido ? Accessibility.negative : null,
                ),
              ),
              Text('disponible', style: t.labelSmall?.copyWith(color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowBar extends StatelessWidget {
  const _FlowBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: t.bodyMedium?.copyWith(color: Colors.black54)),
            const Spacer(),
            Text(Fmt.moneda(value),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0).toDouble(),
          minHeight: 10,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.black12,
          color: color,
        ),
      ],
    );
  }
}
