import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/controllers/favoritos_controller.dart';
import 'package:controlinventario/controllers/productos_controller.dart';
import 'package:controlinventario/main.dart';
import 'package:controlinventario/models/producto.dart';
import 'package:controlinventario/models/usuario.dart';
import 'package:controlinventario/repositories/productos_repository.dart';
import 'package:controlinventario/screens/productos_screen.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/services/productos_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'soporte/backend_falso.dart';
import 'soporte/repositorio_falso.dart';

final _productos = [
  {'id': 1, 'nombre': 'Tornillos', 'cantidad': 40, 'cantidad_minima': 10},
  {'id': 2, 'nombre': 'Clavos', 'cantidad': 5, 'cantidad_minima': 10},
  {'id': 3, 'nombre': 'Brocha', 'cantidad': 6, 'cantidad_minima': 6},
];

void main() {
  late RespuestaFalsa Function(RequestOptions) respuestaProductos;
  late ApiClient api;

  /// Monta AuthController (con sesión abierta) y ProductosController sobre el backend falso.
  Future<ProductosController> preparar() async {
    api = clienteFalso({
      'GET /usuarios/me': (_) => (codigo: 200, cuerpo: {'id': 1, 'email': 'ana@tienda.com'}),
      'GET /productos/': (o) => respuestaProductos(o),
    });
    final auth = Get.put(AuthController(api: api, almacen: AlmacenFalso('tok')));
    await auth.restaurarSesion();
    return Get.put(
      ProductosController(repositorio: ProductosRepository(ProductosApiService(api)), auth: auth),
    );
  }

  setUp(() {
    Get.testMode = true;
    respuestaProductos = (_) => (codigo: 200, cuerpo: _productos);
  });

  tearDown(Get.reset);

  test('Producto.necesitaReponer incluye el caso igual al mínimo', () {
    expect(Producto.fromJson(_productos[0]).necesitaReponer, isFalse);
    expect(Producto.fromJson(_productos[1]).necesitaReponer, isTrue);
    expect(Producto.fromJson(_productos[2]).necesitaReponer, isTrue);
  });

  group('ProductosController', () {
    test('carga al haber sesión, ordenados por nombre, y pide limit=100', () async {
      String? limit;
      respuestaProductos = (o) {
        limit = '${o.queryParameters['limit']}';
        return (codigo: 200, cuerpo: _productos);
      };
      final c = await preparar();
      await c.cargar();

      expect(c.productos.map((p) => p.nombre), ['Brocha', 'Clavos', 'Tornillos']);
      expect(c.guardadoEl.value, isNull);
      expect(limit, '100');
      expect(c.totalPorReponer, 2);
    });

    test('filtro y búsqueda', () async {
      final c = await preparar();
      await c.cargar();

      c.filtro.value = FiltroProductos.porReponer;
      expect(c.visibles.map((p) => p.nombre), ['Brocha', 'Clavos']);

      c.busqueda.value = 'cla';
      expect(c.visibles.single.nombre, 'Clavos');
    });

    test('un 5xx deja el mensaje de error', () async {
      respuestaProductos = (_) => (codigo: 500, cuerpo: {'detail': 'Error interno del servidor'});
      final c = await preparar();
      await c.cargar();

      expect(c.error.value, 'El servidor tuvo un problema. Inténtalo más tarde.');
      expect(c.productos, isEmpty);
    });

    test('cerrar sesión vacía la lista', () async {
      final c = await preparar();
      await c.cargar();
      await Get.find<AuthController>().cerrarSesion();
      expect(c.productos, isEmpty);
    });
  });

  group('ProductosScreen', () {
    late RepositorioFalso repo;

    /// Sin HTTP: dio no avanza dentro del reloj simulado de las pruebas de widgets.
    Future<void> montar(WidgetTester tester) async {
      final auth = Get.put(AuthController(api: ApiClient(), almacen: AlmacenFalso()));
      auth.usuario.value = const Usuario(id: 1, email: 'ana@tienda.com');
      Get.put(ProductosController(repositorio: repo, auth: auth));
      Get.put(FavoritosController(servicio: FavoritosFalso(), auth: auth));
      await tester.pumpWidget(const InventarioApp(home: Scaffold(body: ProductosScreen())));
      await tester.pumpAndSettle();
    }

    setUp(() => repo = RepositorioFalso(_productos.map(Producto.fromJson).toList()));

    testWidgets('muestra la lista con la alerta de reposición', (tester) async {
      await montar(tester);
      expect(find.text('Tornillos'), findsOneWidget);
      expect(find.text('Por reponer'), findsNWidgets(2));
      expect(find.text('Por reponer (2)'), findsOneWidget);
    });

    testWidgets('estado vacío cuando no hay productos', (tester) async {
      repo.productos = [];
      await montar(tester);
      expect(find.text('Aún no tienes productos en tu inventario.'), findsOneWidget);
    });

    testWidgets('estado de error con Reintentar que recupera la lista', (tester) async {
      repo.error = ApiException(
        'El servidor tuvo un problema. Inténtalo más tarde.',
        statusCode: 503,
      );
      await montar(tester);
      expect(find.text('El servidor tuvo un problema. Inténtalo más tarde.'), findsOneWidget);

      repo.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Tornillos'), findsOneWidget);
    });
  });
}
