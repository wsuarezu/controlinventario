/// Reglas de los formularios. Validar en la app evita un viaje inútil al
/// servidor; el backend sigue siendo quien decide.
class Validadores {
  Validadores._();

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo';
    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
    return valido ? null : 'Escribe un correo válido';
  }

  static String? passwordNueva(String? valor) {
    final largo = valor?.length ?? 0;
    return largo >= 8 ? null : 'La contraseña debe tener al menos 8 caracteres';
  }

  static String? requerido(String? valor, {String campo = 'este campo'}) =>
      (valor == null || valor.trim().isEmpty) ? 'Completa $campo' : null;

  static String? enteroNoNegativo(String? valor) {
    final numero = int.tryParse(valor?.trim() ?? '');
    if (numero == null) return 'Escribe un número entero';
    return numero < 0 ? 'No puede ser negativo' : null;
  }

  static String? enteroPositivo(String? valor) {
    final numero = int.tryParse(valor?.trim() ?? '');
    if (numero == null) return 'Escribe un número entero';
    return numero <= 0 ? 'Debe ser mayor que cero' : null;
  }
}
