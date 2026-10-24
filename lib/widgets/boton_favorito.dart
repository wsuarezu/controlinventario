import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favoritos_controller.dart';
import '../theme/app_theme.dart';

/// Estrella para marcar o desmarcar un producto como favorito.
class BotonFavorito extends StatelessWidget {
  const BotonFavorito({super.key, required this.productoId, this.colorInactivo});

  final int productoId;

  /// Color de la estrella vacía (en la AppBar conviene blanco).
  final Color? colorInactivo;

  @override
  Widget build(BuildContext context) {
    final favoritos = Get.find<FavoritosController>();
    return Obx(() {
      final activo = favoritos.esFavorito(productoId);
      return IconButton(
        tooltip: activo ? 'Quitar de favoritos' : 'Agregar a favoritos',
        icon: Icon(
          activo ? Icons.star : Icons.star_border,
          color: activo ? AppTheme.ambar : colorInactivo,
        ),
        onPressed: () => favoritos.alternar(productoId),
      );
    });
  }
}
