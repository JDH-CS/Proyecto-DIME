import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/soft_card.dart';
import '../../data/models/transaccion.dart';
import '../../data/services/bank_api.dart';
import '../../state/app_state.dart';
import '../transactions/manual_transaction_sheet.dart';
import '../transactions/review_transactions_sheet.dart';
import 'bank_picker_screen.dart';

/// Hoja que se abre con "Actualizar transacciones": automático o manual.
Future<void> mostrarOpcionesActualizar(BuildContext context) {
  final s = context.read<AppState>();
  final vinculado = s.bancoVinculado;

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      final t = Theme.of(sheetCtx).textTheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Actualizar transacciones',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('¿Cómo quieres agregar tus movimientos?',
                  style: t.bodyMedium?.copyWith(color: Colors.black54)),
              const SizedBox(height: 16),
              _OpcionTile(
                icon: Icons.sync_rounded,
                titulo: 'Actualizar automáticamente',
                subtitulo: vinculado
                    ? 'Importar los movimientos nuevos de ${s.conexion!.nombreInstitucion}'
                    : 'Vincula tu banco para importar tus movimientos',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (vinculado) {
                    sincronizarYRevisar(context);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BankPickerScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _OpcionTile(
                icon: Icons.edit_note_rounded,
                titulo: 'Agregar manualmente',
                subtitulo: 'Registra tú mismo un gasto o un ingreso',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showManualTransactionSheet(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Consulta al banco, guarda lo nuevo y abre los pop-ups de revisión.
Future<void> sincronizarYRevisar(BuildContext context) async {
  final state = context.read<AppState>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  void aviso(String msg) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ProgresoDialog('Consultando tu banco…'),
  );

  final List<Transaccion> nuevas;
  try {
    nuevas = await state.sincronizarBanco();
  } catch (e) {
    navigator.pop(); // cierra el diálogo de progreso
    aviso(mensajeBanco(e));
    return;
  }
  navigator.pop(); // cierra el diálogo de progreso

  if (nuevas.isEmpty) {
    aviso('Estás al día: no hay transacciones nuevas.');
    return;
  }
  if (!context.mounted) return;
  await revisarTransacciones(context, nuevas);
}

class _OpcionTile extends StatelessWidget {
  const _OpcionTile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitulo, style: t.bodySmall?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ProgresoDialog extends StatelessWidget {
  const _ProgresoDialog(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
  }
}
