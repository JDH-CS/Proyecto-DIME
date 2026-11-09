import 'dart:math';

import 'package:flutter/painting.dart' show Color;

import '../core/theme/app_theme.dart';
import 'models/categoria.dart';
import 'models/perfil.dart';
import 'models/presupuesto.dart';
import 'models/transaccion.dart';

/// Datos de prueba locales. Se reemplazan por Supabase más adelante.
class MockData {
  MockData._();

  static const usuarioId = 'user_demo_001';
  static const presupuestoId = 'pres_001';
  static const _cuentaId = 'cuenta_demo_1';

  // (id, nombre, icono, monto asignado, fracción gastada del mes actual)
  static const List<(String, String, String, double, double)> _defs = [
    ('cat_viv', 'Vivienda', 'home', 950.0, 1.00),
    ('cat_ali', 'Alimentación', 'restaurant', 650.0, 0.72),
    ('cat_tra', 'Transporte', 'car', 250.0, 0.55),
    ('cat_ser', 'Servicios', 'bolt', 220.0, 0.83),
    ('cat_ent', 'Entretenimiento', 'movie', 150.0, 1.12),
    ('cat_sal', 'Salud', 'health', 150.0, 0.20),
    ('cat_edu', 'Educación', 'school', 200.0, 0.50),
    ('cat_com', 'Compras', 'shopping', 180.0, 0.40),
    ('cat_sus', 'Suscripciones', 'subscriptions', 60.0, 0.90),
  ];

  static const Map<String, String> _comercios = {
    'cat_viv': 'Alquiler apartamento',
    'cat_ali': 'Supermercado Rey',
    'cat_tra': 'Gasolinera / Metro',
    'cat_ser': 'Luz, agua e internet',
    'cat_ent': 'Cine y salidas',
    'cat_sal': 'Farmacia Arrocha',
    'cat_edu': 'Cursos y libros',
    'cat_com': 'Compras varias',
    'cat_sus': 'Streaming y apps',
  };

  /// Categorías predeterminadas que se ofrecen al "Añadir categoría".
  static const List<(String, String)> plantillasCategorias = [
    ('Vivienda', 'home'),
    ('Alimentación', 'restaurant'),
    ('Transporte', 'car'),
    ('Servicios', 'bolt'),
    ('Entretenimiento', 'movie'),
    ('Salud', 'health'),
    ('Educación', 'school'),
    ('Compras', 'shopping'),
    ('Suscripciones', 'subscriptions'),
    ('Mascotas', 'pets'),
    ('Viajes', 'flight'),
    ('Deporte', 'fitness'),
    ('Regalos', 'gift'),
    ('Café', 'coffee'),
    ('Hijos', 'child'),
    ('Ahorros', 'savings'),
  ];

  /// Patrimonio neto de los últimos 12 meses (el último valor es el mes actual).
  static const List<double> patrimonioBase = [
    1200, 1650, 2300, 2150, 2700, 2700, 3250, 3100, 3800, 4300, 4950, 5750,
  ];

  static Perfil perfil() => Perfil(
        id: usuarioId,
        nombre: 'Peter',
        apellido: 'Parker',
        fechaNacimiento: DateTime(1999, 12, 31),
        documentoIdentidad: '8-921-1456',
        estado: EstadoPerfil.activo,
        fechaCreacion: DateTime.now().subtract(const Duration(days: 330)),
        fechaActualizacion: DateTime.now(),
        correo: 'peter.parker@gmail.com',
        celular: '+507 6123-4567',
      );

  static List<Categoria> categoriasGasto() => [
        for (var i = 0; i < _defs.length; i++)
          Categoria(
            id: _defs[i].$1,
            usuarioId: usuarioId,
            nombre: _defs[i].$2,
            tipoCategoria: 'gasto',
            color: AppTheme.chartShades[i % AppTheme.chartShades.length].toARGB32(),
            icono: _defs[i].$3,
            esPredeterminada: true,
            fechaCreacion: DateTime.now().subtract(const Duration(days: 330)),
          ),
      ];

  static Presupuesto presupuesto() {
    final now = DateTime.now();
    return Presupuesto(
      id: presupuestoId,
      usuarioId: usuarioId,
      nombre: 'Presupuesto mensual',
      fechaInicio: DateTime(now.year, now.month, 1),
      fechaFin: DateTime(now.year, now.month + 1, 0),
      moneda: 'USD',
      fechaCreacion: now,
      fechaActualizacion: now,
    );
  }

  static List<AsignacionPresupuestaria> asignaciones(List<Categoria> cats) {
    final now = DateTime.now();
    return [
      for (final d in _defs)
        AsignacionPresupuestaria(
          id: 'ap_${d.$1}',
          presupuestoId: presupuestoId,
          categoriaId: d.$1,
          montoAsignado: d.$4,
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
    ];
  }

  /// 12 meses de transacciones (ingresos + gastos), deterministas.
  static List<Transaccion> transacciones(List<Categoria> cats) {
    final rnd = Random(7);
    final now = DateTime.now();
    final out = <Transaccion>[];
    var n = 0;

    Transaccion tx(String catId, String tipo, String desc, double monto, DateTime fecha) {
      n++;
      return Transaccion(
        id: 'tx_$n',
        usuarioId: usuarioId,
        cuentaFinancieraId: _cuentaId,
        categoriaId: catId,
        identificadorExterno: 'EXT-${1000 + n}',
        codigoComercio: 'MCC-${5000 + rnd.nextInt(900)}',
        descripcion: desc,
        tipoTransaccion: tipo,
        monto: monto,
        fechaTransaccion: fecha,
        origen: 'banco',
        fechaRegistro: fecha,
        fechaActualizacion: fecha,
      );
    }

    double r2(double v) => double.parse(v.toStringAsFixed(2));

    for (var m = 11; m >= 0; m--) {
      final mes = DateTime(now.year, now.month - m);
      final esActual = m == 0;
      final maxDia = esActual ? now.day : DateTime(mes.year, mes.month + 1, 0).day;

      // Ingresos
      out.add(tx('cat_ing_sal', 'ingreso', 'Depósito de salario', 3200, DateTime(mes.year, mes.month, 1)));
      if (esActual || m % 3 == 0) {
        out.add(tx('cat_ing_free', 'ingreso', 'Trabajo freelance', 300, DateTime(mes.year, mes.month, min(5, maxDia))));
      }

      // Gastos por categoría
      for (final d in _defs) {
        final factor = d.$1 == 'cat_viv' ? 1.0 : (esActual ? d.$5 : 0.7 + rnd.nextDouble() * 0.6);
        final total = r2(d.$4 * factor);
        final partes = d.$1 == 'cat_viv' ? 1 : 2 + rnd.nextInt(3);
        var restante = total;
        for (var i = 0; i < partes; i++) {
          final monto = i == partes - 1 ? restante : r2(total / partes);
          restante = r2(restante - monto);
          if (monto <= 0) continue;
          final dia = d.$1 == 'cat_viv' ? 1 : 1 + rnd.nextInt(maxDia);
          out.add(tx(d.$1, 'gasto', _comercios[d.$1] ?? d.$2, monto, DateTime(mes.year, mes.month, dia)));
        }
      }
    }
    return out;
  }

  /// Color del tono n-ésimo (útil para nuevas categorías).
  static Color shade(int i) => AppTheme.chartShades[i % AppTheme.chartShades.length];
}
