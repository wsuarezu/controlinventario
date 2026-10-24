import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../theme/app_theme.dart';

/// Fila de un producto: nombre, stock y mínimo, con alerta si hay que reponer.
class ProductoTile extends StatelessWidget {
  const ProductoTile({super.key, required this.producto, this.onTap, this.trailing});

  final Producto producto;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final alerta = producto.necesitaReponer;
    final colorStock = alerta ? AppTheme.alertaStock : tema.colorScheme.primary;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorStock.withValues(alpha: 0.15),
          foregroundColor: colorStock,
          child: Text('${producto.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text('Mínimo: ${producto.cantidadMinima}'),
            if (alerta) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.alertaStock),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Por reponer',
                style: TextStyle(color: AppTheme.alertaStock, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
