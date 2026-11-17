import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/phone_field.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/perfil.dart';
import '../../data/services/cuenta_service.dart';
import '../../state/app_state.dart';

/// "Administrar perfil": foto y datos personales.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _fechaCtrl;
  late DateTime _fechaNac;

  bool _guardando = false;
  bool _subiendoFoto = false;

  late PaisTelefono _pais;
  late String _telOriginal; // el teléfono guardado, ya normalizado

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().perfil;
    _nombreCtrl = TextEditingController(text: p.nombre);
    _apellidoCtrl = TextEditingController(text: p.apellido);
    final (pais, numero) = PaisesTelefono.separar(p.celular);
    _pais = pais;
    _telOriginal = PaisesTelefono.unir(pais, numero);
    _telCtrl = TextEditingController(text: numero);
    _fechaNac = p.fechaNacimiento;
    _fechaCtrl = TextEditingController(text: Fmt.fecha(p.fechaNacimiento));
    for (final c in [_nombreCtrl, _apellidoCtrl, _telCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  bool _hayCambios(Perfil p) =>
      _nombreCtrl.text.trim() != p.nombre ||
      _apellidoCtrl.text.trim() != p.apellido ||
      PaisesTelefono.unir(_pais, _telCtrl.text) != _telOriginal ||
      _fechaNac != p.fechaNacimiento;

  bool _esMayorDeEdad(DateTime nac) {
    final hoy = DateTime.now();
    var edad = hoy.year - nac.year;
    if (hoy.month < nac.month || (hoy.month == nac.month && hoy.day < nac.day)) edad--;
    return edad >= 18;
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaNac,
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
    );
    if (f != null) {
      setState(() {
        _fechaNac = f;
        _fechaCtrl.text = Fmt.fecha(f);
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final state = context.read<AppState>();
    try {
      await CuentaService(state).actualizarPerfil(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        fechaNacimiento: _fechaNac,
        telefono: PaisesTelefono.unir(_pais, _telCtrl.text),
      );
      _telOriginal = PaisesTelefono.unir(_pais, _telCtrl.text);
      if (mounted) showSoon(context, 'Perfil actualizado');
    } catch (_) {
      if (mounted) showSoon(context, 'No se pudo guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ───────────── Foto ─────────────
  void _opcionesFoto(Perfil p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _elegirFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            if (p.fotoRuta != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _quitarFoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirFoto(ImageSource fuente) async {
    final state = context.read<AppState>();
    try {
      final x = await ImagePicker().pickImage(
        source: fuente,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (x == null) return;

      if (mounted) setState(() => _subiendoFoto = true);
      final bytes = await x.readAsBytes();
      final ext = x.path.contains('.') ? x.path.split('.').last : 'jpg';
      await CuentaService(state).cambiarFoto(bytes, ext);
      if (mounted) showSoon(context, 'Foto actualizada');
    } catch (_) {
      if (mounted) showSoon(context, 'No se pudo cambiar la foto. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _quitarFoto() async {
    final state = context.read<AppState>();
    setState(() => _subiendoFoto = true);
    try {
      await CuentaService(state).quitarFoto();
      if (mounted) showSoon(context, 'Foto eliminada');
    } catch (_) {
      if (mounted) showSoon(context, 'No se pudo eliminar la foto.');
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().perfil;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final solo = <(IconData, String, String)>[
      (Icons.badge_outlined, 'Documento de identidad', p.documentoIdentidad),
      (Icons.mail_outline_rounded, 'Correo electrónico', p.correo),
      (Icons.event_available_outlined, 'Miembro desde', Fmt.fecha(p.fechaCreacion)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Administrar perfil')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Foto
            Center(
              child: GestureDetector(
                onTap: _subiendoFoto ? null : () => _opcionesFoto(p),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: ProfileAvatar(perfil: p, radius: 56),
                    ),
                    if (_subiendoFoto)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary,
                        child: Icon(Icons.photo_camera_rounded, size: 18, color: cs.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 16),

            // Datos editables
            SoftCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Información personal',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (v) => Validators.requerido(v, 'El nombre'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Apellido'),
                            validator: (v) => Validators.requerido(v, 'El apellido'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _fechaCtrl,
                      readOnly: true,
                      onTap: _elegirFecha,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (_) =>
                          _esMayorDeEdad(_fechaNac) ? null : 'Debes ser mayor de 18 años',
                    ),
                    const SizedBox(height: 14),
                    PhoneField(
                      controller: _telCtrl,
                      pais: _pais,
                      onPaisChanged: (p) => setState(() => _pais = p),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (_hayCambios(p) && !_guardando) ? _guardar : null,
                      child: _guardando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Datos de solo lectura
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < solo.length; i++) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Icon(solo[i].$1, size: 20, color: Colors.black54),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(solo[i].$2,
                                    style: t.labelMedium?.copyWith(color: Colors.black54)),
                                const SizedBox(height: 2),
                                Text(solo[i].$3,
                                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black26),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tu documento y correo no se pueden editar aquí. Si necesitas cambiarlos, escríbenos desde Ayuda y soporte.',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
