import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Registro de cuenta. Si sale bien, la sesión queda abierta y se vuelve a la
/// raíz, que ya muestra el inventario.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _auth.mensajeError.value = '';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _auth.registrar(_email.text.trim(), _password.text);
    if (_auth.estaAutenticado) Get.until((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
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
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo 8 caracteres',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: Validadores.passwordNueva,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _confirmacion,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  labelText: 'Repite la contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v == _password.text ? null : 'Las contraseñas no coinciden',
              ),
              const SizedBox(height: AppSpacing.lg),
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
                      : const Text('Crear cuenta'),
                ),
              ),
              TextButton(onPressed: Get.back, child: const Text('Ya tengo cuenta')),
            ],
          ),
        ),
      ),
    );
  }
}
