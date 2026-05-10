import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../utils/password_generator.dart';

class UsuarioFormController {
  final _supabase = Supabase.instance.client;

  Future<String?> guardarUsuario({
    int? id,
    required String nombres,
    required String apellidos,
    required String ci,
    required String email,
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

    // Si es CREACION (nuevo usuario), generar contrasenia automatica
    if (id == null) {
      final contraseniaGenerada = PasswordGenerator.generarContraseniaSegura();
      final salt = BCrypt.gensalt();
      datos['password'] = BCrypt.hashpw(contraseniaGenerada, salt);

      try {
        await _supabase.from('usuarios').insert(datos);
        return contraseniaGenerada;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          if (e.message.contains('usuarios_ci_key')) {
            throw 'Ya existe un usuario registrado con este Carnet de Identidad (CI).';
          } else if (e.message.contains('usuarios_email_key')) {
            throw 'Este correo electrónico ya está en uso por otro usuario.';
          }
          throw 'Un dato único ya existe en la base de datos.';
        }
        throw 'Error de base de datos: ${e.message}';
      } catch (e) {
        throw 'Error inesperado al guardar: $e';
      }
    } else {
      // Si es EDICION, solo actualizar datos (sin cambiar contrasenia)
      try {
        await _supabase.from('usuarios').update(datos).eq('id', id);
        return null;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          if (e.message.contains('usuarios_ci_key')) {
            throw 'Ya existe un usuario con este CI.';
          } else if (e.message.contains('usuarios_email_key')) {
            throw 'Este correo ya está en uso.';
          }
        }
        throw 'Error: ${e.message}';
      } catch (e) {
        throw 'Error inesperado: $e';
      }
    }
  }
}