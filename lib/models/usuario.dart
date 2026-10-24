/// Usuario de la sesión, tal como lo devuelve `GET /usuarios/me`.
class Usuario {
  const Usuario({required this.id, required this.email});

  final int id;
  final String email;

  factory Usuario.fromJson(Map<String, dynamic> json) =>
      Usuario(id: (json['id'] as num).toInt(), email: json['email'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'email': email};
}
