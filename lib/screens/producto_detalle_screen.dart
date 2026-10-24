import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/productos_controller.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../widgets/empty_view.dart';
import 'producto_form_screen.dart';

/// Detalle de un producto: registrar entradas y salidas de stock, editar y
/// eliminar. Lee el producto del controlador, así refleja cada cambio.
class ProductoDetalleScreen extends StatelessWidget {
  const ProductoDetalleScreen({super.key, required this.productoId});

  final int productoId;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductosController>();
    return Obx(() {
      final producto = c.porId(productoId);
      if (producto == null) {
        // Se eliminó (aquí o en otro dispositivo): salida clara, no pantalla vacía.
        return Scaffold(
          appBar: AppBar(title: const Text('Producto')),
          body: EmptyView(
            icono: Icons.inventory_2_outlined,
            mensaje: 'Este producto ya no existe.',
            textoAccion: 'Volver a la lista',
            onAccion: () => Navigator.of(context).pop(),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Producto'),
          actions: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Get.to(() => ProductoFormScreen(producto: producto)),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: c.guardando.value ? null : () => _eliminar(context, c, producto),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Resumen(producto: producto),
            const SizedBox(height: AppSpacing.lg),
            Text('Movimiento de stock', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: c.guardando.value
                        ? null
                        : () => _pedirMovimiento(context, c, producto, entrada: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('Salida'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: c.guardando.value
                        ? null
                        : () => _pedirMovimiento(context, c, producto, entrada: true),
                    icon: const Icon(Icons.add),
                    label: const Text('Entrada'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El stock no puede quedar por debajo de la cantidad mínima.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (c.guardando.value) ...[
              const SizedBox(height: AppSpacing.lg),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      );
    });
  }

  Future<void> _pedirMovimiento(
    BuildContext context,
    ProductosController c,
    Producto producto, {
    required bool entrada,
  }) async {
    final unidades = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoMovimiento(entrada: entrada),
    );
    if (unidades == null || !context.mounted) return;
    final error = await c.ajustar(producto.id, entrada ? unidades : -unidades);
    if (!context.mounted) return;
    _avisar(
      context,
      error ?? (entrada ? 'Entrada de $unidades registrada' : 'Salida de $unidades registrada'),
      esError: error != null,
    );
  }

  Future<void> _eliminar(BuildContext context, ProductosController c, Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar «${producto.nombre}»? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final error = await c.eliminar(producto.id);
    if (error != null) {
      if (context.mounted) _avisar(context, error, esError: true);
      return;
    }
    navegador.pop();
    messenger.showSnackBar(SnackBar(content: Text('«${producto.nombre}» eliminado')));
  }

  void _avisar(BuildContext context, String mensaje, {required bool esError}) {
    final tema = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: esError ? tema.colorScheme.error : null),
      );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = producto.necesitaReponer ? AppTheme.alertaStock : tema.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.nombre, style: tema.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Dato(etiqueta: 'En stock', valor: '${producto.cantidad}', color: color),
                const SizedBox(width: AppSpacing.xl),
                _Dato(etiqueta: 'Mínimo', valor: '${producto.cantidadMinima}'),
              ],
            ),
            if (producto.necesitaReponer) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.alertaStock),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Por reponer: el stock está en el mínimo o por debajo.',
                      style: TextStyle(color: AppTheme.alertaStock),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, this.color});

  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: tema.textTheme.bodySmall),
        Text(
          valor,
          style: tema.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Pide cuántas unidades entran o salen. Devuelve el número (> 0) o null.
class _DialogoMovimiento extends StatefulWidget {
  const _DialogoMovimiento({required this.entrada});

  final bool entrada;

  @override
  State<_DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends State<_DialogoMovimiento> {
  final _formKey = GlobalKey<FormState>();
  final _unidades = TextEditingController(text: '1');

  @override
  void dispose() {
    _unidades.dispose();
    super.dispose();
  }

  void _aceptar() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, int.parse(_unidades.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entrada ? 'Registrar entrada' : 'Registrar salida'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _unidades,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Unidades'),
          validator: Validadores.enteroPositivo,
          onFieldSubmitted: (_) => _aceptar(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _aceptar, child: const Text('Aceptar')),
      ],
    );
  }
}
