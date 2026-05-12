import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsController {
  final _supabase = Supabase.instance.client;

  /// Obtiene el rango de fechas según el período seleccionado
  Map<String, DateTime> _obtenerRangoFechas(String periodo) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    late final DateTime inicio;
    late final DateTime fin;

    switch (periodo) {
      case 'hoy':
        inicio = hoy;
        fin = hoy.add(const Duration(days: 1));
        break;
      case 'semana':
        final diaSemanaCero = hoy.subtract(Duration(days: hoy.weekday % 7));
        inicio = diaSemanaCero;
        fin = diaSemanaCero.add(const Duration(days: 7));
        break;
      case '2semanas':
        final diaSemanaCero = hoy.subtract(Duration(days: hoy.weekday % 7));
        inicio = diaSemanaCero.subtract(const Duration(days: 7));
        fin = diaSemanaCero.add(const Duration(days: 7));
        break;
      case 'mes':
        inicio = DateTime(ahora.year, ahora.month, 1);
        fin = DateTime(ahora.year, ahora.month + 1, 1);
        break;
      case 'mesAnterior':
        final mesAnterior = ahora.month - 1;
        final anno = mesAnterior > 0 ? ahora.year : ahora.year - 1;
        final mes = mesAnterior > 0 ? mesAnterior : 12;
        inicio = DateTime(anno, mes, 1);
        fin = DateTime(anno, mes + 1, 1);
        break;
      case 'anno':
        inicio = DateTime(ahora.year, 1, 1);
        fin = DateTime(ahora.year + 1, 1, 1);
        break;
      case 'annoAnterior':
        inicio = DateTime(ahora.year - 1, 1, 1);
        fin = DateTime(ahora.year, 1, 1);
        break;
      default:
        inicio = hoy;
        fin = hoy.add(const Duration(days: 1));
    }

    return {
      'inicio': inicio,
      'fin': fin,
    };
  }

  /// Obtiene el resumen de ingresos y viajes en un período
  Future<Map<String, dynamic>> obtenerResumen(String periodo) async {
    final rango = _obtenerRangoFechas(periodo);
    final fechaInicio = rango['inicio']!.toIso8601String().split('T')[0];
    final fechaFin = rango['fin']!.toIso8601String().split('T')[0];

    try {
      // Obtener total de ingresos
      final boletos = await _supabase
          .from('boletos')
          .select('precio, fecha_venta')
          .gte('fecha_venta', '$fechaInicio 00:00:00')
          .lt('fecha_venta', '$fechaFin 00:00:00')
          .eq('estado', 'vendido');

      double totalIngresos = 0.0;
      for (final boleto in boletos as List) {
        final precio = boleto['precio'];
        if (precio is num) {
          totalIngresos += precio.toDouble();
        }
      }

      // Obtener total de viajes completados
      final viajes = await _supabase
          .from('viajes')
          .select('id')
          .gte('fecha_salida', fechaInicio)
          .lt('fecha_salida', fechaFin)
          .eq('estado', 'finalizado');

      final cantidadViajes = (viajes as List).length;

      // Obtener cantidad de boletos vendidos
      final cantidadBoletos = (boletos as List).length;

      return {
        'totalIngresos': totalIngresos,
        'cantidadViajes': cantidadViajes,
        'cantidadBoletos': cantidadBoletos,
        'promedioPorViaje': cantidadViajes > 0 ? totalIngresos / cantidadViajes : 0.0,
      };
    } catch (e) {
      throw 'Error al obtener resumen: $e';
    }
  }

  /// Obtiene ventas agrupadas por usuario (vendedor)
  Future<List<Map<String, dynamic>>> obtenerVentasPorUsuario(String periodo) async {
    final rango = _obtenerRangoFechas(periodo);
    final fechaInicio = rango['inicio']!.toIso8601String().split('T')[0];
    final fechaFin = rango['fin']!.toIso8601String().split('T')[0];

    try {
      // Obtener boletos en el rango de fechas
      final datos = await _supabase
          .from('boletos')
          .select('fk_usuario_vendedor, precio, id')
          .gte('fecha_venta', '$fechaInicio 00:00:00')
          .lt('fecha_venta', '$fechaFin 00:00:00')
          .eq('estado', 'vendido');

      // Agrupar por usuario y obtener IDs únicos
      final Map<int, Map<String, dynamic>> ventasPorUsuario = {};
      final Set<int> usuariosIds = {};

      for (final boleto in datos as List) {
        final userId = boleto['fk_usuario_vendedor'];
        final precio = boleto['precio'];
        
        usuariosIds.add(userId);

        if (!ventasPorUsuario.containsKey(userId)) {
          ventasPorUsuario[userId] = {
            'usuarioId': userId,
            'nombreUsuario': 'Desconocido',
            'cantidadVentas': 0,
            'totalIngresos': 0.0,
          };
        }

        ventasPorUsuario[userId]!['cantidadVentas']++;
        if (precio is num) {
          ventasPorUsuario[userId]!['totalIngresos'] += precio.toDouble();
        }
      }

      // Obtener nombres de usuarios
      if (usuariosIds.isNotEmpty) {
        final usuarios = await _supabase
            .from('usuarios')
            .select('id, nombres, apellidos')
            .inFilter('id', usuariosIds.toList());

        for (final usuario in usuarios as List) {
          final userId = usuario['id'];
          final nombres = usuario['nombres'] ?? '';
          final apellidos = usuario['apellidos'] ?? '';
          final nombreCompleto = '$nombres $apellidos'.trim();

          if (ventasPorUsuario.containsKey(userId)) {
            ventasPorUsuario[userId]!['nombreUsuario'] = nombreCompleto.isEmpty ? 'Desconocido' : nombreCompleto;
          }
        }
      }

      // Convertir a lista y ordenar por ingresos (descendente)
      final lista = ventasPorUsuario.values.toList();
      lista.sort((a, b) => (b['totalIngresos'] as double).compareTo(a['totalIngresos'] as double));

      return lista;
    } catch (e) {
      throw 'Error al obtener ventas por usuario: $e';
    }
  }

  /// Obtiene detalles de viajes en un período
  Future<List<Map<String, dynamic>>> obtenerDetallesViajes(String periodo) async {
    final rango = _obtenerRangoFechas(periodo);
    final fechaInicio = rango['inicio']!.toIso8601String().split('T')[0];
    final fechaFin = rango['fin']!.toIso8601String().split('T')[0];

    try {
      // Obtener viajes sin join (evitar errores de relación)
      final datos = await _supabase
          .from('viajes')
          .select('id, fecha_salida, hora_salida, estado, fk_ruta')
          .gte('fecha_salida', fechaInicio)
          .lt('fecha_salida', fechaFin);

      // Obtener rutas para enriquecer datos
      final rutasIds = Set<int>();
      for (final viaje in datos as List) {
        final rutaId = viaje['fk_ruta'];
        if (rutaId is int) rutasIds.add(rutaId);
      }

      final Map<int, Map<String, dynamic>> rutasMap = {};
      if (rutasIds.isNotEmpty) {
        final rutas = await _supabase
            .from('rutas')
            .select('id, origen, destino')
            .inFilter('id', rutasIds.toList());

        for (final ruta in rutas as List) {
          rutasMap[ruta['id']] = ruta;
        }
      }

      // Enriquecer con datos de boletos
      final viajes = [];

      for (final viaje in datos as List) {
        final viajeId = viaje['id'];
        final rutaId = viaje['fk_ruta'];

        // Obtener boletos de este viaje
        final boletos = await _supabase
            .from('boletos')
            .select('precio')
            .eq('fk_viaje', viajeId)
            .eq('estado', 'vendido');

        double totalIngresos = 0.0;
        int cantidadBoletos = 0;

        for (final boleto in boletos as List) {
          cantidadBoletos++;
          final precio = boleto['precio'];
          if (precio is num) {
            totalIngresos += precio.toDouble();
          }
        }

        final rutaData = rutasMap[rutaId];
        final nombreRuta = rutaData != null 
            ? '${rutaData['origen'] ?? 'Origen'} ➔ ${rutaData['destino'] ?? 'Destino'}'
            : 'Ruta desconocida';

        viajes.add({
          'id': viajeId,
          'fecha': viaje['fecha_salida'],
          'hora': viaje['hora_salida'],
          'ruta': nombreRuta,
          'estado': viaje['estado'],
          'cantidadBoletos': cantidadBoletos,
          'totalIngresos': totalIngresos,
        });
      }

      // Ordenar por fecha (descendente)
      viajes.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));

      return viajes.cast<Map<String, dynamic>>();
    } catch (e) {
      throw 'Error al obtener detalles de viajes: $e';
    }
  }
}
