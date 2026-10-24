import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/favoritos_controller.dart';
import 'controllers/productos_controller.dart';
import 'screens/root_shell.dart';
import 'services/api_client.dart';
import 'services/cache_productos_service.dart';
import 'services/favoritos_service.dart';
import 'theme/app_theme.dart';
import 'utils/reporte_errores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ReporteErrores.instalar();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(CacheProductosService.nombreCaja);
  await Hive.openBox<dynamic>(FavoritosService.nombreCaja);
  // Un solo cliente HTTP y un solo controlador de sesión para toda la app.
  // Al crearse, AuthController comprueba si hay un token guardado.
  Get.put(ApiClient(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(ProductosController(), permanent: true);
  Get.put(FavoritosController(), permanent: true);
  Get.put(AsistenteController(), permanent: true);
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
      home: home ?? const PuertaSesion(),
    );
  }
}
