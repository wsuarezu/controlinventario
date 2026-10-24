/// Producto del inventario, tal como lo devuelve el backend (`/productos/`).
class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.cantidadMinima,
  });

  final int id;
  final String nombre;
  final int cantidad;
  final int cantidadMinima;

  /// En el mínimo o por debajo: conviene reponer. (El backend no deja bajar
  /// de la mínima con un ajuste, pero un producto puede crearse ya por debajo.)
  bool get necesitaReponer => cantidad <= cantidadMinima;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: (json['id'] as num).toInt(),
    nombre: json['nombre'] as String,
    cantidad: (json['cantidad'] as num).toInt(),
    cantidadMinima: (json['cantidad_minima'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'cantidad': cantidad,
    'cantidad_minima': cantidadMinima,
  };
}
