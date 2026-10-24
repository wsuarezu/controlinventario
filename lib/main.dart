import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'utils/reporte_errores.dart';
import 'widgets/empty_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReporteErrores.instalar();
  await Hive.initFlutter();
  Get.put(ApiClient(), permanent: true);
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key, this.home});

  /// Permite a las pruebas montar la app con otra pantalla inicial.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Control de Inventario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      themeMode: ThemeMode.system,
      home:
          home ??
          Scaffold(
            appBar: AppBar(title: const Text('Control de Inventario')),
            body: const EmptyView(mensaje: 'Base de la app lista. Pronto: inicio de sesión.'),
          ),
    );
  }
}
