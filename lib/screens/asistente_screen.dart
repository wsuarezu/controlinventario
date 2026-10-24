import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../theme/app_theme.dart';

/// Chat con el asistente de inventario. Estados: vacío (con sugerencias),
/// pensando, respuesta y error con Reintentar.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final AsistenteController _c = Get.find<AsistenteController>();
  final _texto = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? sugerencia]) async {
    final pregunta = sugerencia ?? _texto.text;
    if (pregunta.trim().isEmpty) return;
    _texto.clear();
    FocusScope.of(context).unfocus();
    final envio = _c.preguntar(pregunta);
    _bajar();
    await envio;
    _bajar();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: tema.colorScheme.secondaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: tema.colorScheme.onSecondaryContainer),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sugerencias de IA: verifica antes de decidir.',
                  style: TextStyle(color: tema.colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_c.mensajes.isEmpty && !_c.pensando.value && _c.error.value.isEmpty) {
              return _Bienvenida(onSugerencia: _enviar);
            }
            return ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                for (final m in _c.mensajes) _Burbuja(mensaje: m),
                if (_c.pensando.value) const _Pensando(),
                if (_c.error.value.isNotEmpty)
                  _ErrorChat(mensaje: _c.error.value, onReintentar: _c.reintentar),
              ],
            );
          }),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                      hintText: 'Pregunta sobre tu inventario',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Obx(
                  () => IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _c.pensando.value ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida({required this.onSugerencia});

  final void Function(String) onSugerencia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Icon(Icons.auto_awesome, size: 56, color: tema.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Pregúntame sobre tu inventario',
          textAlign: TextAlign.center,
          style: tema.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Respondo con los datos actuales de tus productos.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in AsistenteController.sugerencias)
              ActionChip(label: Text(s), onPressed: () => onSugerencia(s)),
          ],
        ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final propio = mensaje.deUsuario;
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: propio ? tema.colorScheme.primary : tema.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              mensaje.texto,
              style: TextStyle(
                color: propio ? tema.colorScheme.onPrimary : tema.colorScheme.onSurface,
              ),
            ),
            if (!propio) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                mensaje.esIa ? 'Generado con IA' : 'Respuesta automática (sin IA)',
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pensando extends StatelessWidget {
  const _Pensando();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: AppSpacing.sm),
          Text('El asistente está pensando...'),
        ],
      ),
    );
  }
}

class _ErrorChat extends StatelessWidget {
  const _ErrorChat({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      color: tema.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje, style: TextStyle(color: tema.colorScheme.onErrorContainer)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
