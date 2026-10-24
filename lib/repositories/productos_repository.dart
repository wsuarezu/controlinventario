import '../models/producto.dart';
import '../services/productos_api_service.dart';

/// Punto único de acceso a los productos para el controlador. Hoy solo
/// consulta el backend; aquí se suma la caché local sin cambiar las pantallas.
class ProductosRepository {
  ProductosRepository(this._remoto);

  final ProductosApiService _remoto;

  Future<List<Producto>> obtenerTodos() async {
    final productos = await _remoto.listar();
    productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return productos;
  }
}
