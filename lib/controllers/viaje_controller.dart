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

  Future<List<ViajeModel>> obtenerViajesActivos() async {
    try {
      final data = await _supabase
          .from('viajes')
          .select('id, fk_bus, fk_admin, fk_ruta, fecha_salida, hora_salida, estado, rutas(origen, destino)')
          .neq('estado', 'Finalizado') 
          // ordenamos primero por fecha y luego por hora para que salgan en orden lógico
          .order('fecha_salida') 
          .order('hora_salida');

      return (data as List)
          .map((map) => ViajeModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al cargar viajes activos: $e';
    }
  }

  Future<List<ViajeModel>> obtenerHistorialViajes() async {
    try {
      final data = await _supabase
          .from('viajes')
          .select('id, fk_bus, fk_admin, fk_ruta, fecha_salida, hora_salida, estado, rutas(origen, destino)')
          // Filtramos estrictamente por la palabra 'Finalizado'
          .eq('estado', 'Finalizado') 
          // Ordenamos 'false' para que muestre los más recientes arriba
          .order('fecha_salida', ascending: false) 
          .order('hora_salida', ascending: false);

      return (data as List)
          .map((map) => ViajeModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al cargar el historial: $e';
    }
  }
  
  Future<List<ViajeModel>> obtenerHistorialPorRango(String fechaInicio, String fechaFin) async {
    try {
      final data = await _supabase
          .from('viajes')
          .select('id, fk_bus, fk_admin, fk_ruta, fecha_salida, hora_salida, estado, rutas(origen, destino)')
          .eq('estado', 'Finalizado')
          // .gte significa Mayor o igual que (Greater Than or Equal)
          .gte('fecha_salida', fechaInicio)
          // .lte significa Menor o igual que (Less Than or Equal)
          .lte('fecha_salida', fechaFin)
          .order('fecha_salida', ascending: false)
          .order('hora_salida', ascending: false);

      return (data as List)
          .map((map) => ViajeModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al filtrar el historial: $e';
    }
  }

  Future<List<ViajeModel>> obtenerHistorialViajesPorFecha(String fechaSalida) async {
    try {
      final data = await _supabase
          .from('viajes')
          .select(
              'id, fk_bus, fk_admin, fk_ruta, fecha_salida, hora_salida, estado, rutas(origen, destino)')
          .eq('estado', 'Finalizado')
          .eq('fecha_salida', fechaSalida)
          .order('hora_salida', ascending: false);

      return (data as List)
          .map((map) => ViajeModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al filtrar historial por fecha: $e';
    }
  }

  Future<void> actualizarEstadoViaje(int idViaje, String nuevoEstado) async {
    try {
      await _supabase
          .from('viajes')
          .update({'estado': nuevoEstado})
          .eq('id', idViaje);
    } catch (e) {
      throw 'No se pudo actualizar el estado: $e';
    }
  }
  Future<void> crearViaje({
    required int idRuta,
    required int idAdmin,
    required int idBus,
    required String fechaSalida,
    required String horaSalida,
    String estado = 'Programado',
  }) async {
    try {
      await _supabase.from('viajes').insert({
        'fk_ruta': idRuta,
        'fk_admin': idAdmin,
        'fk_bus': idBus,
        'fecha_salida': fechaSalida,
        'hora_salida': horaSalida,
        'estado': estado,
      });
    } catch (e) {
      throw 'Error al crear viaje: $e';
    }
  }
}