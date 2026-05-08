import 'package:flutter/material.dart';
import '../controllers/usuarios_controller.dart';
import '../models/usuario_model.dart';
import 'usuario_form_view.dart'; 

class UsuariosListView extends StatefulWidget {
  const UsuariosListView({super.key});

  @override
  State<UsuariosListView> createState() => _UsuariosListViewState();
}

class _UsuariosListViewState extends State<UsuariosListView> {
  final UsuariosController _controller = UsuariosController();
  
  List<UsuarioModel> _usuarios = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _estaCargando = true);
    try {
      final usuariosObtenidos = await _controller.obtenerUsuarios();
      setState(() {
        _usuarios = usuariosObtenidos;
      });
    } catch (e) {
      

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }
    

  void _irAlFormulario({UsuarioModel? usuario}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Le pasamos el usuario (puede ir lleno o null)
        builder: (context) => UsuarioFormView(usuarioActual: usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Gestión de Usuarios', style: TextStyle(color: Colors.white)),
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF638541)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Al tocar la tarjeta, pasamos los datos de ESTE usuario
                    onTap: () => _irAlFormulario(usuario: usuario),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF638541).withAlpha(40),
                      child: Icon(
                        usuario.nombreRol.toLowerCase() == 'admin' ? Icons.admin_panel_settings : Icons.person,
                        color: const Color(0xFF638541),
                      ),
                    ),
                    title: Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    subtitle: Text('CI: ${usuario.ci} • Rol: ${usuario.nombreRol}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        // Al tocar Nuevo, NO pasamos usuario (es null por defecto)
        onPressed: () => _irAlFormulario(),
        backgroundColor: const Color(0xFF638541),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}