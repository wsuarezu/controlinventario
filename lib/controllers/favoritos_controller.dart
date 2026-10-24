import 'package:get/get.dart';

import '../services/favoritos_service.dart';
import 'auth_controller.dart';

/// Ids de los productos favoritos del usuario actual, compartidos por la
/// lista, el detalle y la pestaña Favoritos. Se cargan de Hive al iniciar sesión.
class FavoritosController extends GetxController {
  FavoritosController({FavoritosService? servicio, AuthController? auth})
    : _servicio = servicio ?? FavoritosService(),
      _auth = auth ?? Get.find<AuthController>();

  final FavoritosService _servicio;
  final AuthController _auth;

  final RxSet<int> ids = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.usuario, (_) => _cargar());
    _cargar();
  }

  void _cargar() {
    final usuario = _auth.usuario.value;
    usuario == null ? ids.clear() : ids.assignAll(_servicio.leer(usuario.id));
  }

  bool esFavorito(int productoId) => ids.contains(productoId);

  Future<void> alternar(int productoId) async {
    final usuario = _auth.usuario.value;
    if (usuario == null) return;
    if (!ids.remove(productoId)) ids.add(productoId);
    await _servicio.guardar(usuario.id, ids.toSet());
  }
}
