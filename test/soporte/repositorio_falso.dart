import 'package:controlinventario/models/producto.dart';
import 'package:controlinventario/repositories/productos_repository.dart';
import 'package:controlinventario/services/api_client.dart';

/// Repositorio en memoria con las mismas reglas que el backend, para probar
/// controlador y pantallas sin HTTP (dio no avanza en el reloj simulado).
class RepositorioFalso implements ProductosRepository {
  RepositorioFalso(List<Producto> iniciales) : productos = List.of(iniciales);

  List<Producto> productos;

  /// Si tiene valor, la próxima operación (de cualquier tipo) falla con él.
  ApiException? error;

  int _siguienteId = 100;

  void _fallarSiCorresponde() {
    final e = error;
    if (e != null) throw e;
  }

  Producto _buscar(int id) => productos.firstWhere(
    (p) => p.id == id,
    orElse: () =>
        throw ApiException('El producto ya no existe. Actualiza la lista.', statusCode: 404),
  );

  Producto _copia(Producto p, {String? nombre, int? cantidad, int? cantidadMinima}) => Producto(
    id: p.id,
    nombre: nombre ?? p.nombre,
    cantidad: cantidad ?? p.cantidad,
    cantidadMinima: cantidadMinima ?? p.cantidadMinima,
  );

  void _guardar(Producto p) {
    productos = [for (final x in productos) x.id == p.id ? p : x];
  }

  @override
  Future<List<Producto>> obtenerTodos() async {
    _fallarSiCorresponde();
    return List.of(productos);
  }

  @override
  Future<Producto> crear({
    required String nombre,
    required int cantidad,
    required int cantidadMinima,
  }) async {
    _fallarSiCorresponde();
    final p = Producto(
      id: _siguienteId++,
      nombre: nombre,
      cantidad: cantidad,
      cantidadMinima: cantidadMinima,
    );
    productos = [...productos, p];
    return p;
  }

  @override
  Future<Producto> actualizar(int id, {String? nombre, int? cantidadMinima}) async {
    _fallarSiCorresponde();
    final p = _copia(_buscar(id), nombre: nombre, cantidadMinima: cantidadMinima);
    _guardar(p);
    return p;
  }

  @override
  Future<Producto> ajustar(int id, int delta) async {
    _fallarSiCorresponde();
    final actual = _buscar(id);
    final nueva = actual.cantidad + delta;
    if (nueva < actual.cantidadMinima) {
      throw ApiException('El ajuste dejaría la cantidad por debajo del mínimo', statusCode: 400);
    }
    final p = _copia(actual, cantidad: nueva);
    _guardar(p);
    return p;
  }

  @override
  Future<void> eliminar(int id) async {
    _fallarSiCorresponde();
    _buscar(id);
    productos = productos.where((p) => p.id != id).toList();
  }

  @override
  Future<void> enviarDatosInvalidos() async => throw ApiException(
    'Datos inválidos — cantidad: Input should be a valid integer',
    statusCode: 422,
  );
}
