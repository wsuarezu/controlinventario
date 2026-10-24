import 'dart:convert';

import 'package:get/get.dart';

import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/secure_token_storage.dart';

/// Estado de la sesión para toda la app. `usuario` es null cuando no hay
/// sesión; la pantalla raíz (`PuertaSesion`) reacciona a ese cambio.
class AuthController extends GetxController {
  AuthController({ApiClient? api, AuthService? servicio, SecureTokenStorage? almacen})
    : _api = api ?? Get.find<ApiClient>(),
      _almacen = almacen ?? SecureTokenStorage() {
    _servicio = servicio ?? AuthService(_api);
  }

  final ApiClient _api;
  final SecureTokenStorage _almacen;
  late final AuthService _servicio;

  static const mensajeCaducada = 'Tu sesión caducó. Inicia sesión de nuevo.';

  final Rxn<Usuario> usuario = Rxn<Usuario>();
  final RxBool cargando = false.obs;

  /// true mientras se comprueba el token guardado al abrir la app.
  final RxBool restaurando = true.obs;

  /// Error del último intento de registro o inicio de sesión.
  final RxString mensajeError = ''.obs;

  /// Aviso que se muestra en el login (por ejemplo, «tu sesión caducó»).
  final RxString avisoSesion = ''.obs;

  /// Tareas que otros controladores registran para limpiar sus datos al
  /// cerrar sesión (caché, favoritos…), sin que este controlador los conozca.
  final List<Future<void> Function()> _alCerrarSesion = [];

  bool get estaAutenticado => usuario.value != null;

  void registrarLimpieza(Future<void> Function() tarea) => _alCerrarSesion.add(tarea);

  @override
  void onInit() {
    super.onInit();
    _api.alSesionCaducada = sesionCaducada;
    restaurarSesion();
  }

  /// Crea la cuenta y, si sale bien, inicia sesión con ella.
  Future<void> registrar(String email, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _servicio.registrar(email, password);
      await _entrar(email, password);
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _entrar(email, password);
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  /// Pide el token, lo guarda en memoria (para el interceptor) y en el
  /// almacenamiento seguro, y carga el usuario.
  Future<void> _entrar(String email, String password) async {
    final token = await _servicio.iniciarSesion(email, password);
    _api.token = token;
    await _almacen.guardar(token);
    await _cargarUsuario();
    avisoSesion.value = '';
  }

  /// GET /usuarios/me; guarda id y correo para poder abrir la app sin conexión.
  Future<void> _cargarUsuario() async {
    final actual = await _servicio.usuarioActual();
    await _almacen.guardarUsuario(jsonEncode(actual.toJson()));
    usuario.value = actual;
  }

  /// Al abrir la app: si hay token guardado, comprueba con GET /usuarios/me
  /// que siga siendo válido. Un 401 lo borra. Sin conexión se conserva (puede
  /// seguir siendo válido) y se entra con el usuario guardado, para mostrar
  /// la caché offline.
  Future<void> restaurarSesion() async {
    restaurando.value = true;
    try {
      final guardado = await _almacen.leer();
      if (guardado == null) return;
      _api.token = guardado;
      await _cargarUsuario();
    } on ApiException catch (e) {
      if (e.esNoAutorizado) {
        await cerrarSesion();
        avisoSesion.value = mensajeCaducada;
      } else {
        avisoSesion.value = e.mensaje;
        final json = e.sinConexion ? await _almacen.leerUsuario() : null;
        if (json != null) {
          usuario.value = Usuario.fromJson(jsonDecode(json) as Map<String, dynamic>);
        }
      }
    } finally {
      restaurando.value = false;
    }
  }

  /// Lo llama `ApiClient` cuando el servidor responde 401 fuera del login.
  Future<void> sesionCaducada() async {
    if (!estaAutenticado) return;
    await cerrarSesion();
    avisoSesion.value = mensajeCaducada;
    // Si había pantallas encima (formularios), se vuelve a la raíz.
    if (Get.key.currentState != null) Get.until((ruta) => ruta.isFirst);
  }

  /// Borra el token (memoria y almacenamiento seguro) y los datos locales del usuario.
  Future<void> cerrarSesion() async {
    for (final tarea in _alCerrarSesion) {
      await tarea();
    }
    await _almacen.borrar();
    _api.token = null;
    usuario.value = null;
  }

  /// Solo práctica (menú de pruebas): la siguiente petición responderá 401.
  void invalidarTokenParaPruebas() => _api.token = 'token-invalido';
}
