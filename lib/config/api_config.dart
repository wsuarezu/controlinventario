/// Direcciones de los servidores. Se definen al compilar con `--dart-define`;
/// los valores por defecto (`10.0.2.2`) son cómo el emulador Android ve el
/// `localhost` del computador. La app no guarda ninguna clave.
class ApiConfig {
  ApiConfig._();

  /// Backend FastAPI de inventario (usuarios y productos).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Servidor propio del asistente de IA (`asistente-server/`).
  static const String asistenteUrl = String.fromEnvironment(
    'LLM_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
