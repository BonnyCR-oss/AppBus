class UsuarioModel {
  final int id;
  final String nombres;
  final String apellidos;
  final String ci;
  final String email;
  final String password;
  final int fkRol;
  final bool estaActivo; 
  final String nombreRol;

  const UsuarioModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.ci,
    required this.email,
    required this.password,
    required this.fkRol,
    required this.estaActivo,
    this.nombreRol = 'Sin Rol',
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      nombres: (map['nombres'] ?? '').toString().trim(),
      apellidos: (map['apellidos'] ?? '').toString().trim(),
      ci: (map['ci'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      password: (map['password'] ?? '').toString(),
      fkRol: (map['fk_rol'] as num?)?.toInt() ?? 0,
      estaActivo: map['estado'] == true, 
      
      nombreRol: map['roles'] != null 
          ? map['roles']['nombre']?.toString() ?? 'Sin Rol' 
          : 'Sin Rol',
    );
  }

  String get nombreCompleto {
    final parts = [nombres, apellidos].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Usuario' : parts.join(' ');
  }
}