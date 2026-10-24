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

  /// POST /productos/ → 201 con el producto creado. Reglas de negocio → 400.
  Future<Producto> crear({
    required String nombre,
    required int cantidad,
    required int cantidadMinima,
  }) async {
    final r = await _api.post(
      '/productos/',
      data: {'nombre': nombre, 'cantidad': cantidad, 'cantidad_minima': cantidadMinima},
    );
    return Producto.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// PATCH /productos/{id}: solo nombre y mínimo; la cantidad cambia con [ajustar].
  Future<Producto> actualizar(int id, {String? nombre, int? cantidadMinima}) async {
    final r = await _api.patch(
      '/productos/$id',
      data: {'nombre': ?nombre, 'cantidad_minima': ?cantidadMinima},
    );
    return Producto.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// POST /productos/{id}/ajustar con `delta` positivo (entrada) o negativo (salida).
  Future<Producto> ajustar(int id, int delta) async {
    final r = await _api.post('/productos/$id/ajustar', data: {'delta': delta});
    return Producto.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// DELETE /productos/{id} → 204 sin cuerpo.
  Future<void> eliminar(int id) => _api.delete('/productos/$id');

  /// Solo práctica (menú de pruebas): envía tipos inválidos para provocar un 422.
  Future<void> enviarDatosInvalidos() => _api.post(
    '/productos/',
    data: {'nombre': 'Prueba', 'cantidad': 'muchos', 'cantidad_minima': -1.5},
  );
}
