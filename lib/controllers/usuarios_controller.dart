import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class UsuariosController {
  final _supabase = Supabase.instance.client;

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

  // eliminar usuario fisicamente de la base de datos
  Future<void> eliminarUsuarioPorId(int id) async {
    try {
      await _supabase.from('usuarios').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar usuario: ${e.message}');
    } catch (e) {
      throw Exception('No se pudo eliminar el usuario: $e');
    }
  }
}