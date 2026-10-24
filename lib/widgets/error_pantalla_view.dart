import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lo que se ve cuando una pantalla falla al construirse, en lugar de la
/// pantalla roja. No usa `Theme` ni `Scaffold` a propósito: puede aparecer en
/// cualquier punto del árbol, incluso fuera de `MaterialApp`, y no debe fallar.
class ErrorPantallaView extends StatelessWidget {
  const ErrorPantallaView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Color(0xFFF5F7F6),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_circle_outlined, size: 56, color: Color(0xFF607D8B)),
                  SizedBox(height: 12),
                  Text(
                    'Esta pantalla tuvo un problema',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF263238),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ya lo registramos. Vuelve atrás e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF455A64),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
