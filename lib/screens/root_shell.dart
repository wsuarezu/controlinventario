import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_view.dart';
import 'login_screen.dart';

/// Raíz de la app: mientras se comprueba el token muestra la carga; sin
/// sesión, el login; con sesión, la app. Al cerrar sesión o caducar el token,
/// `usuario` pasa a null y esta puerta vuelve sola al login.
class PuertaSesion extends StatelessWidget {
  const PuertaSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.restaurando.value) {
        return const Scaffold(body: LoadingView(mensaje: 'Comprobando tu sesión...'));
      }
      return auth.estaAutenticado ? const RootShell() : const LoginScreen();
    });
  }
}

/// Contenedor con la barra de navegación inferior. El índice de la pestaña es
/// estado local de esta pantalla, por eso usa `setState`.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _indice = 0;

  static const _titulos = ['Inventario', 'Favoritos', 'Asistente'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titulos[_indice]), actions: const [MenuCuenta()]),
      body: switch (_indice) {
        0 => const EmptyView(mensaje: 'Aquí verás tus productos.'),
        1 => const EmptyView(
          mensaje: 'Aquí verás tus productos favoritos.',
          icono: Icons.star_border,
        ),
        _ => const EmptyView(
          mensaje: 'Aquí podrás consultar al asistente.',
          icono: Icons.auto_awesome,
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.star_border), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Asistente'),
        ],
      ),
    );
  }
}

/// Menú de la cuenta en la AppBar: muestra el correo y permite cerrar sesión.
class MenuCuenta extends StatelessWidget {
  const MenuCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (opcion) async {
        if (opcion == 'salir') await _confirmarSalida(context, auth);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(enabled: false, child: Text(auth.usuario.value?.email ?? '')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'salir',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarSalida(BuildContext context, AuthController auth) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Se borrarán los datos guardados en este teléfono para tu cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar == true) await auth.cerrarSesion();
  }
}
