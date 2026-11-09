import 'package:flutter/material.dart';

import 'sections/gastos_section.dart';
import 'sections/ingresos_gastos_section.dart';
import 'sections/patrimonio_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'Gastos'),
              Tab(text: 'Patrimonio neto'),
              Tab(text: 'Ingresos vs Gastos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GastosSection(),
            PatrimonioSection(),
            IngresosGastosSection(),
          ],
        ),
      ),
    );
  }
}
