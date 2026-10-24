import 'dart:io';

import 'package:dio/dio.dart';

/// Error de red o HTTP ya traducido a un mensaje en español. `statusCode` es
/// null cuando no hubo respuesta HTTP (sin conexión o tiempo agotado).
class ApiException implements Exception {
  ApiException(this.mensaje, {this.statusCode, this.sinConexion = false});

  final String mensaje;
  final int? statusCode;

  /// true si el servidor no respondió (red caída, backend apagado o timeout).
  /// Lo usa el repositorio para decidir si muestra la caché offline.
  final bool sinConexion;

  bool get esNoAutorizado => statusCode == 401;

  static const rutaLogin = '/usuarios/token';

  /// Único lugar donde un error de `dio` se convierte en texto para la persona.
  factory ApiException.desde(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'El servidor tardó demasiado en responder. Revisa tu conexión e inténtalo de nuevo.',
          sinConexion: true,
        );
      case DioExceptionType.badResponse:
        return _desdeRespuesta(e.response!, e.requestOptions.path);
      default:
        if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
          return ApiException(
            'No hay conexión con el servidor. Revisa tu red y que el backend esté encendido.',
            sinConexion: true,
          );
        }
        return ApiException('No se pudo completar la petición. Inténtalo de nuevo.');
    }
  }

  static ApiException _desdeRespuesta(Response<dynamic> r, String ruta) {
    final codigo = r.statusCode ?? 0;
    final detail = r.data is Map ? (r.data as Map)['detail'] : null;

    if (codigo == 401) {
      // En el login, 401 = credenciales incorrectas; en otra ruta, el token ya no sirve.
      if (ruta == rutaLogin) {
        return ApiException('Correo o contraseña incorrectos.', statusCode: 401);
      }
      return ApiException('Tu sesión caducó. Inicia sesión de nuevo.', statusCode: 401);
    }
    if (codigo == 403) {
      return ApiException('No tienes permiso para modificar este producto.', statusCode: 403);
    }
    if (codigo == 404) {
      return ApiException('El producto ya no existe. Actualiza la lista.', statusCode: 404);
    }
    if (codigo >= 500) {
      return ApiException('El servidor tuvo un problema. Inténtalo más tarde.', statusCode: codigo);
    }
    if (codigo == 422 && detail is List) {
      final campos = detail.whereType<Map>().map((error) {
        final loc = error['loc'];
        final campo = loc is List && loc.isNotEmpty ? '${loc.last}' : 'dato';
        return '$campo: ${error['msg']}';
      });
      return ApiException('Datos inválidos — ${campos.join('; ')}', statusCode: 422);
    }
    // 400: el backend explica la regla de negocio en `detail` (texto en español).
    if (detail is String && detail.isNotEmpty) {
      return ApiException(detail, statusCode: codigo);
    }
    return ApiException('La petición no pudo completarse (código $codigo).', statusCode: codigo);
  }

  @override
  String toString() => mensaje;
}
