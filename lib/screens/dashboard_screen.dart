import 'package:flutter/material.dart';

// Definimos unos datos falsos (mock) para el chofer de ejemplo
// En el futuro, estos vendrán de la base de datos Supabase
const String _driverName = 'Carlos Pérez';
const String _driverPhone = '+591 76543210';
const Map<String, String> _driverDetails = {
  'bloodGroup': 'O+',
  'age': '35 años',
  'birthDate': '12 de mayo, 1990',
};

class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key});

  // FUNCIÓN AUXILIAR: Muestra el diálogo detallado del chofer (Mini ventanita)
  void _mostrarDetallesChofer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Bordes redondeados profesionales
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // El diálogo se ajusta al contenido
            children: [
              // 1. Fotito del Chofer (Placeholder por ahora)
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF638541),
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              // 2. Nombre completo
              const Text(
                _driverName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Chofer certificado',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Divider(height: 32), // Línea divisoria

              // 3. Datos detallados en formato clave-valor
              _buildDialogInfoRow(Icons.phone, 'Teléfono', _driverPhone),
              _buildDialogInfoRow(Icons.bloodtype_outlined, 'Sangre', _driverDetails['bloodGroup']!),
              _buildDialogInfoRow(Icons.cake_outlined, 'Edad', _driverDetails['age']!),
              _buildDialogInfoRow(Icons.calendar_month_outlined, 'Fecha Nac.', _driverDetails['birthDate']!),
            ],
          ),
          // Botón para cerrar
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo claro
      backgroundColor: const Color(0xFFF9FAF7),
      
      // BARRA SUPERIOR VERDE REDISEÑADA (AppBar profunda)
      // BARRA SUPERIOR VERDE REDISEÑADA
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        elevation: 0,
        toolbarHeight: 90, 
        
        // 1. Alineamos el nombre y celular a la izquierda
        centerTitle: false, 
        
        title: GestureDetector(
          onTap: () => _mostrarDetallesChofer(context),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _driverName, 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                _driverPhone, 
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        
        // 2. Colocamos el logo y los iconos en las 'actions' (A la derecha)
        actions: [
          // LOGO DEL BUS (Ahora a la derecha)
          Center(
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              // Cuando tengas tu imagen real, cambiarás el Icon por:
              // child: Image.asset('assets/images/mi_logo.png'),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16), // Espacio entre el logo y los iconos
          
          // Icono de estadísticas
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () {},
          ),
          // Botón de salir (logout)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); 
            },
          ),
          const SizedBox(width: 8), // Margen final
        ],
      ),

      // CUERPO CENTRAL DE LA PANTALLA (Donde van las B)
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Espacio alrededor de los botones
          child: Column(
            children: [
              // 1. BOTÓN PRINCIPAL 1: GESTIÓN DE RUTAS
              _buildMenuActionButton(
                context,
                title: 'Gestión de Rutas',
                subtitle: 'Iniciar nueva ruta / Ver historial',
                icon: Icons.map,
                color: const Color(0xFF638541),
                onTap: () {
                  // Navegar a la futura pantalla de Rutas
                  debugPrint('Ir a Gestión de Rutas');
                },
              ),
              const SizedBox(height: 24), // Espacio

              // 2. BOTÓN PRINCIPAL 2: VENTA DE VIAJE ACTIVO
              _buildMenuActionButton(
                context,
                title: 'Venta (Viaje Activo)',
                subtitle: 'Ir a venta del viaje único activo',
                icon: Icons.confirmation_number_outlined,
                color: const Color(0xFFC0A261), // Color secundario distintivo
                onTap: () {
                  // Navegar a la venta del viaje activo
                  debugPrint('Ir a Venta Activa');
                },
              ),
              const SizedBox(height: 24),

              // 3. BOTÓN PRINCIPAL 3: ADMINISTRACIÓN (ROL DUEÑO)
              _buildMenuActionButton(
                context,
                title: 'Administración',
                subtitle: 'Control de usuarios y buses (Dueño)',
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.blueGrey[600]!,
                showLock: true, // Muestra el candadito
                onTap: () {
                  // Diálogo de aviso de ROL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acceso permitido solo para el Dueño')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FUNCIÓN AUXILIAR: Construye los botones de acción del menú principal
  Widget _buildMenuActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showLock = false, // Muestra u oculta el candado
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Sombra suave profesional
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, // Acción al tocar
          borderRadius: BorderRadius.circular(20), // Efecto de onda redondeado
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icono grande en circulo
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withAlpha(40),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Flechita de acción o candado
                if (showLock)
                  const Icon(Icons.lock_outline, color: Colors.blueGrey, size: 24)
                else
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FUNCIÓN AUXILIAR: Fila de información para el diálogo del chofer
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