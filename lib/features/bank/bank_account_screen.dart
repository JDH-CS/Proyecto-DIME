import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_logo.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/cuenta_financiera.dart';
import '../../data/services/bank_api.dart';
import '../../state/app_state.dart';
import 'bank_flow.dart';
import 'bank_picker_screen.dart';

/// "Administrar cuenta bancaria" (Configuración).
class BankAccountScreen extends StatelessWidget {
  const BankAccountScreen({super.key});

  Future<void> _desvincular(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Desvincular banco?'),
        content: const Text(
          'DIME dejará de importar tus movimientos. Las transacciones que ya importaste se conservan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await state.desvincularBanco();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Banco desvinculado')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensajeBanco(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = Theme.of(context).textTheme;
    final c = s.conexion;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta bancaria')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (c == null || !s.bancoVinculado)
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.account_balance_rounded, size: 40, color: Colors.black38),
                    const SizedBox(height: 12),
                    Text(
                      c == null
                          ? 'Aún no has vinculado tu banco'
                          : 'Tu conexión con ${c.nombreInstitucion} fue revocada',
                      textAlign: TextAlign.center,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vincula tu banco para importar tus cuentas y movimientos automáticamente.',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BankPickerScreen()),
                      ),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Vincular banco'),
                    ),
                  ],
                ),
              )
            else ...[
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BankLogo(logoKey: c.logoKey, nombre: c.nombreInstitucion, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nombreInstitucion,
                                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              const Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(Icons.check_circle_rounded, size: 16),
                                label: Text('Conectada'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.ultimaSincronizacion == null
                          ? 'Aún no se ha sincronizado'
                          : 'Última sincronización: ${DateFormat('dd/MM/yyyy HH:mm').format(c.ultimaSincronizacion!)}',
                      style: t.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
                child: Text('Tus cuentas',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (final cuenta in s.cuentas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CuentaCard(cuenta: cuenta),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: s.sincronizando ? null : () => sincronizarYRevisar(context),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sincronizar ahora'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _desvincular(context),
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Desvincular banco'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CuentaCard extends StatelessWidget {
  const _CuentaCard({required this.cuenta});

  final CuentaFinanciera cuenta;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SoftCard(
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
            child: Icon(
              cuenta.esTarjeta ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cuenta.nombre, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(cuenta.tipoLabel, style: t.bodySmall?.copyWith(color: Colors.black54)),
                const SizedBox(height: 6),
                if (cuenta.esTarjeta) ...[
                  Text('Saldo adeudado: ${Fmt.moneda(cuenta.saldoActual)}', style: t.bodySmall),
                  Text(
                    'Disponible: ${Fmt.moneda(cuenta.montoDisponible ?? 0)}'
                    '${cuenta.limiteCredito != null ? ' de ${Fmt.moneda(cuenta.limiteCredito!)}' : ''}',
                    style: t.bodySmall,
                  ),
                ] else
                  Text('Saldo: ${Fmt.moneda(cuenta.saldoActual)}', style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
