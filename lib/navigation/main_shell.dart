import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/categories/categories_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tour/tour_prefs.dart';
import '../features/tour/tour_screen.dart';
import '../state/app_state.dart';

/// Contenedor con la barra de navegación inferior (NavigationBar de Material 3,
/// el sucesor visual de BottomNavigationBar). Muestra el tour a los usuarios nuevos.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    CategoriesScreen(),
    DashboardScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarTourSiCorresponde());
  }

  Future<void> _mostrarTourSiCorresponde() async {
    if (!mounted) return;
    final uid = context.read<AppState>().perfil.id;
    if (await TourPrefs.completado(uid)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => TourScreen(userId: uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
