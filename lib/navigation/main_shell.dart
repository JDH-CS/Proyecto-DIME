import 'package:flutter/material.dart';

import '../features/categories/categories_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

/// Contenedor con la barra de navegación inferior (NavigationBar de Material 3,
/// el sucesor visual de BottomNavigationBar).
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
