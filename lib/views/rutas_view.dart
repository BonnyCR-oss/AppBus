import 'package:flutter/material.dart';

class RutasView extends StatelessWidget {
  const RutasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Gestión de Rutas',
            style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
          child: Text('Aquí se iniciarán rutas y se verá el historial')),
    );
  }
}
