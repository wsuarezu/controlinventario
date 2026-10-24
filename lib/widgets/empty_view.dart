import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado vacío: la carga terminó bien, pero no hay datos. Puede ofrecer una
/// acción (por ejemplo, «Agregar producto») para que no sea un callejón sin salida.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.mensaje = 'No hay nada por aquí todavía',
    this.icono = Icons.inventory_2_outlined,
    this.textoAccion,
    this.onAccion,
  });

  final String mensaje;
  final IconData icono;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            if (textoAccion != null && onAccion != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onAccion,
                icon: const Icon(Icons.add),
                label: Text(textoAccion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
