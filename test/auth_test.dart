import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/controllers/favoritos_controller.dart';
import 'package:controlinventario/controllers/productos_controller.dart';
import 'package:controlinventario/main.dart';
import 'package:controlinventario/repositories/productos_repository.dart';
import 'package:controlinventario/services/productos_api_service.dart';
import 'package:controlinventario/screens/root_shell.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'soporte/backend_falso.dart';

const _usuario = {'id': 1, 'email': 'ana@tienda.com'};

/// Backend con un usuario válido (clave «clave123») y token «tok».
Map<String, RespuestaFalsa Function(RequestOptions)> _rutas() => {
  'POST /usuarios/token': (o) {
    final datos = o.data as Map;
    return datos['password'] == 'clave123'
        ? (codigo: 200, cuerpo: {'access_token': 'tok', 'token_type': 'bearer'})
        : (codigo: 401, cuerpo: {'detail': 'Credenciales inválidas'});
  },
  'GET /usuarios/me': (o) => o.headers['Authorization'] == 'Bearer tok'
      ? (codigo: 200, cuerpo: _usuario)
      : (codigo: 401, cuerpo: {'detail': 'Credenciales inválidas'}),
  'GET /productos/': (o) => (codigo: 200, cuerpo: <Object>[]),
  'POST /usuarios/': (o) => (o.data as Map)['email'] == 'ana@tienda.com'
      ? (codigo: 400, cuerpo: {'detail': 'El email ya está registrado'})
      : (codigo: 201, cuerpo: {'id': 2, 'email': (o.data as Map)['email']}),
};

void main() {
  late ApiClient api;
  late AlmacenFalso almacen;

  AuthController crear() => AuthController(api: api, almacen: almacen);

  setUp(() {
    Get.testMode = true;
    api = clienteFalso(_rutas());
    almacen = AlmacenFalso();
  });

  tearDown(Get.reset);

  group('AuthController', () {
    test('sin token guardado termina sin sesión', () async {
      final auth = crear();
      await auth.restaurarSesion();
      expect(auth.restaurando.value, isFalse);
      expect(auth.estaAutenticado, isFalse);
    });

    test('iniciar sesión guarda el token en el almacenamiento seguro', () async {
      final auth = crear();
      await auth.iniciarSesion('ana@tienda.com', 'clave123');

      expect(auth.estaAutenticado, isTrue);
      expect(auth.usuario.value!.email, 'ana@tienda.com');
      expect(almacen.token, 'tok');
      expect(api.token, 'tok');
    });

    test('credenciales incorrectas muestran el mensaje del 401 de login', () async {
      final auth = crear();
      await auth.iniciarSesion('ana@tienda.com', 'mala');

      expect(auth.estaAutenticado, isFalse);
      expect(auth.mensajeError.value, 'Correo o contraseña incorrectos.');
      expect(almacen.token, isNull);
    });

    test('registro con correo repetido muestra el 400 del backend', () async {
      final auth = crear();
      await auth.registrar('ana@tienda.com', 'clave123');
      expect(auth.mensajeError.value, 'El email ya está registrado');
    });

    test('restaura la sesión con un token guardado válido', () async {
      almacen.token = 'tok';
      final auth = crear();
      await auth.restaurarSesion();
      expect(auth.estaAutenticado, isTrue);
    });

    test('sin conexión al abrir, entra con el usuario guardado (para ver la caché)', () async {
      api = clienteFalso({}); // sin la ruta: se simula abajo con un error de conexión
      api.dio.httpClientAdapter = _SinRed();
      almacen
        ..token = 'tok'
        ..usuarioJson = '{"id":1,"email":"ana@tienda.com"}';
      final auth = crear();
      await auth.restaurarSesion();

      expect(auth.usuario.value?.email, 'ana@tienda.com');
      expect(almacen.token, 'tok', reason: 'sin red no se sabe si caducó: se conserva');
      expect(auth.avisoSesion.value, contains('No hay conexión'));
    });

    test('al iniciar sesión guarda id y correo junto al token', () async {
      final auth = crear();
      await auth.iniciarSesion('ana@tienda.com', 'clave123');
      expect(almacen.usuarioJson, contains('ana@tienda.com'));
    });

    test('un token guardado inválido se borra y avisa que caducó', () async {
      almacen.token = 'viejo';
      final auth = crear();
      await auth.restaurarSesion();

      expect(auth.estaAutenticado, isFalse);
      expect(almacen.token, isNull);
      expect(auth.avisoSesion.value, AuthController.mensajeCaducada);
    });

    test('un 401 en cualquier petición cierra la sesión y ejecuta la limpieza', () async {
      final auth = crear();
      api.alSesionCaducada = auth.sesionCaducada;
      var limpiezas = 0;
      auth.registrarLimpieza(() async => limpiezas++);
      await auth.iniciarSesion('ana@tienda.com', 'clave123');

      auth.invalidarTokenParaPruebas();
      await expectLater(api.get('/usuarios/me'), throwsA(isA<ApiException>()));
      await Future<void>.delayed(Duration.zero);

      expect(auth.estaAutenticado, isFalse);
      expect(almacen.token, isNull);
      expect(limpiezas, 1);
      expect(auth.avisoSesion.value, AuthController.mensajeCaducada);
    });
  });

  group('Pantallas', () {
    testWidgets('sin sesión se muestra el login', (tester) async {
      Get.put(crear());
      await tester.pumpWidget(const InventarioApp());
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para ver tu inventario'), findsOneWidget);
      expect(find.byType(RootShell), findsNothing);
    });

    testWidgets('el login valida los campos antes de llamar al servidor', (tester) async {
      Get.put(crear());
      await tester.pumpWidget(const InventarioApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect((api.dio.httpClientAdapter as AdaptadorFalso).recibidas, isEmpty);
    });

    testWidgets('entrar lleva al inventario y cerrar sesión vuelve al login', (tester) async {
      final auth = Get.put(crear());
      Get.put(
        ProductosController(repositorio: ProductosRepository(ProductosApiService(api)), auth: auth),
      );
      Get.put(FavoritosController(servicio: FavoritosFalso(), auth: auth));
      await tester.pumpWidget(const InventarioApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@tienda.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(RootShell), findsOneWidget);

      await tester.tap(find.byTooltip('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('ana@tienda.com'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para ver tu inventario'), findsOneWidget);
      expect(almacen.token, isNull);
    });
  });
}

/// Adaptador que falla como un backend apagado.
class _SinRed implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? cuerpo,
    Future<void>? cancelacion,
  ) => throw DioException.connectionError(requestOptions: options, reason: 'Connection refused');

  @override
  void close({bool force = false}) {}
}
