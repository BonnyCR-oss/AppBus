import 'package:flutter/material.dart';

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo gris muy claro (F9FAF7) como el de tu diseño
      backgroundColor: const Color(0xFFF9FAF7),
      
      // Barra superior verde
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        elevation: 0,
        title: const Text(
          'BusControl',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Icono de estadísticas (el de las barritas de tu imagen)
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {},
          ),
          // Perfil del usuario "Carlos Chofer"
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // SECCIÓN DE RESUMEN (Viajes activos, Asientos, Recaudado)
          Container(
            color: const Color(0xFF638541),
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Viajes activos', '2'),
                _buildStatColumn('Asientos vendidos', '8'),
                _buildStatColumn('Recaudado hoy', '\$87'),
              ],
            ),
          ),

          // PESTAÑAS (Activos e Historial)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Activos (2)', true),
                _buildTab('Historial (2)', false),
              ],
            ),
          ),

          // LISTA DE VIAJES (Por ahora solo un mensaje central)
          const Expanded(
            child: Center(
              child: Text(
                'Aquí aparecerán las tarjetas de tus viajes',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),

      // BOTÓN FLOTANTE "NUEVO VIAJE"
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF638541),
        label: const Text('Nuevo viaje', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Función auxiliar para las columnas de estadísticas de arriba
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Función auxiliar para las pestañas
  Widget _buildTab(String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF638541) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? const Color(0xFF638541) : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}