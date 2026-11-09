import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/soft_card.dart';
import '../../state/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().perfil;
    final t = Theme.of(context).textTheme;

    final filas = <(IconData, String, String)>[
      (Icons.person_outline_rounded, 'Nombre', p.nombre),
      (Icons.person_outline_rounded, 'Apellido', p.apellido),
      (Icons.badge_outlined, 'Documento de identidad', p.documentoIdentidad),
      (Icons.cake_outlined, 'Fecha de nacimiento', Fmt.fecha(p.fechaNacimiento)),
      (Icons.mail_outline_rounded, 'Correo electrónico', p.correo),
      (Icons.phone_outlined, 'Celular', p.celular),
      (Icons.event_available_outlined, 'Miembro desde', Fmt.fecha(p.fechaCreacion)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ProfileAvatar(perfil: p, radius: 56),
              ),
            ),
            const SizedBox(height: 16),
            Text(p.nombreCompleto,
                textAlign: TextAlign.center,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Center(
              child: Chip(
                avatar: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(p.estado.label),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => showSoon(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Cambiar foto'),
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < filas.length; i++) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Icon(filas[i].$1, size: 20, color: Colors.black54),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(filas[i].$2,
                                    style: t.labelMedium?.copyWith(color: Colors.black54)),
                                const SizedBox(height: 2),
                                Text(filas[i].$3,
                                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
