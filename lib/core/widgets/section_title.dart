import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Text(subtitle!, style: t.bodySmall?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}
