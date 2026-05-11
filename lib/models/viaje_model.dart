class ViajeModel {
  final int id;
  final int? fkBus; // Puede ser null si aún no asignan bus
  final int? fkAdmin; 
  final int fkRuta;
  final String fechaSalida;
  final String horaSalida;
  final String estado;
  final String? origenRuta;
  final String? destinoRuta;

  ViajeModel({
    required this.id,
    this.fkBus,
    this.fkAdmin,
    required this.fkRuta,
    required this.fechaSalida,
    required this.horaSalida,
    required this.estado,
    this.origenRuta,
    this.destinoRuta,
  });

  factory ViajeModel.fromMap(Map<String, dynamic> map) {
    final rutas = map['rutas'];
    final Map<String, dynamic>? rutaMap = rutas is Map<String, dynamic> ? rutas : null;

    return ViajeModel(
      id: map['id'] ?? 0,
      fkBus: map['fk_bus'],
      fkAdmin: map['fk_admin'],
      fkRuta: map['fk_ruta'] ?? 0,
      fechaSalida: map['fecha_salida']?.toString() ?? '',
      horaSalida: map['hora_salida']?.toString() ?? '',
      estado: map['estado'] ?? 'Desconocido',
      origenRuta: rutaMap?['origen']?.toString(),
      destinoRuta: rutaMap?['destino']?.toString(),
    );
  }
}