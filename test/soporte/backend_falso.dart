import 'dart:convert';

import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/services/favoritos_service.dart';
import 'package:controlinventario/services/secure_token_storage.dart';
import 'package:dio/dio.dart';

/// Respuesta que devuelve el backend falso: código y cuerpo JSON.
typedef RespuestaFalsa = ({int codigo, Object? cuerpo});

/// `ApiClient` real (con sus interceptores) sobre un adaptador que responde
/// sin red. `rutas` asocia "MÉTODO /ruta" a una función que decide la respuesta.
ApiClient clienteFalso(Map<String, RespuestaFalsa Function(RequestOptions)> rutas) {
  final cliente = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://prueba')));
  cliente.dio.httpClientAdapter = AdaptadorFalso(rutas);
  return cliente;
}

class AdaptadorFalso implements HttpClientAdapter {
  AdaptadorFalso(this.rutas);

  final Map<String, RespuestaFalsa Function(RequestOptions)> rutas;

  /// Peticiones recibidas, en orden ("MÉTODO /ruta").
  final List<String> recibidas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? cuerpo,
    Future<void>? cancelacion,
  ) async {
    final clave = '${options.method} ${options.path}';
    recibidas.add(clave);
    final manejador = rutas[clave];
    final respuesta = manejador == null
        ? (codigo: 404, cuerpo: {'detail': 'Not Found'})
        : manejador(options);
    return ResponseBody.fromString(
      respuesta.cuerpo == null ? '' : jsonEncode(respuesta.cuerpo),
      respuesta.codigo,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Almacenamiento seguro en memoria, para no depender del Keystore en pruebas.
class AlmacenFalso implements SecureTokenStorage {
  AlmacenFalso([this.token]);

  String? token;
  String? usuarioJson;

  @override
  Future<String?> leer() async => token;

  @override
  Future<void> guardar(String valor) async => token = valor;

  @override
  Future<String?> leerUsuario() async => usuarioJson;

  @override
  Future<void> guardarUsuario(String json) async => usuarioJson = json;

  @override
  Future<void> borrar() async {
    token = null;
    usuarioJson = null;
  }
}

/// Favoritos en memoria (sin Hive) para pruebas de widgets.
class FavoritosFalso implements FavoritosService {
  final Map<int, Set<int>> porUsuario = {};

  @override
  Set<int> leer(int usuarioId) => {...?porUsuario[usuarioId]};

  @override
  Future<void> guardar(int usuarioId, Set<int> ids) async => porUsuario[usuarioId] = {...ids};
}
