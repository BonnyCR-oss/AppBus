import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';

class LoginController {
  static const int rolDuenoId = 1;

  Future<UsuarioModel?> buscarUsuarioPorEmail(String email) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('usuarios')
        .select('id, nombres, apellidos, ci, email, password, fk_rol')
        .ilike('email', email)
        .maybeSingle();

    return data == null ? null : UsuarioModel.fromMap(data);
  }

  bool validarPassword(String passwordPlano, String passwordGuardada) {
    final pareceHashBcrypt = passwordGuardada.startsWith(r'$2a$') ||
        passwordGuardada.startsWith(r'$2b$') ||
        passwordGuardada.startsWith(r'$2y$');

    if (!pareceHashBcrypt) {
      return passwordPlano == passwordGuardada;
    }

    try {
      return BCrypt.checkpw(passwordPlano, passwordGuardada);
    } catch (_) {
      return false;
    }
  }

  String mensajeErrorBaseDatos(PostgrestException e) {
    final esErrorPermiso =
        e.code == '42501' || e.message.contains('"code":"42501"');
    if (esErrorPermiso) {
      return 'Sin permisos en Supabase para leer usuarios. Revisa GRANT y policy RLS.';
    }
    return 'Error de base de datos: ${e.message}';
  }
}
