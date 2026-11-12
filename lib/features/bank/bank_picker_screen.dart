import 'package:flutter/material.dart';

import '../../core/widgets/bank_logo.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/services/bank_api.dart';
import 'bank_authorize_screen.dart';

/// Paso 1 de la vinculación: elegir el banco.
class BankPickerScreen extends StatefulWidget {
  const BankPickerScreen({super.key});

  @override
  State<BankPickerScreen> createState() => _BankPickerScreenState();
}

class _BankPickerScreenState extends State<BankPickerScreen> {
  late Future<List<BankInstitution>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = BankApi().institutions();
  }

  void _reintentar() => setState(() => _futuro = BankApi().institutions());

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular banco')),
      body: SafeArea(
        child: FutureBuilder<List<BankInstitution>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black38),
                      const SizedBox(height: 16),
                      Text(mensajeBanco(snap.error!),
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 20),
                      FilledButton(onPressed: _reintentar, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              );
            }

            final bancos = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  child: Text(
                    'Elige tu banco para importar tus cuentas y movimientos de forma segura.',
                    style: t.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ),
                for (final b in bancos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BankAuthorizeScreen(banco: b)),
                      ),
                      child: Row(
                        children: [
                          BankLogo(logoKey: b.logoKey, nombre: b.name),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(b.name,
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
