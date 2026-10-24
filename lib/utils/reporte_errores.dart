import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/error_pantalla_view.dart';

/// Manejo de los errores que nadie esperaba. Conecta las tres vías por donde
/// se escapan (un widget que falla al construirse, un `Future` sin `catch` y
/// la pantalla roja de depuración) a un único lugar: `registrar`.
class ReporteErrores {
  ReporteErrores._();

  /// Últimos mensajes registrados (ya limpios). Sirven para las pruebas.
  static final List<String> recientes = [];

  /// Quita lo que NUNCA debe quedar en un registro: cabeceras `Bearer`,
  /// tokens JWT y valores de campos `password`.
  static String limpiar(String texto) => texto
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'), 'Bearer ***')
      .replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'), '***')
      .replaceAllMapped(
        RegExp(r'(password["=:\s]+)[^\s,&}"]+', caseSensitive: false),
        (m) => '${m[1]}***',
      );

  /// Guarda el error ya limpio. En producción se enviaría a un servicio de
  /// monitoreo (Crashlytics, Sentry…), siempre con el mensaje limpio.
  static void registrar(Object error, StackTrace? pila) {
    final mensaje = limpiar('${error.runtimeType}: $error');
    recientes.add(mensaje);
    if (recientes.length > 20) recientes.removeAt(0);
    debugPrint('[Inventario] error no controlado -> $mensaje');
  }

  /// Avisa sin mostrar nada técnico, si la app ya tiene navegación.
  static void avisar() {
    try {
      if (Get.key.currentState == null) return;
      Get.snackbar('Algo salió mal', 'Ya registramos el problema. Puedes seguir usando la app.');
    } catch (_) {
      // El aviso nunca debe romper el propio manejo de errores.
    }
  }

  /// Se llama una sola vez, desde `main()`.
  static void instalar() {
    FlutterError.onError = (detalles) {
      FlutterError.presentError(detalles);
      registrar(detalles.exception, detalles.stack);
    };
    PlatformDispatcher.instance.onError = (error, pila) {
      registrar(error, pila);
      avisar();
      return true;
    };
    ErrorWidget.builder = (detalles) => const ErrorPantallaView();
  }
}
