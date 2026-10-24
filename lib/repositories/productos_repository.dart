import '../models/producto.dart';
import '../services/productos_api_service.dart';

/// Punto único de acceso a los productos para el controlador. Hoy solo
/// habla con el backend; aquí se suma la caché local sin cambiar las pantallas.
class ProductosRepository {
  ProductosRepository(this._remoto);

  final ProductosApiService _remoto;

  Future<List<Producto>> obtenerTodos() async {
    final productos = await _remoto.listar();
    productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return productos;
  }

  Future<Producto> crear({
    required String nombre,
    required int cantidad,
    required int cantidadMinima,
  }) => _remoto.crear(nombre: nombre, cantidad: cantidad, cantidadMinima: cantidadMinima);

  Future<Producto> actualizar(int id, {String? nombre, int? cantidadMinima}) =>
      _remoto.actualizar(id, nombre: nombre, cantidadMinima: cantidadMinima);

  Future<Producto> ajustar(int id, int delta) => _remoto.ajustar(id, delta);

  Future<void> eliminar(int id) => _remoto.eliminar(id);

  Future<void> enviarDatosInvalidos() => _remoto.enviarDatosInvalidos();
}
