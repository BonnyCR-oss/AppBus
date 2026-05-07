import 'package:flutter/material.dart';

class PantallaVenta extends StatelessWidget {
  const PantallaVenta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Venta de Boletos', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(child: Text('Aquí aparecerá el mapa del bus para vender asientos')),
    );
  }
}