import 'package:get/get.dart';

import '../services/api_client.dart';
import '../services/asistente_service.dart';
import 'auth_controller.dart';

/// Un mensaje de la conversación.
class MensajeChat {
  const MensajeChat({required this.texto, required this.deUsuario, this.esIa = false});

  final String texto;
  final bool deUsuario;

  /// Solo para respuestas: true si la generó la IA (no el modo reglas).
  final bool esIa;
}

/// Conversación con el asistente. Se borra al cerrar sesión.
class AsistenteController extends GetxController {
  AsistenteController({AsistenteService? servicio, AuthController? auth})
    : _servicio = servicio ?? AsistenteService(Get.find<ApiClient>()),
      _auth = auth ?? Get.find<AuthController>();

  final AsistenteService _servicio;
  final AuthController _auth;

  static const sugerencias = [
    '¿Qué productos debo reponer?',
    '¿Cuáles tienen más stock?',
    'Resume el estado de mi inventario',
  ];

  final RxList<MensajeChat> mensajes = <MensajeChat>[].obs;
  final RxBool pensando = false.obs;

  /// Error de la última pregunta; vacío si no hubo.
  final RxString error = ''.obs;

  String? _ultimaPregunta;

  @override
  void onInit() {
    super.onInit();
    _auth.registrarLimpieza(limpiar);
  }

  Future<void> preguntar(String texto) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || pensando.value) return;
    _ultimaPregunta = pregunta;
    error.value = '';
    mensajes.add(MensajeChat(texto: pregunta, deUsuario: true));
    await _consultar(pregunta);
  }

  /// Reintenta la última pregunta sin repetirla en la conversación.
  Future<void> reintentar() async {
    final pregunta = _ultimaPregunta;
    if (pregunta == null || pensando.value) return;
    error.value = '';
    await _consultar(pregunta);
  }

  Future<void> _consultar(String pregunta) async {
    pensando.value = true;
    try {
      final r = await _servicio.preguntar(pregunta);
      mensajes.add(MensajeChat(texto: r.texto, deUsuario: false, esIa: r.esIa));
    } on AsistenteException catch (e) {
      error.value = e.mensaje;
    } finally {
      pensando.value = false;
    }
  }

  Future<void> limpiar() async {
    mensajes.clear();
    error.value = '';
    _ultimaPregunta = null;
  }
}
