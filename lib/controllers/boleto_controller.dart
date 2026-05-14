import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asiento_model.dart';

class BoletoController {
  final _supabase = Supabase.instance.client;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<Map<int, Map<String, dynamic>>> obtenerDetalleBoletosPorViaje(
      int viajeId) async {
    final data = await _supabase
        .from('boletos')
        .select(
            'id, fk_asiento, nombre_pasajero, ci_pasajero, precio, fecha_venta, estado, fk_usuario_vendedor,origen, destino')
        .eq('fk_viaje', viajeId)
        .order('fecha_venta', ascending: false);

    final Map<int, Map<String, dynamic>> detallePorAsiento = {};

    for (final row in data as List) {
      final map = row as Map<String, dynamic>;
      final asientoId = _toInt(map['fk_asiento']);
      if (asientoId <= 0) continue;

      // Conserva solo el ultimo boleto por asiento en este viaje.
      detallePorAsiento.putIfAbsent(asientoId, () => map);
    }

    return detallePorAsiento;
  }

  Future<void> registrarVenta({
    required int viajeId,
    required List<AsientoModel> asientos,
    required String nombrePasajero,
    required String ciPasajero,
    required double precioUnitario,
    required int? vendedorId,
    required String origen,
    required String destino,
    String estado = 'vendido', // <-- NUEVO PARÁMETRO CON VALOR POR DEFECTO
  }) async {
    if (asientos.isEmpty) {
      throw 'Debes seleccionar al menos un asiento.';
    }

    if (vendedorId == null) {
      throw 'No se encontró usuario vendedor en sesión.';
    }

    final fechaVenta = DateTime.now().toIso8601String();
    // Un boleto por asiento seleccionado, usando los mismos datos del comprador.
    final boletos = asientos
        .map(
          (asiento) => {
            'fk_viaje': viajeId,
            'fk_asiento': asiento.id,
            'fk_usuario_vendedor': vendedorId,
            'nombre_pasajero': nombrePasajero,
            'ci_pasajero': ciPasajero,
            'precio': precioUnitario,
            'fecha_venta': fechaVenta,
            'origen': origen,
            'destino': destino,
            'estado': estado,
          },
        )
        .toList();

    await _supabase.from('boletos').insert(boletos);
  }

  // --- NUEVAS FUNCIONES PARA RESERVAS ---

  /// Elimina una reserva para que el asiento vuelva a estar disponible
  Future<void> liberarReserva(int viajeId, int asientoId) async {
    try {
      await _supabase
          .from('boletos')
          .delete()
          .eq('fk_viaje', viajeId)
          .eq('fk_asiento', asientoId)
          .eq('estado', 'reservado'); // Filtro extra de seguridad
    } catch (e) {
      throw 'Error al liberar la reserva: $e';
    }
  }

  /// Cambia el estado de una reserva a 'vendido'
  Future<void> confirmarReserva(int viajeId, int asientoId) async {
    try {
      await _supabase
          .from('boletos')
          .update({
            'estado': 'vendido', 
            'fecha_venta': DateTime.now().toIso8601String() // Actualizamos la fecha a HOY para los reportes
          }) 
          .eq('fk_viaje', viajeId)
          .eq('fk_asiento', asientoId)
          .eq('estado', 'reservado');
    } catch (e) {
      throw 'Error al confirmar la reserva: $e';
    }
  }

  Future<double> obtenerTotalRecaudadoPorViaje(int viajeId) async {
    try {
      final data = await _supabase
          .from('boletos')
          .select('precio')
          .eq('fk_viaje', viajeId)
          .eq('estado', 'vendido');

      double total = 0.0;
      for (final row in data as List) {
        final precio = row['precio'];
        if (precio is num) {
          total += precio.toDouble();
        }
      }
      return total;
    } catch (e) {
      throw 'Error al calcular total recaudado: $e';
    }
  }

  Future<Map<int, Map<String, dynamic>>> obtenerEstadisticasVendedores(
      int viajeId) async {
    try {
      final data = await _supabase
          .from('boletos')
          .select('fk_usuario_vendedor, precio')
          .eq('fk_viaje', viajeId)
          .eq('estado', 'vendido');

      final Map<int, Map<String, dynamic>> estadisticas = {};

      for (final row in data as List) {
        final vendedorId = _toInt(row['fk_usuario_vendedor']);
        final precio = (row['precio'] is num) ? row['precio'].toDouble() : 0.0;

        if (vendedorId <= 0) continue;

        if (!estadisticas.containsKey(vendedorId)) {
          estadisticas[vendedorId] = {
            'cantidad_boletos': 0,
            'total_recaudado': 0.0,
            'nombres': '',
            'apellidos': '',
          };
        }

        estadisticas[vendedorId]!['cantidad_boletos'] =
            _toInt(estadisticas[vendedorId]!['cantidad_boletos']) + 1;
        estadisticas[vendedorId]!['total_recaudado'] =
            (estadisticas[vendedorId]!['total_recaudado'] as double) + precio;
      }

      // Obtener nombres de vendedores
      for (final vendedorId in estadisticas.keys) {
        try {
          final usuario = await _supabase
              .from('usuarios')
              .select('nombres, apellidos')
              .eq('id', vendedorId)
              .maybeSingle();

          if (usuario != null) {
            estadisticas[vendedorId]!['nombres'] =
                (usuario['nombres'] ?? '').toString();
            estadisticas[vendedorId]!['apellidos'] =
                (usuario['apellidos'] ?? '').toString();
          }
        } catch (e) {
          debugPrint('Error al obtener nombre del vendedor $vendedorId: $e');
        }
      }

      return estadisticas;
    } catch (e) {
      throw 'Error al obtener estadísticas de vendedores: $e';
    }
  }
}
