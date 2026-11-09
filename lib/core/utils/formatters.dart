import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formato de dinero y fechas.
class Fmt {
  Fmt._();

  static final NumberFormat _money =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

  static String moneda(double v) => _money.format(v);

  /// "+$800.00", "-$150.00" o "$0.00".
  static String monedaConSigno(double v) {
    if (v == 0) return _money.format(0);
    return '${v > 0 ? '+' : '-'}${_money.format(v.abs())}';
  }

  static String mesCorto(DateTime d) {
    final s = DateFormat('MMM', 'es').format(d).replaceAll('.', '');
    return s[0].toUpperCase() + s.substring(1);
  }

  static String mesLargo(DateTime d) {
    final s = DateFormat('MMMM yyyy', 'es').format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  static String fecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
}

/// Convierte a mayúsculas mientras se escribe (cédula / pasaporte).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Celular panameño: 6123-4567 (se escribe solo el guion).
class PanamaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final text =
        digits.length > 4 ? '${digits.substring(0, 4)}-${digits.substring(4)}' : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
