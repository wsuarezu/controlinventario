import 'package:flutter/material.dart';

/// Tema visual de Control de Inventario: un solo lugar para colores,
/// tipografía y formas. Las pantallas leen todo desde `Theme.of(context)`.
///
/// Paleta: verde (stock sano) como primario, ámbar (alerta de stock bajo)
/// como acento y pizarra para la AppBar.
class AppTheme {
  AppTheme._();

  static const Color verde = Color(0xFF2E7D32);
  static const Color ambar = Color(0xFFF9A825);
  static const Color pizarra = Color(0xFF263238);

  /// Color de alerta para productos bajo el mínimo (igual en claro y oscuro).
  static const Color alertaStock = Color(0xFFE65100);

  static ThemeData get claro => _construir(Brightness.light);

  /// Misma semilla con `Brightness.dark`: Flutter genera la paleta oscura
  /// completa. No se fijan colores de texto para que sigan siendo legibles.
  static ThemeData get oscuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final esClaro = brillo == Brightness.light;
    final colores = ColorScheme.fromSeed(
      seedColor: verde,
      primary: esClaro ? verde : null,
      secondary: ambar,
      brightness: brillo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      scaffoldBackgroundColor: esClaro ? const Color(0xFFF5F7F6) : null,
      appBarTheme: const AppBarTheme(
        backgroundColor: pizarra,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colores.primary,
          foregroundColor: colores.onPrimary,
          minimumSize: const Size(48, 48), // tamaño mínimo de toque accesible
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colores.primary,
        foregroundColor: colores.onPrimary,
      ),
    );
  }
}

/// Espaciados de la app: se usan en lugar de números sueltos en cada widget.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
