import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario_model.dart';

class LoginController {
  static const int rolDuenoId = 1;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UsuarioModel?> buscarUsuarioPorEmail(String email) async {
    final data = await _supabase
        .from('usuarios')
        .select('id, nombres, apellidos, ci, contacto, email, password, fk_rol, estado')//agregue estado
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

  String generarHashContrasenia(String passwordPlano) {
    return BCrypt.hashpw(passwordPlano, BCrypt.gensalt());
  }

  Future<void> actualizarContraseniaUsuario({
    required int usuarioId,
    required String nuevaContraseniaPlano,
  }) async {
    final hash = generarHashContrasenia(nuevaContraseniaPlano);
    await actualizarContraseniaUsuarioHash(
      usuarioId: usuarioId,
      hashContrasenia: hash,
    );
  }

  Future<void> actualizarContraseniaUsuarioHash({
    required int usuarioId,
    required String hashContrasenia,
  }) async {
    await _supabase
        .from('usuarios')
        .update({'password': hashContrasenia})
        .eq('id', usuarioId);
  }
}
