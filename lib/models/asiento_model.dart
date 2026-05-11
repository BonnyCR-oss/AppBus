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

  // Calcula fila (basada en número: 1-4->fila 0, 5-8->fila 1, etc.)
  // Agrupa de 4 asientos por fila (2 izq + pasillo + 2 der)
  int get fila => (numero - 1) ~/ 4;

  // Calcula posición en la fila para layout de 5 columnas:
  // Columnas: 0(asiento izq 1), 1(asiento izq 2), 2(pasillo), 3(asiento der 1), 4(asiento der 2)
  int get posicionFila {
    final posEnGrupo = (numero - 1) % 4;
    return posEnGrupo < 2 ? posEnGrupo : posEnGrupo + 1; // Salta columna 2 (pasillo)
  }

  // Determina si es lado izquierdo o derecho
  bool get esLadoIzquierdo => (numero - 1) % 4 < 2;
  bool get esLadoDerecho => (numero - 1) % 4 >= 2;
}