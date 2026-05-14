import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alquiler_model.dart';

class AlquilerController {
  final _supabase = Supabase.instance.client;

  // 1. Obtener alquileres activos (que no estén finalizados)
  Future<List<AlquilerModel>> obtenerAlquileresActivos() async {
    try {
      final data = await _supabase
          .from('alquileres')
          .select()
          .neq('estado', 'Finalizado')
          .order('fecha_salida')
          .order('hora_salida');

      return (data as List)
          .map((map) => AlquilerModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al cargar alquileres: $e';
    }
  }

  // crear un nuevo alquiler
  Future<void> crearAlquiler({
    required int idAdmin,
    required String cliente,
    required String? telefono,
    required String origen,
    required String destino,
    required String fecha,
    required String hora,
    required double precio,
  }) async {
    try {
      await _supabase.from('alquileres').insert({
        'fk_bus': 1, 
        'fk_admin': idAdmin,
        'nombre_cliente': cliente,
        'telefono_cliente': telefono,
        'origen': origen,
        'destino': destino,
        'fecha_salida': fecha,
        'hora_salida': hora,
        'precio_total': precio,
        'estado': 'Programado',
      });
      
    } on PostgrestException catch (errorDB) {
      // Aquí puedes imprimir el error real en la consola para ti como desarrollador
      debugPrint('Error de Supabase: ${errorDB.message} (Código: ${errorDB.code})');
      
      // Pero a la vista le lanzamos un mensaje amigable en español
      throw 'Ocurrió un error en el servidor al guardar el alquiler. Por favor, intenta de nuevo.';
      
    } catch (e) {
      // Para cualquier otro tipo de error (como falta de internet o fallos del teléfono)
      throw 'Error inesperado al registrar el alquiler. Verifica tu conexión.';
    }
  }
  // 3. Actualizar estado del alquiler
  Future<void> actualizarEstadoAlquiler(int id, String nuevoEstado) async {
    try {
      await _supabase.from('alquileres').update({'estado': nuevoEstado}).eq('id', id);
    } catch (e) {
      throw 'No se pudo actualizar el estado: $e';
    }
  }

  Future<List<AlquilerModel>> obtenerHistorialAlquileres() async {
    try {
      final data = await _supabase
          .from('alquileres')
          .select()
          .eq('estado', 'Finalizado')
          .order('fecha_salida', ascending: false) 
          .order('hora_salida', ascending: false);

      return (data as List)
          .map((map) => AlquilerModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al cargar historial de alquileres: $e';
    }
  }

  Future<List<AlquilerModel>> obtenerHistorialAlquileresPorRango(String fechaInicio, String fechaFin) async {
    try {
      final data = await _supabase
          .from('alquileres')
          .select() 
          .eq('estado', 'Finalizado')
          .gte('fecha_salida', fechaInicio)
          .lte('fecha_salida', fechaFin) 
          .order('fecha_salida', ascending: false)
          .order('hora_salida', ascending: false);

      return (data as List)
          .map((map) => AlquilerModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al filtrar el historial de alquileres: $e';
    }
  }
}