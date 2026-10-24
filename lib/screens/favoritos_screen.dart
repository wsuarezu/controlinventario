import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favoritos_controller.dart';
import '../controllers/productos_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/boton_favorito.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/producto_tile.dart';
import 'producto_detalle_screen.dart';

/// Productos marcados con estrella. Los ids vienen de Hive; los datos, de la
/// misma lista que la pestaña Inventario (backend o caché).
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productos = Get.find<ProductosController>();
    final favoritos = Get.find<FavoritosController>();
    return Obx(() {
      if (productos.cargando.value && productos.productos.isEmpty) {
        return const LoadingView(mensaje: 'Cargando favoritos...');
      }
      if (productos.error.value.isNotEmpty && productos.productos.isEmpty) {
        return ErrorView(mensaje: productos.error.value, onReintentar: productos.cargar);
      }
      final lista = productos.productos.where((p) => favoritos.ids.contains(p.id)).toList();
      if (lista.isEmpty) {
        return const EmptyView(
          icono: Icons.star_border,
          mensaje: 'Aún no tienes favoritos.\nToca la estrella de un producto en Inventario para tenerlo a mano aquí.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: lista.length,
        itemBuilder: (_, i) => ProductoTile(
          producto: lista[i],
          trailing: BotonFavorito(productoId: lista[i].id),
          onTap: () => Get.to(() => ProductoDetalleScreen(productoId: lista[i].id)),
        ),
      );
    });
  }
}
