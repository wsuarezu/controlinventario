import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/api_config.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'register_screen.dart';

/// Inicio de sesión. Es la pantalla raíz mientras no hay sesión, así que no
/// tiene botón de volver: la salida es entrar o crear una cuenta.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();
  bool _verPassword = false;

  @override
  void initState() {
    super.initState();
    _auth.mensajeError.value = '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _auth.iniciarSesion(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Inventario')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Icon(Icons.inventory_2_outlined, size: 72, color: tema.colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Inicia sesión para ver tu inventario',
                textAlign: TextAlign.center,
                style: tema.textTheme.titleMedium,
              ),
              Obx(
                () => _auth.avisoSesion.value.isEmpty
                    ? const SizedBox(height: AppSpacing.xl)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: tema.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              _auth.avisoSesion.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tema.colorScheme.onErrorContainer),
                            ),
                          ),
                        ),
                      ),
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validadores.correo,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _verPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                    icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _verPassword = !_verPassword),
                  ),
                ),
                validator: (v) => Validadores.requerido(v, campo: 'tu contraseña'),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => _auth.mensajeError.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          _auth.mensajeError.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tema.colorScheme.error),
                        ),
                      ),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: _auth.cargando.value ? null : _enviar,
                  child: _auth.cargando.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Get.to(() => const RegisterScreen()),
                child: const Text('¿No tienes cuenta? Crear una'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Servidor: ${ApiConfig.baseUrl}',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
