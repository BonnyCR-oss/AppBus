import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ruta_model.dart';

class RutaController {
  final _supabase = Supabase.instance.client;

  // taer las rutas de la db
  Future<List<RutaModel>> obtenerRutas() async {
    try {
      final data = await _supabase.from('rutas').select().order('id');
      return (data as List).map((map) => RutaModel.fromMap(map)).toList();
    } catch (e) {
      throw 'Error al cargar rutas: $e';
    }
  }

  // actualizar solo el precio
  Future<void> actualizarPrecio(int id, double nuevoPrecio) async {
    try {
      await _supabase
          .from('rutas')
          .update({'precio': nuevoPrecio})
          .eq('id', id);
    } catch (e) {
      throw 'No se pudo actualizar el precio: $e';
    }
  }
}