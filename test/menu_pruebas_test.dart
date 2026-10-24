import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/controllers/productos_controller.dart';
import 'package:controlinventario/main.dart';
import 'package:controlinventario/models/usuario.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/utils/reporte_errores.dart';
import 'package:controlinventario/widgets/error_pantalla_view.dart';
import 'package:controlinventario/widgets/menu_pruebas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'soporte/backend_falso.dart';
import 'soporte/repositorio_falso.dart';

void main() {
  late AuthController auth;
  late ApiClient api;

  Future<void> montar(WidgetTester tester) async {
    Get.testMode = true;
    api = ApiClient()..token = 'tok';
    auth = Get.put(AuthController(api: api, almacen: AlmacenFalso('tok')));
    auth.usuario.value = const Usuario(id: 1, email: 'ana@tienda.com');
    Get.put(ProductosController(repositorio: RepositorioFalso([]), auth: auth));
    await tester.pumpWidget(
      InventarioApp(
        home: Scaffold(appBar: AppBar(actions: const [MenuPruebas()])),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester tester, String opcion) async {
    await tester.tap(find.byTooltip('Pruebas de errores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion));
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('muestra todas las pruebas, marcadas como solo práctica', (tester) async {
    await montar(tester);
    await tester.tap(find.byTooltip('Pruebas de errores'));
    await tester.pumpAndSettle();

    expect(find.text('Pruebas de errores (solo práctica)'), findsOneWidget);
    for (final opcion in [
      'Invalidar token',
      'Enviar datos inválidos',
      'Error de pantalla',
      'Error asíncrono',
      'Ver registro de errores',
    ]) {
      expect(find.text(opcion), findsOneWidget);
    }
  });

  testWidgets('Enviar datos inválidos muestra el mensaje del 422', (tester) async {
    await montar(tester);
    await elegir(tester, 'Enviar datos inválidos');
    expect(find.textContaining('Datos inválidos — cantidad'), findsOneWidget);
  });

  testWidgets('Invalidar token cambia el token de la sesión', (tester) async {
    await montar(tester);
    await elegir(tester, 'Invalidar token');
    expect(api.token, 'token-invalido');
  });

  testWidgets('Ver registro de errores muestra los errores ya limpios', (tester) async {
    ReporteErrores.recientes.clear();
    ReporteErrores.registrar(StateError('falló con Bearer abc.def.ghi'), null);
    await montar(tester);
    await elegir(tester, 'Ver registro de errores');

    expect(find.textContaining('Bearer ***'), findsOneWidget);
    expect(find.textContaining('abc.def.ghi'), findsNothing);
  });

  testWidgets('Error de pantalla muestra la vista amigable', (tester) async {
    final anterior = ErrorWidget.builder;
    ErrorWidget.builder = (_) => const ErrorPantallaView();
    try {
      await montar(tester);
      await elegir(tester, 'Error de pantalla');

      expect(tester.takeException(), isA<StateError>());
      expect(find.text('Esta pantalla tuvo un problema'), findsOneWidget);
    } finally {
      // Flutter exige restaurarlo antes de que termine el cuerpo de la prueba.
      ErrorWidget.builder = anterior;
    }
  });
}
