import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_client.dart';

/// Respuesta del asistente. `modo` es «gemini» (IA) o «reglas» (sin IA).
class RespuestaAsistente {
  const RespuestaAsistente({required this.texto, required this.modo});

  final String texto;
  final String modo;

  bool get esIa => modo == 'gemini';

  factory RespuestaAsistente.fromJson(Map<String, dynamic> json) => RespuestaAsistente(
    texto: (json['respuesta'] as String?)?.trim().isNotEmpty == true
        ? json['respuesta'] as String
        : 'El asistente no devolvió ninguna respuesta.',
    modo: json['modo'] as String? ?? 'reglas',
  );
}

/// Error del asistente ya traducido a un mensaje para la persona.
class AsistenteException implements Exception {
  AsistenteException(this.mensaje, {this.sesionCaducada = false});

  final String mensaje;
  final bool sesionCaducada;

  @override
  String toString() => mensaje;
}

/// Habla con el servidor propio del asistente (`asistente-server/`). La app
/// no conoce ninguna clave de IA: solo envía la pregunta y el token de la
/// sesión, con el que el servidor consulta el inventario del usuario.
class AsistenteService {
  AsistenteService(this._api, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.asistenteUrl,
              connectTimeout: const Duration(seconds: 10),
              // El modelo puede tardar: más margen que el backend.
              receiveTimeout: const Duration(seconds: 40),
            ),
          );

  final ApiClient _api;
  final Dio _dio;

  Future<RespuestaAsistente> preguntar(String pregunta) async {
    final token = _api.token;
    if (token == null) {
      throw AsistenteException('Inicia sesión para usar el asistente.', sesionCaducada: true);
    }
    try {
      final r = await _dio.post(
        '/asistente',
        data: {'consulta': pregunta},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return RespuestaAsistente.fromJson(Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  AsistenteException _traducir(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AsistenteException('El asistente tardó demasiado en responder. Inténtalo de nuevo.');
      case DioExceptionType.badResponse:
        final codigo = e.response?.statusCode ?? 0;
        final datos = e.response?.data;
        final detail = datos is Map ? datos['detail'] : null;
        if (codigo == 401) {
          // Mismo camino que un 401 del backend: AuthController cierra la sesión.
          _api.alSesionCaducada?.call();
          return AsistenteException(
            'Tu sesión caducó. Inicia sesión de nuevo.',
            sesionCaducada: true,
          );
        }
        if (detail is String && detail.isNotEmpty) return AsistenteException(detail);
        return AsistenteException('El asistente tuvo un problema (código $codigo).');
      default:
        return AsistenteException(
          'El asistente no está disponible. Revisa que el servidor del asistente esté encendido.',
        );
    }
  }
}
