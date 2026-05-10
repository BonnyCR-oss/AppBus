import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/viaje_model.dart';

class ViajeController {
  final _supabase = Supabase.instance.client;

  //para la pantalla de Ventas: Busca el único viaje 'Activo'
  Future<ViajeModel?> obtenerViajeActivo() async {
    try {
      final data = await _supabase
          .from('viajes')
          .select()
          .eq('estado', 'Activo')
          .maybeSingle();

      if (data == null) return null;
      return ViajeModel.fromMap(data);
    } catch (e) {
      throw 'Error al buscar el viaje activo: $e';
    }
  }

  // pra el admin iniciar un nuevo viaje con todos los datos
  Future<void> abrirNuevoViaje({
    required int idRuta,
    required int idAdmin,
    required int idBus,
    required String fechaSalida, // Recibimos el valor del selector
    required String horaSalida,  // Recibimos el valor del selector
  }) async {
    try {
      await _supabase
          .from('viajes')
          .update({'estado': 'Finalizado'})
          .eq('estado', 'Activo'); 

      await _supabase.from('viajes').insert({
        'fk_ruta': idRuta,
        'fk_admin': idAdmin,
        'fk_bus': idBus,
        'fecha_salida': fechaSalida,
        'hora_salida': horaSalida,
        'estado': 'Activo',
      });
      
    } catch (e) {
      throw 'Error al abrir nuevo viaje: $e';
    }
  }

  // finalizar manualmente
  Future<void> finalizarViajeActivo() async {
    try {
      await _supabase
          .from('viajes')
          .update({'estado': 'Finalizado'}) 
          .eq('estado', 'Activo');
    } catch (e) {
      throw 'Error al finalizar el viaje: $e';
    }
  }
}