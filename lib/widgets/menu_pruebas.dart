import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/productos_controller.dart';
import '../screens/pantalla_con_fallo.dart';
import '../utils/reporte_errores.dart';

enum _Prueba { invalidarToken, datosInvalidos, errorPantalla, errorAsincrono, verRegistro }

/// Menú «Pruebas de errores (solo práctica)». Está también en el APK de release
/// a propósito: permite a quien evalúa comprobar el manejo de errores sin tocar
/// código. El 400 se ve con acciones reales (correo repetido, salida bajo el
/// mínimo) y el 5xx o sin conexión, apagando el backend.
class MenuPruebas extends StatelessWidget {
  const MenuPruebas({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_Prueba>(
      tooltip: 'Pruebas de errores',
      icon: const Icon(Icons.bug_report_outlined),
      onSelected: (prueba) => _ejecutar(context, prueba),
      itemBuilder: (_) => const [
        PopupMenuItem(enabled: false, child: Text('Pruebas de errores (solo práctica)')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _Prueba.invalidarToken,
          child: _Opcion(Icons.key_off_outlined, 'Invalidar token', '401 → sesión caducada'),
        ),
        PopupMenuItem(
          value: _Prueba.datosInvalidos,
          child: _Opcion(Icons.rule, 'Enviar datos inválidos', '422 → campos inválidos'),
        ),
        PopupMenuItem(
          value: _Prueba.errorPantalla,
          child: _Opcion(Icons.broken_image_outlined, 'Error de pantalla', 'Sin pantalla roja'),
        ),
        PopupMenuItem(
          value: _Prueba.errorAsincrono,
          child: _Opcion(Icons.sync_problem, 'Error asíncrono', 'Captura global'),
        ),
        PopupMenuItem(
          value: _Prueba.verRegistro,
          child: _Opcion(Icons.receipt_long_outlined, 'Ver registro de errores', 'Sin tokens'),
        ),
      ],
    );
  }

  Future<void> _ejecutar(BuildContext context, _Prueba prueba) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (prueba) {
      case _Prueba.invalidarToken:
        // La siguiente petición lleva un token inválido: el backend responde 401,
        // ApiClient avisa y AuthController vuelve al login con el aviso.
        Get.find<AuthController>().invalidarTokenParaPruebas();
        await Get.find<ProductosController>().cargar();
      case _Prueba.datosInvalidos:
        final mensaje = await Get.find<ProductosController>().enviarDatosInvalidos();
        messenger.showSnackBar(
          SnackBar(content: Text(mensaje ?? 'El backend aceptó los datos (no se esperaba).')),
        );
      case _Prueba.errorPantalla:
        await Get.to(() => const PantallaConFallo());
      case _Prueba.errorAsincrono:
        // Un Future que falla sin que nadie lo espere. El texto incluye un token
        // falso para comprobar que el registro lo oculta.
        unawaited(
          Future<void>.delayed(
            Duration.zero,
            () => throw StateError('Fallo asíncrono de prueba con Bearer token.falso.123'),
          ),
        );
      case _Prueba.verRegistro:
        if (!context.mounted) return;
        await showDialog<void>(context: context, builder: (_) => const _DialogoRegistro());
    }
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion(this.icono, this.titulo, this.detalle);

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: Text(detalle),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _DialogoRegistro extends StatelessWidget {
  const _DialogoRegistro();

  @override
  Widget build(BuildContext context) {
    final registros = ReporteErrores.recientes.reversed.toList();
    return AlertDialog(
      title: const Text('Registro de errores'),
      content: SizedBox(
        width: double.maxFinite,
        child: registros.isEmpty
            ? const Text('No hay errores registrados.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: registros.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) =>
                    SelectableText(registros[i], style: Theme.of(context).textTheme.bodySmall),
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    );
  }
}
