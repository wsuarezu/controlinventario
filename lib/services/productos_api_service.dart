import '../models/producto.dart';
import 'api_client.dart';

/// Llamadas HTTP de productos. Las rutas llevan barra final: sin ella el
/// backend responde 307 (redirección).
class ProductosApiService {
  ProductosApiService(this._api);

  final ApiClient _api;

  /// El backend pagina con `limit` = 20 por defecto y no devuelve el total;
  /// para un inventario pequeño se pide hasta 100 de una vez.
  Future<List<Producto>> listar() async {
    final r = await _api.get('/productos/', query: {'limit': 100});
    return (r.data as List)
        .map((e) => Producto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
