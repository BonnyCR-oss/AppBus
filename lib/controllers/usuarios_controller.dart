import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/usuario_model.dart';
import '../services/smtp_email_service.dart';
import '../utils/password_generator.dart';

class UsuariosController {
  final _supabase = Supabase.instance.client;
  final _smtpEmailService = SmtpEmailService();

  // traer la lista de usuarios
  Future<List<UsuarioModel>> obtenerUsuarios() async {
    try {
      final data = await _supabase
          .from('usuarios')
          .select('*, roles(nombre)')
          .order('id');

      return (data as List).map((mapa) => UsuarioModel.fromMap(mapa)).toList();
    } catch (e) {
      throw Exception('Error al cargar usuarios: $e');
    }
  }

  // desactivar usuario (eliminacion logica)
  Future<void> eliminarUsuarioPorId(int id) async {
    try {
      await _supabase.from('usuarios').update({'estado': false}).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al desactivar usuario: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo desactivar el usuario: $e');
    }
  }

  Future<void> reenviarContraseniaTemporal(UsuarioModel usuario) async {
    final nuevaContrasenia = PasswordGenerator.generarContraseniaSegura();
    final hash = BCrypt.hashpw(nuevaContrasenia, BCrypt.gensalt());

    try {
      await _supabase
          .from('usuarios')
          .update({'password': hash})
          .eq('id', usuario.id);

      try {
        await _smtpEmailService.enviarContraseniaGenerada(
          to: usuario.email,
          nombre: usuario.nombreCompleto,
          contrasenia: nuevaContrasenia,
        );
      } catch (_) {
        // Email falló pero contraseña ya fue actualizada en DB
      }
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar contraseña temporal: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo reenviar contraseña: $e');
    }
  }
}