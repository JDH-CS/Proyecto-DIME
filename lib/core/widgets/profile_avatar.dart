import 'package:flutter/material.dart';

import '../../data/models/perfil.dart';

/// Foto de perfil o ícono genérico de usuario si no hay foto.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.perfil, this.radius = 20});

  final Perfil perfil;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.surfaceContainerHighest,
      foregroundImage: perfil.fotoUrl != null ? NetworkImage(perfil.fotoUrl!) : null,
      child: Icon(Icons.person_rounded, size: radius * 1.1, color: cs.onSurfaceVariant),
    );
  }
}
