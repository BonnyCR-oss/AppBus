class AsientoModel {
  final int id;
  final int fkBus;
  final int numero;
  final String tipo;
  final String estado;

  const AsientoModel({
    required this.id,
    required this.fkBus,
    required this.numero,
    required this.tipo,
    required this.estado,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory AsientoModel.fromMap(Map<String, dynamic> map) {
    return AsientoModel(
      id: _toInt(map['id']),
      fkBus: _toInt(map['fk_bus']),
      numero: _toInt(map['numero']),
      tipo: (map['tipo'] ?? '').toString(),
      estado: (map['estado'] ?? '').toString(),
    );
  }

  bool get estaDisponible {
    final value = estado.toLowerCase();
    return value == 'disponible' || value == 'libre' || value == 'activo';
  }

  // Calcula fila con salto de puerta entre 10 y 11.
  // 1-4 -> fila 0, 5-8 -> fila 1, 9-10 -> fila 2,
  // 11-14 -> fila 3, 15-18 -> fila 4, etc.
  // Reemplaza todo desde aquí hasta el final de tu clase
  
  int get fila {
    // LADO IZQUIERDO (1,2 - 5,6 - 9,10 - 13,14...)
    // Siguen un patrón continuo sin verse afectados por la puerta
    if (numero % 4 == 1 || numero % 4 == 2) {
      return (numero - 1) ~/ 4;
    } 
    // LADO DERECHO (4,3 - 8,7 - [PUERTA] - 12,11 - 16,15...)
    else {
      if (numero <= 8) {
        return (numero - 1) ~/ 4; // Filas 0 y 1
      } else {
        return ((numero - 1) ~/ 4) + 1; // A partir del 11, bajan una fila por la puerta
      }
    }
  }

  // Nueva propiedad infalible para ubicar cada asiento en su columna real
  int get columnaFisica {
    final mod = numero % 4;
    if (mod == 1) return 0; // Ventana Izquierda (1, 5, 9, 13...)
    if (mod == 2) return 1; // Pasillo Izquierdo (2, 6, 10, 14...)
    if (mod == 0) return 3; // Pasillo Derecho (4, 8, 12, 16...)
    if (mod == 3) return 4; // Ventana Derecha (3, 7, 11, 15...)
    return -1;
  }
} // Fin de la clase AsientoModel