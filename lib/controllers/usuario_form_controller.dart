import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class UsuarioFormController {
  final _supabase = Supabase.instance.client;

  Future<void> guardarUsuario({
    int? id,
    required String nombres,
    required String apellidos,
    required String ci,
    required String email,
    required String passwordPlana,
    required String rolSeleccionado,
    required bool estaActivo,
  }) async {
    
    int fkRol = 2; 
    if (rolSeleccionado == 'Admin') fkRol = 1;

    final datos = {
      'nombres': nombres,
      'apellidos': apellidos,
      'ci': ci,
      'email': email,
      'fk_rol': fkRol,
      'estado': estaActivo,
    };

    if (passwordPlana.isNotEmpty) {
      final salt = BCrypt.gensalt();
      datos['password'] = BCrypt.hashpw(passwordPlana, salt);
    } else if (id == null) {
      throw Exception('La contraseña es obligatoria para un usuario nuevo.');
    }

    try {
      if (id == null) {
        await _supabase.from('usuarios').insert(datos);
      } else {
        await _supabase.from('usuarios').update(datos).eq('id', id);
      }
    } on PostgrestException catch (e) {

      if (e.code == '23505') {
        if (e.message.contains('usuarios_ci_key')) {
          throw 'Ya existe un usuario registrado con este Carnet de Identidad (CI).';
        } else if (e.message.contains('usuarios_email_key')) {
          throw 'Este correo electrónico ya está en uso por otro usuario.';
        }
        throw 'Un dato único ya existe en la base de datos.';
      }
      // Si es otro error de Supabase
      throw 'Error de base de datos: ${e.message}';
    } catch (e) {
      // Cualquier otro tipo de error
      throw 'Error inesperado al guardar: $e';
    }
  }
}