import 'package:flutter/material.dart';

/// Logo del banco desde assets/banks/(logoKey).png
/// Si el archivo no existe, muestra las iniciales del banco.
class BankLogo extends StatelessWidget {
  const BankLogo({super.key, required this.logoKey, required this.nombre, this.size = 48});

  final String logoKey;
  final String nombre;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.black12),
      ),
      child: Image.asset(
        'assets/banks/$logoKey.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Center(
          child: Text(
            iniciales,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: size * 0.34,
              color: cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}
