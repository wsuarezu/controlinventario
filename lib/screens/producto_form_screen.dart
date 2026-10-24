import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/productos_controller.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Formulario para crear o editar un producto. Al editar, la cantidad no se
/// cambia aquí: el stock solo se mueve con entradas y salidas (detalle).
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  /// null = crear; con valor = editar ese producto.
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductosController _c = Get.find<ProductosController>();
  late final TextEditingController _nombre;
  late final TextEditingController _cantidad;
  late final TextEditingController _minima;
  String _error = '';

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _cantidad = TextEditingController(text: p == null ? '' : '${p.cantidad}');
    _minima = TextEditingController(text: p == null ? '' : '${p.cantidadMinima}');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cantidad.dispose();
    _minima.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final nombre = _nombre.text.trim();
    final minima = int.parse(_minima.text);

    final error = _editando
        ? await _c.actualizar(widget.producto!.id, nombre: nombre, cantidadMinima: minima)
        : await _c.crear(
            nombre: nombre,
            cantidad: int.parse(_cantidad.text),
            cantidadMinima: minima,
          );

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editando ? 'Producto actualizado' : 'Producto agregado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar producto' : 'Nuevo producto')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => Validadores.requerido(v, campo: 'el nombre'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_editando) ...[
                _CampoEntero(
                  controller: _cantidad,
                  etiqueta: 'Cantidad inicial',
                  icono: Icons.numbers,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _CampoEntero(
                controller: _minima,
                etiqueta: 'Cantidad mínima',
                ayuda: 'Por debajo de este número, el producto aparece «Por reponer»',
                icono: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tema.colorScheme.error),
                  ),
                ),
              Obx(
                () => ElevatedButton.icon(
                  onPressed: _c.guardando.value ? null : _guardar,
                  icon: _c.guardando.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_editando ? 'Guardar cambios' : 'Agregar producto'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo numérico de enteros >= 0.
class _CampoEntero extends StatelessWidget {
  const _CampoEntero({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    this.ayuda,
  });

  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        helperMaxLines: 2,
        prefixIcon: Icon(icono),
      ),
      validator: Validadores.enteroNoNegativo,
    );
  }
}
