import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/soft_card.dart';
import '../../data/models/reporte_soporte.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';
import '../tour/tour_screen.dart';
import 'report_form_screen.dart';

/// "Ayuda y soporte": preguntas frecuentes, enviar un reporte y ver el estado de los enviados.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<ReporteSoporte>> _reportes;

  static const _faq = [
    (
      '¿Cómo vinculo mi banco?',
      'Ve a Configuración → Administrar cuenta bancaria → Vincular banco, o toca "Actualizar transacciones" en Inicio y elige la opción automática.',
    ),
    (
      '¿Cómo agrego una transacción manualmente?',
      'En Inicio toca "Actualizar transacciones" y elige "Agregar manualmente". Indica si es un gasto o un ingreso, el monto, la categoría y la fecha.',
    ),
    (
      '¿Cómo reordeno mis categorías?',
      'En la pestaña Categorías, arrastra desde el lado izquierdo de la tarjeta o mantén presionada la tarjeta y muévela.',
    ),
    (
      '¿Qué pasa si olvidé mi contraseña?',
      'En la pantalla de inicio toca "¿Olvidaste tu contraseña?". Te enviaremos un código temporal al correo para crear una nueva.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reportes = CuentaService(context.read<AppState>()).misReportes();
  }

  void _recargar() => setState(() {
        _reportes = CuentaService(context.read<AppState>()).misReportes();
      });

  Future<void> _nuevoReporte() async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReportFormScreen()),
    );
    if (enviado == true && mounted) _recargar();
  }

  void _verTour() {
    final perfil = context.read<AppState>().perfil;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TourScreen(userId: perfil.id, repeticion: true),
      ),
    );
  }

  void _detalle(ReporteSoporte r) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.asunto, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                '${r.tipoLabel} · ${DateFormat('dd/MM/yyyy HH:mm').format(r.fechaCreacion)} · ${r.estadoLabel}',
                style: t.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Text(r.descripcion, style: t.bodyMedium),
              const SizedBox(height: 16),
              Text('Respuesta a: ${r.correoContacto}',
                  style: t.bodySmall?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconoEstado(String estado) => switch (estado) {
        'en revision' => Icons.manage_search_rounded,
        'resuelto' => Icons.check_circle_rounded,
        _ => Icons.mark_email_unread_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('¿Tienes un problema o una duda?',
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Envíanos un reporte y te responderemos por correo electrónico.',
                      style: t.bodyMedium?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _nuevoReporte,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Enviar un reporte'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                onTap: _verTour,
                leading: const Icon(Icons.tour_outlined),
                title: const Text('Ver tour de nuevo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Repasa cómo usar DIME paso a paso'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
              child: Text('Preguntas frecuentes',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < _faq.length; i++) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(_faq[i].$1,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_faq[i].$2, style: t.bodyMedium?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
              child: Text('Mis reportes',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            FutureBuilder<List<ReporteSoporte>>(
              future: _reportes,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return SoftCard(
                    child: Column(
                      children: [
                        const Text('No se pudieron cargar tus reportes.'),
                        TextButton(onPressed: _recargar, child: const Text('Reintentar')),
                      ],
                    ),
                  );
                }
                final lista = snap.data!;
                if (lista.isEmpty) {
                  return SoftCard(
                    child: Text('Aún no has enviado ningún reporte.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: Colors.black54)),
                  );
                }
                return SoftCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < lista.length; i++) ...[
                        if (i > 0) const Divider(indent: 16, endIndent: 16),
                        ListTile(
                          onTap: () => _detalle(lista[i]),
                          leading: Icon(_iconoEstado(lista[i].estado)),
                          title: Text(lista[i].asunto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${lista[i].tipoLabel} · ${DateFormat('dd/MM/yyyy').format(lista[i].fechaCreacion)}',
                          ),
                          trailing: Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(lista[i].estadoLabel),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
