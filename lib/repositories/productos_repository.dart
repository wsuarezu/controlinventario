import '../models/producto.dart';
import '../services/api_client.dart';
import '../services/cache_productos_service.dart';
import '../services/productos_api_service.dart';

/// Lista obtenida por el repositorio. `guardadoEl` tiene valor solo cuando
/// viene de la caché offline (el backend no respondió).
class ResultadoProductos {
  const ResultadoProductos(this.productos, {this.guardadoEl});

  final List<Producto> productos;
  final DateTime? guardadoEl;

  bool get desdeCache => guardadoEl != null;
}

/// Punto único de acceso a los productos para el controlador: combina el
/// backend con la caché local, sin que las pantallas sepan de dónde vienen.
class ProductosRepository {
  /// Sin [_cache] solo consulta el backend. [reloj] permite fijar la hora en pruebas.
  ProductosRepository(this._remoto, [this._cache, DateTime Function()? reloj])
    : _reloj = reloj ?? DateTime.now;

  final ProductosApiService _remoto;
  final CacheProductosService? _cache;
  final DateTime Function() _reloj;

  /// Pide la lista al backend y la guarda en caché. Si el backend no responde
  /// (sin red, apagado o timeout) y hay copia, devuelve la copia. Cualquier
  /// otro error (401, 5xx…) se propaga: la copia no debe ocultarlo.
  Future<ResultadoProductos> obtenerTodos(int usuarioId) async {
    try {
      final productos = await _remoto.listar();
      _ordenar(productos);
      await _cache?.guardar(usuarioId, productos, _reloj());
      return ResultadoProductos(productos);
    } on ApiException catch (e) {
      final copia = e.sinConexion ? _cache?.leer(usuarioId) : null;
      if (copia == null) rethrow;
      return ResultadoProductos(copia.productos, guardadoEl: copia.guardadoEl);
    }
  }

  /// Tras un cambio confirmado por el backend, la caché refleja la lista actual.
  Future<void> actualizarCache(int usuarioId, List<Producto> productos) async =>
      _cache?.guardar(usuarioId, productos, _reloj());

  Future<void> borrarCache(int usuarioId) async => _cache?.borrar(usuarioId);

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

  static void _ordenar(List<Producto> productos) =>
      productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
}
