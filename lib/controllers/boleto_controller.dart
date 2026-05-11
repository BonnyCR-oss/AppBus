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
            'id, fk_asiento, nombre_pasajero, ci_pasajero, precio, fecha_venta, estado, fk_usuario_vendedor')
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
            'estado': 'vendido',
          },
        )
        .toList();

    await _supabase.from('boletos').insert(boletos);
  }
}
