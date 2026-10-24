import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/productos_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/boton_favorito.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/producto_tile.dart';
import 'producto_detalle_screen.dart';
import 'producto_form_screen.dart';

/// Lista del inventario con búsqueda, filtro «Por reponer» y pull-to-refresh.
/// Cubre los estados de carga, error y vacío (sin productos o sin resultados).
class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductosController>();
    return Obx(() {
      if (c.cargando.value && c.productos.isEmpty) {
        return const LoadingView(mensaje: 'Cargando productos...');
      }
      if (c.error.value.isNotEmpty && c.productos.isEmpty) {
        return ErrorView(mensaje: c.error.value, onReintentar: c.cargar);
      }
      if (c.productos.isEmpty) {
        return RefreshIndicator(
          onRefresh: c.cargar,
          child: ListView(
            children: [
              const SizedBox(height: 120),
              EmptyView(
                mensaje: 'Aún no tienes productos en tu inventario.',
                textoAccion: 'Agregar producto',
                onAccion: () => Get.to(() => const ProductoFormScreen()),
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          _Encabezado(c: c),
          if (c.guardadoEl.value != null)
            _Aviso(
              icono: Icons.cloud_off,
              mensaje:
                  'Sin conexión. Mostrando los datos guardados el ${fechaCorta(c.guardadoEl.value!)}. '
                  'Desliza hacia abajo para reintentar.',
            ),
          if (c.error.value.isNotEmpty) _Aviso(icono: Icons.error_outline, mensaje: c.error.value),
          Expanded(child: _Lista(c: c)),
        ],
      );
    });
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.c});

  final ProductosController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        children: [
          TextField(
            onChanged: (texto) => c.busqueda.value = texto,
            decoration: const InputDecoration(
              hintText: 'Buscar producto',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Row(
              children: [
                ChoiceChip(
                  label: Text('Todos (${c.productos.length})'),
                  selected: c.filtro.value == FiltroProductos.todos,
                  onSelected: (_) => c.filtro.value = FiltroProductos.todos,
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text('Por reponer (${c.totalPorReponer})'),
                  selected: c.filtro.value == FiltroProductos.porReponer,
                  onSelected: (_) => c.filtro.value = FiltroProductos.porReponer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.c});

  final ProductosController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visibles = c.visibles;
      return RefreshIndicator(
        onRefresh: c.cargar,
        child: visibles.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 60),
                  EmptyView(
                    icono: Icons.search_off,
                    mensaje: c.filtro.value == FiltroProductos.porReponer
                        ? 'Ningún producto necesita reposición.'
                        : 'No hay productos que coincidan con la búsqueda.',
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 88),
                itemCount: visibles.length,
                itemBuilder: (_, i) => ProductoTile(
                  producto: visibles[i],
                  trailing: BotonFavorito(productoId: visibles[i].id),
                  onTap: () => Get.to(() => ProductoDetalleScreen(productoId: visibles[i].id)),
                ),
              ),
      );
    });
  }
}

/// Aviso sobre la lista (datos offline o error al recargar): los datos ya
/// mostrados no se borran, se avisa encima.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.mensaje});

  final IconData icono;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tema.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: tema.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: tema.colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
