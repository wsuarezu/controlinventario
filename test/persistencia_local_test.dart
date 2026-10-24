import 'dart:io';

import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/controllers/favoritos_controller.dart';
import 'package:controlinventario/models/producto.dart';
import 'package:controlinventario/models/usuario.dart';
import 'package:controlinventario/repositories/productos_repository.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/services/cache_productos_service.dart';
import 'package:controlinventario/services/favoritos_service.dart';
import 'package:controlinventario/services/productos_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'soporte/backend_falso.dart';

const _clavos = Producto(id: 1, nombre: 'Clavos', cantidad: 8, cantidadMinima: 10);

/// Hive real sobre una carpeta temporal: cerrar y reabrir las cajas simula
/// el cierre completo de la app.
void main() {
  late Directory carpeta;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('inventario_hive_');
    Hive.init(carpeta.path);
  });

  tearDown(() async {
    await Hive.close();
    await carpeta.delete(recursive: true);
    Get.reset();
  });

  Future<Box<dynamic>> reabrir(String nombre) async {
    await Hive.close();
    Hive.init(carpeta.path);
    return Hive.openBox<dynamic>(nombre);
  }

  group('Favoritos', () {
    test('sobreviven al cierre completo de la app', () async {
      final servicio = FavoritosService(await Hive.openBox<dynamic>(FavoritosService.nombreCaja));
      await servicio.guardar(1, {3, 7});

      final tras = FavoritosService(await reabrir(FavoritosService.nombreCaja));
      expect(tras.leer(1), {3, 7});
    });

    test('son de cada usuario', () async {
      final servicio = FavoritosService(await Hive.openBox<dynamic>(FavoritosService.nombreCaja));
      await servicio.guardar(1, {3});
      expect(servicio.leer(2), isEmpty);
    });

    test('FavoritosController carga al iniciar sesión y alterna la estrella', () async {
      Get.testMode = true;
      final servicio = FavoritosService(await Hive.openBox<dynamic>(FavoritosService.nombreCaja));
      await servicio.guardar(1, {5});
      final auth = AuthController(api: ApiClient(), almacen: AlmacenFalso());
      final favoritos = Get.put(FavoritosController(servicio: servicio, auth: auth));

      auth.usuario.value = const Usuario(id: 1, email: 'ana@tienda.com');
      await Future<void>.delayed(Duration.zero);
      expect(favoritos.esFavorito(5), isTrue);

      await favoritos.alternar(9);
      await favoritos.alternar(5);
      expect(servicio.leer(1), {9});

      auth.usuario.value = null;
      await Future<void>.delayed(Duration.zero);
      expect(favoritos.ids, isEmpty, reason: 'otra persona no ve los favoritos anteriores');
    });
  });

  group('Caché offline', () {
    final fecha = DateTime(2026, 10, 24, 14, 5);
    late RespuestaFalsa Function() respuesta;
    late ProductosRepository repo;

    Future<void> crearRepo() async {
      final api = clienteFalso({'GET /productos/': (_) => respuesta()});
      final cache = CacheProductosService(
        await Hive.openBox<dynamic>(CacheProductosService.nombreCaja),
      );
      repo = ProductosRepository(ProductosApiService(api), cache, () => fecha);
    }

    setUp(() async {
      respuesta = () => (codigo: 200, cuerpo: [_clavos.toJson()]);
      await crearRepo();
    });

    test('la copia sobrevive al cierre completo de la app', () async {
      await repo.obtenerTodos(1);

      final cache = CacheProductosService(await reabrir(CacheProductosService.nombreCaja));
      final copia = cache.leer(1)!;
      expect(copia.productos.single.nombre, 'Clavos');
      expect(copia.guardadoEl, fecha);
    });

    test('sin conexión devuelve la copia con su fecha', () async {
      await repo.obtenerTodos(1);
      final api = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://prueba')));
      api.dio.httpClientAdapter = _SinRed();
      final offline = ProductosRepository(
        ProductosApiService(api),
        CacheProductosService(Hive.box(CacheProductosService.nombreCaja)),
      );

      final resultado = await offline.obtenerTodos(1);
      expect(resultado.desdeCache, isTrue);
      expect(resultado.guardadoEl, fecha);
      expect(resultado.productos.single.nombre, 'Clavos');
    });

    test('sin conexión y sin copia (primer uso) se propaga el error', () async {
      final api = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://prueba')));
      api.dio.httpClientAdapter = _SinRed();
      final offline = ProductosRepository(
        ProductosApiService(api),
        CacheProductosService(Hive.box(CacheProductosService.nombreCaja)),
      );

      await expectLater(
        offline.obtenerTodos(1),
        throwsA(isA<ApiException>().having((e) => e.sinConexion, 'sinConexion', isTrue)),
      );
    });

    test('un 5xx no se oculta con la copia', () async {
      await repo.obtenerTodos(1);
      respuesta = () => (codigo: 500, cuerpo: {'detail': 'Error interno del servidor'});
      await expectLater(repo.obtenerTodos(1), throwsA(isA<ApiException>()));
    });

    test('la copia es de cada usuario y se borra al cerrar sesión', () async {
      await repo.obtenerTodos(1);
      final cache = CacheProductosService(Hive.box(CacheProductosService.nombreCaja));
      expect(cache.leer(2), isNull);

      await repo.borrarCache(1);
      expect(cache.leer(1), isNull);
    });
  });
}

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
