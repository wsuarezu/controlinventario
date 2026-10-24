import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

export 'package:dio/dio.dart' show Headers, Options;

export 'api_exception.dart';

/// Cliente HTTP único de la app (una sola instancia de `dio`). Añade el token
/// a cada petición, avisa cuando la sesión caduca y convierte todo error en
/// `ApiException`, para que ningún repositorio repita esa lógica.
class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, siguiente) {
          final t = token;
          if (t != null) opciones.headers['Authorization'] = 'Bearer $t';
          siguiente.next(opciones);
        },
        onError: (error, siguiente) {
          // Un 401 fuera del login significa que el token caducó o fue
          // invalidado: se avisa en un solo lugar (AuthController cierra sesión).
          final esLogin = error.requestOptions.path == ApiException.rutaLogin;
          if (error.response?.statusCode == 401 && !esLogin) {
            alSesionCaducada?.call();
          }
          siguiente.next(error);
        },
      ),
    );
  }

  final Dio dio;

  /// Token JWT en memoria mientras la app está abierta; entre aperturas lo
  /// guarda `SecureTokenStorage`.
  String? token;

  /// Lo asigna `AuthController`: se llama cuando el servidor responde 401.
  void Function()? alSesionCaducada;

  Future<Response<dynamic>> get(String ruta, {Map<String, dynamic>? query}) =>
      _enviar(() => dio.get(ruta, queryParameters: query));

  Future<Response<dynamic>> post(String ruta, {Object? data, Options? options}) =>
      _enviar(() => dio.post(ruta, data: data, options: options));

  Future<Response<dynamic>> patch(String ruta, {Object? data}) =>
      _enviar(() => dio.patch(ruta, data: data));

  Future<Response<dynamic>> delete(String ruta) => _enviar(() => dio.delete(ruta));

  /// Único try/catch de red: todo error de `dio` sale como `ApiException`.
  Future<Response<dynamic>> _enviar(Future<Response<dynamic>> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw ApiException.desde(e);
    }
  }
}
