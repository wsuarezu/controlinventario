import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/controllers/productos_controller.dart';
import 'package:controlinventario/main.dart';
import 'package:controlinventario/models/producto.dart';
import 'package:controlinventario/models/usuario.dart';
import 'package:controlinventario/screens/productos_screen.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/services/productos_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'soporte/backend_falso.dart';
import 'soporte/repositorio_falso.dart';

const _clavos = Producto(id: 1, nombre: 'Clavos', cantidad: 20, cantidadMinima: 5);

void main() {
  late RepositorioFalso repo;
  late ProductosController c;

  setUp(() {
    Get.testMode = true;
    repo = RepositorioFalso([_clavos]);
    final auth = Get.put(AuthController(api: ApiClient(), almacen: AlmacenFalso()));
    auth.usuario.value = const Usuario(id: 1, email: 'ana@tienda.com');
    c = Get.put(ProductosController(repositorio: repo, auth: auth));
  });

  tearDown(Get.reset);

  group('ProductosController — CRUD', () {
    test('crear agrega a la lista en orden alfabético', () async {
      await c.cargar();
      expect(await c.crear(nombre: 'Brocha', cantidad: 3, cantidadMinima: 1), isNull);
      expect(c.productos.map((p) => p.nombre), ['Brocha', 'Clavos']);
    });

    test('editar cambia nombre y mínimo', () async {
      await c.cargar();
      expect(await c.actualizar(1, nombre: 'Clavos 2"', cantidadMinima: 8), isNull);
      expect(c.porId(1)!.nombre, 'Clavos 2"');
      expect(c.porId(1)!.cantidadMinima, 8);
      expect(c.porId(1)!.cantidad, 20);
    });

    test('ajustar suma y resta stock', () async {
      await c.cargar();
      await c.ajustar(1, 10);
      expect(c.porId(1)!.cantidad, 30);
      await c.ajustar(1, -25);
      expect(c.porId(1)!.cantidad, 5);
    });

    test('ajustar bajo el mínimo devuelve el 400 y no cambia la lista', () async {
      await c.cargar();
      final error = await c.ajustar(1, -16);
      expect(error, 'El ajuste dejaría la cantidad por debajo del mínimo');
      expect(c.porId(1)!.cantidad, 20);
    });

    test('eliminar quita el producto', () async {
      await c.cargar();
      expect(await c.eliminar(1), isNull);
      expect(c.productos, isEmpty);
    });

    test('un 404 devuelve el mensaje y recarga la lista', () async {
      await c.cargar();
      repo.productos = []; // otro dispositivo lo borró
      final error = await c.eliminar(1);
      await Future<void>.delayed(Duration.zero);

      expect(error, 'El producto ya no existe. Actualiza la lista.');
      expect(c.productos, isEmpty);
    });
  });

  test('ProductosApiService envía PATCH solo con los campos indicados', () async {
    Object? enviado;
    final api = clienteFalso({
      'PATCH /productos/1': (RequestOptions o) {
        enviado = o.data;
        return (codigo: 200, cuerpo: {..._clavos.toJson(), 'nombre': 'X'});
      },
    });
    final p = await ProductosApiService(api).actualizar(1, nombre: 'X');
    expect(enviado, {'nombre': 'X'});
    expect(p.nombre, 'X');
  });

  group('Pantallas — CRUD', () {
    Future<void> abrirLista(WidgetTester tester) async {
      await c.cargar();
      await tester.pumpWidget(const InventarioApp(home: Scaffold(body: ProductosScreen())));
      await tester.pumpAndSettle();
    }

    testWidgets('registrar una entrada desde el detalle', (tester) async {
      await abrirLista(tester);
      await tester.tap(find.text('Clavos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrada'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '7');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('27'), findsOneWidget);
      expect(find.text('Entrada de 7 registrada'), findsOneWidget);
    });

    testWidgets('una salida bajo el mínimo muestra el error del backend', (tester) async {
      await abrirLista(tester);
      await tester.tap(find.text('Clavos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salida'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '18');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(find.text('El ajuste dejaría la cantidad por debajo del mínimo'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmación y vuelve a la lista', (tester) async {
      await abrirLista(tester);
      await tester.tap(find.text('Clavos'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Aún no tienes productos en tu inventario.'), findsOneWidget);
      expect(repo.productos, isEmpty);
    });

    testWidgets('crear desde el estado vacío valida y agrega el producto', (tester) async {
      repo.productos = [];
      await abrirLista(tester);
      await tester.tap(find.text('Agregar producto'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar producto'));
      await tester.pumpAndSettle();
      expect(find.text('Completa el nombre'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Brocha 3"');
      await tester.enterText(find.byType(TextFormField).at(1), '12');
      await tester.enterText(find.byType(TextFormField).at(2), '4');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar producto'));
      await tester.pumpAndSettle();

      expect(find.text('Brocha 3"'), findsOneWidget);
      expect(repo.productos.single.cantidad, 12);
    });
  });
}
