import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda la sesión en el almacenamiento seguro del sistema (Keystore en
/// Android): el token JWT y los datos básicos del usuario (JSON con id y
/// correo), que permiten abrir la app sin conexión y mostrar su caché.
class SecureTokenStorage {
  SecureTokenStorage([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  static const _claveToken = 'access_token';
  static const _claveUsuario = 'usuario';
  final FlutterSecureStorage _almacen;

  Future<String?> leer() => _almacen.read(key: _claveToken);

  Future<void> guardar(String token) => _almacen.write(key: _claveToken, value: token);

  Future<String?> leerUsuario() => _almacen.read(key: _claveUsuario);

  Future<void> guardarUsuario(String json) => _almacen.write(key: _claveUsuario, value: json);

  Future<void> borrar() async {
    await _almacen.delete(key: _claveToken);
    await _almacen.delete(key: _claveUsuario);
  }
}
