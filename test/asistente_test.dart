import 'package:controlinventario/controllers/asistente_controller.dart';
import 'package:controlinventario/controllers/auth_controller.dart';
import 'package:controlinventario/main.dart';
import 'package:controlinventario/screens/asistente_screen.dart';
import 'package:controlinventario/services/api_client.dart';
import 'package:controlinventario/services/asistente_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'soporte/backend_falso.dart';

/// Servicio del asistente sobre un adaptador falso (sin red).
AsistenteService _servicio(ApiClient api, RespuestaFalsa Function(RequestOptions) responder) {
  final dio = Dio(BaseOptions(baseUrl: 'http://asistente'));
  dio.httpClientAdapter = AdaptadorFalso({'POST /asistente': responder});
  return AsistenteService(api, dio: dio);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('AsistenteService', () {
    test('envía la pregunta con el token y lee la respuesta', () async {
      final api = ApiClient()..token = 'tok';
      String? cabecera;
      Object? cuerpo;
      final servicio = _servicio(api, (o) {
        cabecera = o.headers['Authorization'] as String?;
        cuerpo = o.data;
        return (codigo: 200, cuerpo: {'respuesta': 'Repón clavos.', 'modo': 'gemini'});
      });

      final r = await servicio.preguntar('¿Qué repongo?');
      expect(cabecera, 'Bearer tok');
      expect(cuerpo, {'consulta': '¿Qué repongo?'});
      expect(r.texto, 'Repón clavos.');
      expect(r.esIa, isTrue);
    });

    test('un 401 avisa la sesión caducada', () async {
      var avisos = 0;
      final api = ApiClient()
        ..token = 'viejo'
        ..alSesionCaducada = () => avisos++;
      final servicio = _servicio(
        api,
        (_) => (codigo: 401, cuerpo: {'detail': 'Tu sesión caducó. Inicia sesión de nuevo.'}),
      );

      await expectLater(
        servicio.preguntar('hola'),
        throwsA(isA<AsistenteException>().having((e) => e.sesionCaducada, 'caducada', isTrue)),
      );
      expect(avisos, 1);
    });

    test('un 502 muestra el motivo del servidor (backend apagado)', () async {
      final servicio = _servicio(
        ApiClient()..token = 'tok',
        (_) => (
          codigo: 502,
          cuerpo: {'detail': 'El asistente no pudo contactar al backend de inventario.'},
        ),
      );
      await expectLater(
        servicio.preguntar('hola'),
        throwsA(isA<AsistenteException>().having((e) => e.mensaje, 'mensaje', contains('backend'))),
      );
    });

    test('servidor del asistente apagado: mensaje distinto', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://asistente'));
      dio.httpClientAdapter = _SinRed();
      final servicio = AsistenteService(ApiClient()..token = 'tok', dio: dio);

      await expectLater(
        servicio.preguntar('hola'),
        throwsA(
          isA<AsistenteException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('no está disponible'),
          ),
        ),
      );
    });
  });

  group('AsistenteScreen', () {
    late _AsistenteFalso falso;

    Future<void> montar(WidgetTester tester) async {
      final auth = Get.put(AuthController(api: ApiClient(), almacen: AlmacenFalso()));
      Get.put(AsistenteController(servicio: falso, auth: auth));
      await tester.pumpWidget(const InventarioApp(home: Scaffold(body: AsistenteScreen())));
      await tester.pumpAndSettle();
    }

    setUp(() => falso = _AsistenteFalso());

    testWidgets('estado vacío con sugerencias y aviso de IA', (tester) async {
      await montar(tester);
      expect(find.text('Pregúntame sobre tu inventario'), findsOneWidget);
      expect(find.text('Sugerencias de IA: verifica antes de decidir.'), findsOneWidget);
      expect(find.text('¿Qué productos debo reponer?'), findsOneWidget);
    });

    testWidgets('una sugerencia envía la pregunta y muestra la respuesta', (tester) async {
      await montar(tester);
      await tester.tap(find.text('¿Qué productos debo reponer?'));
      await tester.pumpAndSettle();

      expect(falso.preguntas, ['¿Qué productos debo reponer?']);
      expect(find.text('Conviene reponer Clavos.'), findsOneWidget);
      expect(find.text('Generado con IA'), findsOneWidget);
    });

    testWidgets('un error se muestra con Reintentar', (tester) async {
      falso.error = AsistenteException('El asistente no está disponible.');
      await montar(tester);
      await tester.enterText(find.byType(TextField), 'hola');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();
      expect(find.text('El asistente no está disponible.'), findsOneWidget);

      falso.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Conviene reponer Clavos.'), findsOneWidget);
      expect(falso.preguntas, ['hola', 'hola']);
      expect(find.text('hola'), findsOneWidget, reason: 'reintentar no duplica la pregunta');
    });
  });
}

class _AsistenteFalso implements AsistenteService {
  final List<String> preguntas = [];
  AsistenteException? error;

  @override
  Future<RespuestaAsistente> preguntar(String pregunta) async {
    preguntas.add(pregunta);
    final e = error;
    if (e != null) throw e;
    return const RespuestaAsistente(texto: 'Conviene reponer Clavos.', modo: 'gemini');
  }
}

class _SinRed implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? cuerpo,
    Future<void>? cancelacion,
  ) => throw DioException.connectionError(requestOptions: options, reason: 'Connection refused');

  @override
  void close({bool force = false}) {}
}
