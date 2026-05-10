class RutaModel {
  final int id;
  final String origen;
  final String destino;
  final double precio;

  RutaModel({
    required this.id,
    required this.origen,
    required this.destino,
    required this.precio,
  });

  factory RutaModel.fromMap(Map<String, dynamic> map) {
    return RutaModel(
      id: map['id'] ?? 0,
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      precio: (map['precio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}