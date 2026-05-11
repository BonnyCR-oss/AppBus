import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asiento_model.dart';

class AsientoController {
  final _supabase = Supabase.instance.client;

  Future<List<AsientoModel>> obtenerAsientosPorBus(int busId) async {
    try {
      final dataFiltrada = await _supabase
          .from('asientos')
          .select('id, fk_bus, numero, tipo, estado')
          .eq('fk_bus', busId)
          .order('numero');

      var asientos = (dataFiltrada as List)
          .map((map) => AsientoModel.fromMap(map as Map<String, dynamic>))
          .toList();

      // Fallback para casos donde el filtro en BD no retorna filas por tipo/formato.
      if (asientos.isEmpty) {
        final dataCompleta = await _supabase
            .from('asientos')
            .select('id, fk_bus, numero, tipo, estado')
            .order('numero');

        asientos = (dataCompleta as List)
            .map((map) => AsientoModel.fromMap(map as Map<String, dynamic>))
            .where((a) => a.fkBus == busId)
            .toList();
      }

      return asientos;
    } catch (e) {
      throw 'Error al cargar asientos del bus: $e';
    }
  }
}