import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../widgets/bottom_navbar.dart';
import 'bus_photos_view.dart';
import 'login_view.dart';
import 'reports_view.dart';
import 'rutas_view.dart';
import 'viajes_view.dart';
import 'venta_view.dart';
import 'usuarios_list_view.dart';

class MainShell extends StatefulWidget {
  final String nombreUsuario;
  final String contactoUsuario;
  final int rolUsuarioId;
  final int rolDuenoId;

  const MainShell({
    super.key,
    required this.nombreUsuario,
    required this.contactoUsuario,
    required this.rolUsuarioId,
    required this.rolDuenoId,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late List<BottomNavItem> _navItems;
  final SessionService _sessionService = SessionService();

  bool get _esDueno => widget.rolUsuarioId == widget.rolDuenoId;

  @override
  void initState() {
    super.initState();
    _buildNavItems();
  }

  void _buildNavItems() {
    _navItems = [];

    // Venta (siempre disponible)
    _navItems.add(
      BottomNavItem(
        label: 'Venta',
        icon: Icons.confirmation_number_outlined,
        onTap: () => setState(() => _currentIndex = 0),
      ),
    );

    // Rutas (siempre disponible)
    _navItems.add(
      BottomNavItem(
        label: 'Rutas',
        icon: Icons.map,
        onTap: () => setState(() => _currentIndex = 1),
      ),
    );

    // Viajes (por implementar)
    _navItems.add(
      BottomNavItem(
        label: 'Viajes',
        icon: Icons.route_outlined,
        onTap: () => setState(() => _currentIndex = 2),
      ),
    );

    // Galería (siempre disponible)
    _navItems.add(
      BottomNavItem(
        label: 'Galería',
        icon: Icons.photo_library_outlined,
        onTap: () => setState(() => _currentIndex = 3),
      ),
    );

    // Admin (solo para dueños)
    if (_esDueno) {
      _navItems.add(
        BottomNavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          onTap: () => setState(() => _currentIndex = 4),
        ),
      );
    }
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0:
        return const VentaView();
      case 1:
        return RutasView(esAdmin: _esDueno);
      case 2:
        return ViajesView(esAdmin: _esDueno);
      case 3:
        return const BusPhotosView();
      case 4:
        if (_esDueno) return const UsuariosListView();
        return const VentaView();
      default:
        return const VentaView();
    }
  }

  void _mostrarDetallesChofer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF638541),
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(widget.nombreUsuario,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                _esDueno ? 'Administrador' : 'Vendedor',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Divider(height: 32),
              _buildDialogInfoRow(Icons.phone, 'Contacto', widget.contactoUsuario),
              _buildDialogInfoRow(
                  Icons.email_outlined, 'Email', widget.contactoUsuario),
              _buildDialogInfoRow(
                  Icons.verified_user_outlined, 'Estado', 'Activo'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$key:',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF638541),
          elevation: 0,
          toolbarHeight: 90,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () => _mostrarDetallesChofer(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nombreUsuario,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(widget.contactoUsuario,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          actions: [
            const Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.directions_bus,
                    color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            if (_esDueno)
              IconButton(
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                onPressed: () {
                  if (!_esDueno) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportsView()),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await _sessionService.limpiarSesion();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildCurrentView(),
        bottomNavigationBar: Container(
        color: const Color(0xFF638541),
        child: SafeArea(
          child: CustomBottomNavBar(
            currentIndex: _currentIndex,
            items: _navItems,
            backgroundColor: const Color(0xFF638541),
            activeColor: Colors.white,
            inactiveColor: Colors.white54,
          ),
        ),
      ),
      ),
    );
  }
}
