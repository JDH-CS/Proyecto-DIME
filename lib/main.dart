import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/accessibility/accessibility.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dime_palette.dart';
import 'core/utils/ui_helpers.dart';
import 'features/auth/auth_gate.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await Accessibility.cargar();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const DimeApp());
}

class DimeApp extends StatelessWidget {
  const DimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      // Al cambiar el modo de color se reconstruye el tema y se redibuja toda la app.
      child: ValueListenableBuilder<ColorMode>(
        valueListenable: Accessibility.modo,
        builder: (context, modo, _) => MaterialApp(
          title: 'DIME',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          theme: AppTheme.tema(modo).copyWith(extensions: [DimePalette(modo)]),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        ),
      ),
    );
  }
}
