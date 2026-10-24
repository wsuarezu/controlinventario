import 'package:hive/hive.dart';

/// Productos favoritos en Hive: por cada usuario (clave = su id) se guarda la
/// lista de ids marcados. Sobrevive al cierre de la app y al cierre de sesión.
class FavoritosService {
  FavoritosService([Box<dynamic>? caja]) : _caja = caja ?? Hive.box(nombreCaja);

  static const nombreCaja = 'favoritos';
  final Box<dynamic> _caja;

  Set<int> leer(int usuarioId) =>
      ((_caja.get('$usuarioId') as List?) ?? const []).map((e) => (e as num).toInt()).toSet();

  Future<void> guardar(int usuarioId, Set<int> ids) => _caja.put('$usuarioId', ids.toList());
}
