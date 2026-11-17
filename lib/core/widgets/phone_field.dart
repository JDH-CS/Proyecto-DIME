import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/formatters.dart';
import '../utils/validators.dart';

/// País con su código telefónico y la cantidad de dígitos del número local.
class PaisTelefono {
  const PaisTelefono(this.iso, this.nombre, this.codigo, this.min, this.max, this.ejemplo);

  final String iso;
  final String nombre;
  final String codigo; // "+507"
  final int min;
  final int max;
  final String ejemplo;

  /// Bandera en emoji a partir del código ISO (PA → 🇵🇦).
  String get bandera => String.fromCharCodes(iso.codeUnits.map((c) => c + 127397));

  bool get esPanama => iso == 'PA';
}

/// Lista de países y utilidades para guardar el teléfono como "+código número".
class PaisesTelefono {
  PaisesTelefono._();

  static const panama = PaisTelefono('PA', 'Panamá', '+507', 8, 8, '6123-4567');

  static const List<PaisTelefono> lista = [
    panama,
    PaisTelefono('US', 'Estados Unidos / Canadá', '+1', 10, 10, '2025550123'),
    PaisTelefono('CO', 'Colombia', '+57', 10, 10, '3001234567'),
    PaisTelefono('CR', 'Costa Rica', '+506', 8, 8, '83123456'),
    PaisTelefono('MX', 'México', '+52', 10, 10, '5512345678'),
    PaisTelefono('ES', 'España', '+34', 9, 9, '612345678'),
    PaisTelefono('VE', 'Venezuela', '+58', 10, 10, '4121234567'),
    PaisTelefono('EC', 'Ecuador', '+593', 9, 9, '991234567'),
    PaisTelefono('PE', 'Perú', '+51', 9, 9, '912345678'),
    PaisTelefono('DO', 'República Dominicana', '+1', 10, 10, '8091234567'),
    PaisTelefono('GT', 'Guatemala', '+502', 8, 8, '51234567'),
    PaisTelefono('SV', 'El Salvador', '+503', 8, 8, '70123456'),
    PaisTelefono('HN', 'Honduras', '+504', 8, 8, '91234567'),
    PaisTelefono('NI', 'Nicaragua', '+505', 8, 8, '81234567'),
    PaisTelefono('CU', 'Cuba', '+53', 8, 8, '51234567'),
    PaisTelefono('AR', 'Argentina', '+54', 10, 11, '91123456789'),
    PaisTelefono('CL', 'Chile', '+56', 9, 9, '912345678'),
    PaisTelefono('BR', 'Brasil', '+55', 10, 11, '11912345678'),
    PaisTelefono('UY', 'Uruguay', '+598', 8, 8, '94123456'),
    PaisTelefono('PY', 'Paraguay', '+595', 9, 9, '961456789'),
    PaisTelefono('BO', 'Bolivia', '+591', 8, 8, '71234567'),
    PaisTelefono('GB', 'Reino Unido', '+44', 10, 10, '7400123456'),
    PaisTelefono('FR', 'Francia', '+33', 9, 9, '612345678'),
    PaisTelefono('DE', 'Alemania', '+49', 10, 11, '15123456789'),
    PaisTelefono('IT', 'Italia', '+39', 9, 10, '3123456789'),
    PaisTelefono('PT', 'Portugal', '+351', 9, 9, '912345678'),
    PaisTelefono('CN', 'China', '+86', 11, 11, '13123456789'),
    PaisTelefono('IN', 'India', '+91', 10, 10, '9123456789'),
  ];

  /// Texto que se guarda en la BD: "+507 6123-4567", "+57 3001234567".
  static String unir(PaisTelefono pais, String numero) => '${pais.codigo} ${numero.trim()}';

  /// Separa un teléfono guardado en país y número. Si no reconoce el código,
  /// devuelve Panamá y el texto sin el "+".
  static (PaisTelefono, String) separar(String telefono) {
    final t = telefono.trim();
    if (!t.startsWith('+')) return (panama, t == '—' ? '' : t);
    // Gana el código más largo que coincida; en empate, el primero de la lista
    // (con +1 queda Estados Unidos / Canadá).
    PaisTelefono? mejor;
    for (final p in lista) {
      final coincide = t.startsWith(p.codigo) &&
          (t.length == p.codigo.length || t[p.codigo.length] == ' ');
      if (coincide && (mejor == null || p.codigo.length > mejor.codigo.length)) mejor = p;
    }
    if (mejor == null) return (panama, t.substring(1).trim());
    return (mejor, t.substring(mejor.codigo.length).trim());
  }

  static String? validar(PaisTelefono pais, String? v) {
    if (pais.esPanama) return Validators.celularPanama(v);
    final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return 'Ingresa tu número de celular';
    if (digitos.length < pais.min || digitos.length > pais.max) {
      return pais.min == pais.max
          ? 'Debe tener ${pais.min} dígitos'
          : 'Debe tener entre ${pais.min} y ${pais.max} dígitos';
    }
    return null;
  }
}

/// Campo de celular con selector de código de país.
/// Al cambiar de país se borra el número, porque cambia el formato.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.pais,
    required this.onPaisChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final PaisTelefono pais;
  final ValueChanged<PaisTelefono> onPaisChanged;
  final TextInputAction? textInputAction;

  Future<void> _elegirPais(BuildContext context) async {
    final elegido = await showModalBottomSheet<PaisTelefono>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SelectorPais(actual: pais),
    );
    if (elegido != null && elegido != pais) {
      controller.clear();
      onPaisChanged(elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      inputFormatters: pais.esPanama
          ? [PanamaPhoneFormatter()]
          : [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(pais.max),
            ],
      decoration: InputDecoration(
        labelText: 'Número de celular',
        hintText: pais.ejemplo,
        prefixIcon: InkWell(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          onTap: () => _elegirPais(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pais.bandera, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(pais.codigo, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const Icon(Icons.arrow_drop_down_rounded),
                Container(width: 1, height: 24, color: Colors.black12),
              ],
            ),
          ),
        ),
      ),
      validator: (v) => PaisesTelefono.validar(pais, v),
    );
  }
}

class _SelectorPais extends StatefulWidget {
  const _SelectorPais({required this.actual});

  final PaisTelefono actual;

  @override
  State<_SelectorPais> createState() => _SelectorPaisState();
}

class _SelectorPaisState extends State<_SelectorPais> {
  String _filtro = '';

  String _normalizar(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final f = _normalizar(_filtro.trim());
    final paises = PaisesTelefono.lista
        .where((p) => f.isEmpty || _normalizar(p.nombre).contains(f) || p.codigo.contains(f))
        .toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Código de país',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _filtro = v),
              decoration: const InputDecoration(
                hintText: 'Buscar país o código',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: paises.length,
              itemBuilder: (_, i) {
                final p = paises[i];
                final sel = p.iso == widget.actual.iso;
                return ListTile(
                  leading: Text(p.bandera, style: const TextStyle(fontSize: 24)),
                  title: Text(p.nombre),
                  trailing: Text(p.codigo,
                      style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                  selected: sel,
                  onTap: () => Navigator.of(context).pop(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
