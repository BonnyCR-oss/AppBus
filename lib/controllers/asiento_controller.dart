import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asiento_model.dart';

class AsientoController {
  final _supabase = Supabase.instance.client;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

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

  // Obtener asientos bloqueados vigentes (menos de 5 minutos de antigüedad)
  Future<List<int>> obtenerAsientosBloqueados(
    int viajeId, {
    int? excluirVendedorId,
  }) async {
    try {
      final ahora = DateTime.now();
      final hace5Minutos = ahora.subtract(const Duration(minutes: 5));

      var query = _supabase
          .from('asientos_bloqueados')
          .select('fk_asiento, fk_usuario_vendedor')
          .eq('fk_viaje', viajeId)
          .gt('timestamp_bloqueo', hace5Minutos.toIso8601String());

      if (excluirVendedorId != null) {
        query = query.neq('fk_usuario_vendedor', excluirVendedorId);
      }

      final asientosBloqueados = <int>{};
      final data = await query;
      for (final row in data as List) {
        final asientoId = _toInt(row['fk_asiento']);
        if (asientoId > 0) {
          asientosBloqueados.add(asientoId);
        }
      }
      return asientosBloqueados.toList();
    } catch (e) {
      debugPrint('Error al obtener asientos bloqueados: $e');
      return [];
    }
  }

  // Bloquear un asiento (cuando lo selecciona)
  Future<void> bloquearAsiento({
    required int asientoId,
    required int viajeId,
    required int? vendedorId,
  }) async {
    try {
      if (vendedorId == null) return;
      await _supabase
          .from('asientos_bloqueados')
          .delete()
          .eq('fk_asiento', asientoId)
          .eq('fk_viaje', viajeId);

      await _supabase.from('asientos_bloqueados').insert({
        'fk_asiento': asientoId,
        'fk_viaje': viajeId,
        'fk_usuario_vendedor': vendedorId,
        'timestamp_bloqueo': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error al bloquear asiento: $e');
      // No lanzamos error aquí para no interrumpir la selección
    }
  }

  // Desbloquear un asiento (cuando lo deselecciona)
  Future<void> desbloquearAsiento({
    required int asientoId,
    required int viajeId,
    required int? vendedorId,
  }) async {
    try {
      if (vendedorId == null) return;
      await _supabase
          .from('asientos_bloqueados')
          .delete()
          .eq('fk_asiento', asientoId)
          .eq('fk_viaje', viajeId)
          .eq('fk_usuario_vendedor', vendedorId);
    } catch (e) {
      debugPrint('Error al desbloquear asiento: $e');
    }
  }

  Future<void> desbloquearAsientosVendidos({
    required int viajeId,
    required List<int> asientosIds,
  }) async {
    try {
      if (asientosIds.isEmpty) return;
      await _supabase
          .from('asientos_bloqueados')
          .delete()
          .eq('fk_viaje', viajeId)
          .inFilter('fk_asiento', asientosIds);
    } catch (e) {
      debugPrint('Error al desbloquear asientos vendidos: $e');
    }
  }

  // Desbloquear todos los asientos de un vendedor en un viaje
  Future<void> desbloquearTodosEnViaje({
    required int viajeId,
    required int? vendedorId,
  }) async {
    try {
      if (vendedorId == null) return;
      await _supabase
          .from('asientos_bloqueados')
          .delete()
          .eq('fk_viaje', viajeId)
          .eq('fk_usuario_vendedor', vendedorId);
    } catch (e) {
      debugPrint('Error al desbloquear todos en viaje: $e');
    }
  }
}