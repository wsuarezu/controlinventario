import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado de error con botón «Reintentar», para que la persona nunca quede
/// atrapada en una pantalla sin salida.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: tema.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(mensaje, textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
