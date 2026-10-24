import 'dart:async';

import 'package:get/get.dart';

import '../models/producto.dart';
import '../repositories/productos_repository.dart';
import '../services/api_client.dart';
import '../services/cache_productos_service.dart';
import '../services/productos_api_service.dart';
import 'auth_controller.dart';

/// Filtros de la lista de productos.
enum FiltroProductos { todos, porReponer }

/// Estado de la lista de productos, compartido por las pantallas que la usan
/// (lista, formulario, asistente). Carga sola al iniciar sesión y se vacía al
/// cerrarla.
class ProductosController extends GetxController {
  ProductosController({ProductosRepository? repositorio, AuthController? auth})
    : _repo =
          repositorio ??
          ProductosRepository(ProductosApiService(Get.find<ApiClient>()), CacheProductosService()),
      _auth = auth ?? Get.find<AuthController>();

  final ProductosRepository _repo;
  final AuthController _auth;

  final RxList<Producto> productos = <Producto>[].obs;
  final RxBool cargando = false.obs;

  /// Mensaje del último error de carga; vacío si no hubo error.
  final RxString error = ''.obs;

  /// Fecha de la copia offline que se está mostrando; null si los datos
  /// vienen del backend.
  final Rxn<DateTime> guardadoEl = Rxn<DateTime>();

  /// true mientras se guarda un cambio (crear, editar, ajustar o eliminar).
  final RxBool guardando = false.obs;

  final Rx<FiltroProductos> filtro = FiltroProductos.todos.obs;
  final RxString busqueda = ''.obs;

  /// Lo que se muestra: aplica búsqueda y filtro sobre la lista completa.
  List<Producto> get visibles {
    final texto = busqueda.value.trim().toLowerCase();
    return productos.where((p) {
      if (filtro.value == FiltroProductos.porReponer && !p.necesitaReponer) return false;
      return texto.isEmpty || p.nombre.toLowerCase().contains(texto);
    }).toList();
  }

  int get totalPorReponer => productos.where((p) => p.necesitaReponer).length;

  @override
  void onInit() {
    super.onInit();
    _auth.registrarLimpieza(limpiar);
    // Carga al iniciar sesión (o al restaurarla) y no antes.
    ever(_auth.usuario, (usuario) {
      if (usuario != null) cargar();
    });
    if (_auth.estaAutenticado) cargar();
  }

  int? get _usuarioId => _auth.usuario.value?.id;

  Future<void> cargar() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;
    cargando.value = true;
    error.value = '';
    try {
      final resultado = await _repo.obtenerTodos(usuarioId);
      productos.assignAll(resultado.productos);
      guardadoEl.value = resultado.guardadoEl;
    } on ApiException catch (e) {
      // Un 401 ya lo maneja AuthController (vuelve al login).
      if (!e.esNoAutorizado) error.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Producto? porId(int id) => productos.firstWhereOrNull((p) => p.id == id);

  // Cada operación devuelve null si salió bien, o el mensaje para mostrar.

  Future<String?> crear({
    required String nombre,
    required int cantidad,
    required int cantidadMinima,
  }) => _guardar(() async {
    final nuevo = await _repo.crear(
      nombre: nombre,
      cantidad: cantidad,
      cantidadMinima: cantidadMinima,
    );
    productos.add(nuevo);
    _ordenar();
  });

  Future<String?> actualizar(int id, {String? nombre, int? cantidadMinima}) => _guardar(() async {
    _reemplazar(await _repo.actualizar(id, nombre: nombre, cantidadMinima: cantidadMinima));
    _ordenar();
  });

  /// `delta` positivo = entrada de mercadería; negativo = salida.
  Future<String?> ajustar(int id, int delta) =>
      _guardar(() async => _reemplazar(await _repo.ajustar(id, delta)));

  Future<String?> eliminar(int id) => _guardar(() async {
    await _repo.eliminar(id);
    productos.removeWhere((p) => p.id == id);
  });

  /// Solo práctica (menú de pruebas): devuelve el mensaje del 422.
  Future<String?> enviarDatosInvalidos() => _guardar(_repo.enviarDatosInvalidos);

  Future<String?> _guardar(Future<void> Function() operacion) async {
    guardando.value = true;
    try {
      await operacion();
      guardadoEl.value = null; // el backend respondió: ya no son datos offline
      final usuarioId = _usuarioId;
      if (usuarioId != null) await _repo.actualizarCache(usuarioId, productos);
      return null;
    } on ApiException catch (e) {
      // 404: otro dispositivo lo borró; se recarga para no mostrar datos viejos.
      if (e.statusCode == 404) unawaited(cargar());
      return e.mensaje;
    } finally {
      guardando.value = false;
    }
  }

  void _reemplazar(Producto actualizado) {
    final i = productos.indexWhere((p) => p.id == actualizado.id);
    if (i >= 0) productos[i] = actualizado;
  }

  void _ordenar() =>
      productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  /// Al cerrar sesión: borra la copia offline de este usuario y vacía la lista.
  Future<void> limpiar() async {
    final usuarioId = _usuarioId;
    if (usuarioId != null) await _repo.borrarCache(usuarioId);
    guardadoEl.value = null;
    productos.clear();
    error.value = '';
    busqueda.value = '';
    filtro.value = FiltroProductos.todos;
  }
}
