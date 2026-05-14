class AlquilerModel {
  final int id;
  final int fkBus;
  final int fkAdmin;
  final String nombreCliente;
  final String? telefonoCliente;
  final String origen;
  final String destino;
  final String fechaSalida;
  final String horaSalida;
  final double precioTotal;
  final String estado;

  AlquilerModel({
    required this.id,
    required this.fkBus,
    required this.fkAdmin,
    required this.nombreCliente,
    this.telefonoCliente,
    required this.origen,
    required this.destino,
    required this.fechaSalida,
    required this.horaSalida,
    required this.precioTotal,
    required this.estado,
  });

  factory AlquilerModel.fromMap(Map<String, dynamic> map) {
    return AlquilerModel(
      id: map['id'],
      fkBus: map['fk_bus'],
      fkAdmin: map['fk_admin'],
      nombreCliente: map['nombre_cliente'],
      telefonoCliente: map['telefono_cliente'],
      origen: map['origen'],
      destino: map['destino'],
      fechaSalida: map['fecha_salida'],
      horaSalida: map['hora_salida'],
      precioTotal: (map['precio_total'] as num).toDouble(),
      estado: map['estado'],
    );
  }
}