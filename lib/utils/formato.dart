/// Fecha corta para avisos: «24/10 a las 14:05».
String fechaCorta(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)} a las ${dos(fecha.hour)}:${dos(fecha.minute)}';
}
