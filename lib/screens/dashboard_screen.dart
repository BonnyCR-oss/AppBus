import 'package:flutter/material.dart';
// Importamos todas las pantallas nuevas
import 'bus_photos_screen.dart'; 
import 'rutas_screen.dart';
import 'venta_screen.dart';
import 'admin_screen.dart';

const String _driverName = 'Carlos Pérez';
const String _driverPhone = '+591 76543210';
const Map<String, String> _driverDetails = {
  'bloodGroup': 'O+',
  'age': '35 años',
  'birthDate': '12 de mayo, 1990',
};

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

  void _mostrarDetallesChofer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF638541),
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(_driverName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Chofer certificado', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const Divider(height: 32),
              _buildDialogInfoRow(Icons.phone, 'Teléfono', _driverPhone),
              _buildDialogInfoRow(Icons.bloodtype_outlined, 'Sangre', _driverDetails['bloodGroup']!),
              _buildDialogInfoRow(Icons.cake_outlined, 'Edad', _driverDetails['age']!),
              _buildDialogInfoRow(Icons.calendar_month_outlined, 'Fecha Nac.', _driverDetails['birthDate']!),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        elevation: 0,
        toolbarHeight: 90, 
        centerTitle: false, 
        title: GestureDetector(
          onTap: () => _mostrarDetallesChofer(context),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_driverName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(_driverPhone, style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        actions: [
          const Center(
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.directions_bus, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.bar_chart, color: Colors.white), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'), 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // BOTÓN 1: RUTAS
              _buildMenuActionButton(
                context,
                title: 'Gestión de Rutas',
                subtitle: 'Iniciar nueva ruta / Ver historial',
                icon: Icons.map,
                color: const Color(0xFF638541),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaRutas())),
              ),
              const SizedBox(height: 24),

              // BOTÓN 2: VENTA
              _buildMenuActionButton(
                context,
                title: 'Venta (Viaje Activo)',
                subtitle: 'Ir a venta del viaje único activo',
                icon: Icons.confirmation_number_outlined,
                color: const Color(0xFFC0A261),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaVenta())),
              ),
              const SizedBox(height: 24),

              // BOTÓN 3: ADMIN
              _buildMenuActionButton(
                context,
                title: 'Administración',
                subtitle: 'Control de usuarios y buses (Dueño)',
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.blueGrey[600]!,
                showLock: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaAdmin())),
              ),
              const SizedBox(height: 24),

              // BOTÓN 4: GALERÍA
              _buildMenuActionButton(
                context,
                title: 'Galería del Bus',
                subtitle: 'Ver fotografías del vehículo',
                icon: Icons.photo_library_outlined,
                color: Colors.teal[600]!,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaFotosBus())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuActionButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, bool showLock = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: color.withAlpha(40), child: Icon(icon, color: color, size: 30)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                Icon(showLock ? Icons.lock_outline : Icons.chevron_right, color: Colors.grey[400], size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$key:', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}