import 'package:hive/hive.dart';

import '../models/producto.dart';

/// Copia local de la última lista recibida del backend.
class CacheProductos {
  const CacheProductos({required this.productos, required this.guardadoEl});

  final List<Producto> productos;
  final DateTime guardadoEl;
}

/// Caché offline del inventario en Hive, una entrada por usuario (clave =
/// id del usuario), para que una cuenta nunca vea la copia de otra.
class CacheProductosService {
  CacheProductosService([Box<dynamic>? caja]) : _caja = caja ?? Hive.box(nombreCaja);

  static const nombreCaja = 'cache_productos';
  final Box<dynamic> _caja;

  Future<void> guardar(int usuarioId, List<Producto> productos, DateTime fecha) =>
      _caja.put('$usuarioId', {
        'guardado_el': fecha.toIso8601String(),
        'productos': productos.map((p) => p.toJson()).toList(),
      });

  CacheProductos? leer(int usuarioId) {
    final datos = _caja.get('$usuarioId');
    if (datos is! Map) return null;
    final lista = (datos['productos'] as List? ?? [])
        .map((e) => Producto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CacheProductos(
      productos: lista,
      guardadoEl: DateTime.parse(datos['guardado_el'] as String),
    );
  }

  Future<void> borrar(int usuarioId) => _caja.delete('$usuarioId');
}
