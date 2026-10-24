import 'dart:io';

import 'package:controlinventario/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _respuesta(int codigo, Object? data, {String ruta = '/productos/'}) {
  final opciones = RequestOptions(path: ruta);
  return DioException(
    requestOptions: opciones,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: opciones, statusCode: codigo, data: data),
  );
}

DioException _sinRespuesta(DioExceptionType tipo, {Object? error}) => DioException(
  requestOptions: RequestOptions(path: '/productos/'),
  type: tipo,
  error: error,
);

void main() {
  group('ApiException.desde da un mensaje distinto por cada caso', () {
    test('400 usa el detalle del backend (regla de negocio)', () {
      final e = ApiException.desde(
        _respuesta(400, {'detail': 'El ajuste dejaría la cantidad por debajo del mínimo'}),
      );
      expect(e.statusCode, 400);
      expect(e.mensaje, 'El ajuste dejaría la cantidad por debajo del mínimo');
    });

    test('401 en el login = credenciales incorrectas', () {
      final e = ApiException.desde(
        _respuesta(401, {'detail': 'Credenciales inválidas'}, ruta: '/usuarios/token'),
      );
      expect(e.mensaje, 'Correo o contraseña incorrectos.');
    });

    test('401 en otra ruta = sesión caducada', () {
      final e = ApiException.desde(_respuesta(401, {'detail': 'Not authenticated'}));
      expect(e.esNoAutorizado, isTrue);
      expect(e.mensaje, contains('sesión caducó'));
    });

    test('403 = sin permiso', () {
      final e = ApiException.desde(_respuesta(403, {'detail': 'x'}));
      expect(e.mensaje, contains('permiso'));
    });

    test('404 = el producto ya no existe', () {
      final e = ApiException.desde(_respuesta(404, {'detail': 'Producto 9 no existe'}));
      expect(e.mensaje, contains('ya no existe'));
    });

    test('422 lista cada campo inválido', () {
      final e = ApiException.desde(
        _respuesta(422, {
          'detail': [
            {
              'loc': ['body', 'cantidad'],
              'msg': 'Input should be a valid integer',
            },
          ],
        }),
      );
      expect(e.statusCode, 422);
      expect(e.mensaje, 'Datos inválidos — cantidad: Input should be a valid integer');
    });

    test('5xx = problema del servidor, sin detalles técnicos', () {
      final e = ApiException.desde(_respuesta(500, {'detail': 'Error interno del servidor'}));
      expect(e.mensaje, 'El servidor tuvo un problema. Inténtalo más tarde.');
      expect(e.sinConexion, isFalse);
    });

    test('timeout = el servidor tardó demasiado', () {
      final e = ApiException.desde(_sinRespuesta(DioExceptionType.receiveTimeout));
      expect(e.mensaje, contains('tardó demasiado'));
      expect(e.sinConexion, isTrue);
    });

    test('sin conexión = backend apagado o sin red', () {
      final e = ApiException.desde(
        _sinRespuesta(DioExceptionType.unknown, error: const SocketException('Connection refused')),
      );
      expect(e.mensaje, contains('No hay conexión'));
      expect(e.sinConexion, isTrue);
      expect(e.statusCode, isNull);
    });
  });

  test('ApiClient añade el token y avisa el 401 fuera del login', () async {
    final cliente = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://prueba')));
    cliente.token = 'abc';
    var avisos = 0;
    cliente.alSesionCaducada = () => avisos++;
    String? cabecera;

    cliente.dio.httpClientAdapter = _AdaptadorFalso((opciones) {
      cabecera = opciones.headers['Authorization'] as String?;
      return 401;
    });

    await expectLater(cliente.get('/productos/'), throwsA(isA<ApiException>()));
    expect(cabecera, 'Bearer abc');
    expect(avisos, 1);

    await expectLater(cliente.post('/usuarios/token'), throwsA(isA<ApiException>()));
    expect(avisos, 1, reason: 'un 401 en el login no es una sesión caducada');
  });
}

/// Responde con el código que decida la función, sin red real.
class _AdaptadorFalso implements HttpClientAdapter {
  _AdaptadorFalso(this.codigoPara);

  final int Function(RequestOptions) codigoPara;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? cuerpo,
    Future<void>? cancelacion,
  ) async {
    return ResponseBody.fromString(
      '{"detail":"Not authenticated"}',
      codigoPara(options),
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
