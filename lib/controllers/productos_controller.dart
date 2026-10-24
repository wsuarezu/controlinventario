import 'package:get/get.dart';

import '../models/producto.dart';
import '../repositories/productos_repository.dart';
import '../services/api_client.dart';
import '../services/productos_api_service.dart';
import 'auth_controller.dart';

/// Filtros de la lista de productos.
enum FiltroProductos { todos, porReponer }

/// Estado de la lista de productos, compartido por las pantallas que la usan
/// (lista, formulario, asistente). Carga sola al iniciar sesión y se vacía al
/// cerrarla.
class ProductosController extends GetxController {
  ProductosController({ProductosRepository? repositorio, AuthController? auth})
    : _repo = repositorio ?? ProductosRepository(ProductosApiService(Get.find<ApiClient>())),
      _auth = auth ?? Get.find<AuthController>();

  final ProductosRepository _repo;
  final AuthController _auth;

  final RxList<Producto> productos = <Producto>[].obs;
  final RxBool cargando = false.obs;

  /// Mensaje del último error de carga; vacío si no hubo error.
  final RxString error = ''.obs;

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

  Future<void> cargar() async {
    cargando.value = true;
    error.value = '';
    try {
      productos.assignAll(await _repo.obtenerTodos());
    } on ApiException catch (e) {
      // Un 401 ya lo maneja AuthController (vuelve al login).
      if (!e.esNoAutorizado) error.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> limpiar() async {
    productos.clear();
    error.value = '';
    busqueda.value = '';
    filtro.value = FiltroProductos.todos;
  }
}
