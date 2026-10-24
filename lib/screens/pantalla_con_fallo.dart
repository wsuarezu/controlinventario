import 'package:flutter/material.dart';

/// Solo práctica (menú de pruebas): una pantalla que falla al construirse,
/// para comprobar que se ve `ErrorPantallaView` en lugar de la pantalla roja.
class PantallaConFallo extends StatelessWidget {
  const PantallaConFallo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla con fallo')),
      body: Builder(builder: (_) => throw StateError('Fallo de prueba al construir la pantalla')),
    );
  }
}
