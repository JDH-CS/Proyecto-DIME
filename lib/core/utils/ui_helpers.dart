import 'package:flutter/material.dart';

void showSoon(BuildContext context, [String msg = 'Disponible próximamente']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
