import '../models/usuario.dart';
import 'api_client.dart';

/// Llamadas de autenticación al backend. Solo traduce peticiones y respuestas;
/// el estado de la sesión vive en `AuthController`.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// POST /usuarios/ (JSON) → 201. Correo repetido → 400 con el motivo.
  Future<void> registrar(String email, String password) =>
      _api.post('/usuarios/', data: {'email': email, 'password': password});

  /// POST /usuarios/token: el estándar OAuth2 exige formulario, no JSON, y el
  /// campo se llama `username` aunque lleve el correo. Devuelve el token.
  Future<String> iniciarSesion(String email, String password) async {
    final r = await _api.post(
      ApiException.rutaLogin,
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return (r.data as Map)['access_token'] as String;
  }

  /// GET /usuarios/me con el token actual.
  Future<Usuario> usuarioActual() async {
    final r = await _api.get('/usuarios/me');
    return Usuario.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
