import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/utils/auth_errors.dart';
import '../../core/utils/biometric_vault.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/phone_field.dart';
import '../../navigation/main_shell.dart';
import '../../state/app_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _celCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  PaisTelefono _pais = PaisesTelefono.panama;
  bool _usaPasaporte = false;
  bool _obscure = true;
  bool _cargando = false;
  DateTime? _fechaNac;

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _apellidoCtrl, _docCtrl, _fechaCtrl, _emailCtrl, _celCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _esMayorDeEdad(DateTime nac) {
    final hoy = DateTime.now();
    var edad = hoy.year - nac.year;
    if (hoy.month < nac.month || (hoy.month == nac.month && hoy.day < nac.day)) edad--;
    return edad >= 18;
  }

  String _fechaIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(hoy.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
    );
    if (fecha != null) {
      setState(() {
        _fechaNac = fecha;
        _fechaCtrl.text = Fmt.fecha(fecha);
      });
    }
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      // El trigger de la BD crea perfil, categorías y presupuesto a partir de estos datos.
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'fecha_nacimiento': _fechaIso(_fechaNac!),
          'documento_identidad': _docCtrl.text.trim().toUpperCase(),
          'telefono': PaisesTelefono.unir(_pais, _celCtrl.text),
        },
      );
      if (res.session == null) {
        throw const AuthException('Revisa tu correo para confirmar la cuenta.');
      }
      await state.cargar();
      await BiometricVault.guardar(email, password);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) showSoon(context, mensajeAuth(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Crea tu Cuenta',
                        style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Completa tus datos para empezar a usar DIME',
                        style: t.bodyMedium?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (v) => Validators.requerido(v, 'El nombre'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Apellido'),
                            validator: (v) => Validators.requerido(v, 'El apellido'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Cédula')),
                        ButtonSegment(value: true, label: Text('Pasaporte')),
                      ],
                      selected: {_usaPasaporte},
                      onSelectionChanged: (s) => setState(() {
                        _usaPasaporte = s.first;
                        _docCtrl.clear();
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _docCtrl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                        UpperCaseFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: _usaPasaporte ? 'Número de pasaporte' : 'Cédula',
                        hintText: _usaPasaporte ? 'Ej. PA1234567' : 'Ej. 8-912-1456',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: _usaPasaporte ? Validators.pasaporte : Validators.cedulaPanama,
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
                      validator: (_) {
                        if (_fechaNac == null) return 'Selecciona tu fecha de nacimiento';
                        if (!_esMayorDeEdad(_fechaNac!)) return 'Debes ser mayor de 18 años';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    PhoneField(
                      controller: _celCtrl,
                      pais: _pais,
                      textInputAction: TextInputAction.next,
                      onPaisChanged: (p) => setState(() => _pais = p),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 8 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.passwordRegistro,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _crearCuenta,
                      child: _cargando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Ya tienes una cuenta?', style: t.bodyMedium),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                          child: const Text('Inicia Sesión'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
