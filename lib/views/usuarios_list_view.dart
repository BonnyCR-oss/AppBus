import 'package:flutter/material.dart';
import '../controllers/usuarios_controller.dart';
import '../models/usuario_model.dart';
//pantalla nuevaa
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

  Future<void> _mostrarModal({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarEliminacion(UsuarioModel usuario) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Deseas eliminar a ${usuario.nombreCompleto}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  Future<void> _eliminarUsuario(UsuarioModel usuario) async {
    final confirmado = await _confirmarEliminacion(usuario);
    if (!confirmado) return;

    try {
      await _controller.eliminarUsuarioPorId(usuario.id);
      await _cargarDatos();
      await _mostrarModal(
        titulo: 'Usuario eliminado',
        mensaje: 'El usuario fue eliminado correctamente.',
      );
    } catch (e) {
      await _mostrarModal(
        titulo: 'Error',
        mensaje: e.toString(),
      );
    }
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
        await _mostrarModal(titulo: 'Error', mensaje: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _estaCargando = false);
      }
    }
  }
    

  Future<void> _irAlFormulario({UsuarioModel? usuario}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        // Le pasamos el usuario (puede ir lleno o null)
        builder: (context) => UsuarioFormView(usuarioActual: usuario),
      ),
    );

    if (!mounted) return;

    if (resultado is Map<String, dynamic>) {
      final aviso = resultado['aviso']?.toString();
      if (aviso != null && aviso.isNotEmpty) {
        await _mostrarModal(titulo: 'Aviso', mensaje: aviso);
      }
      if (resultado['recargar'] == true) {
        await _cargarDatos();
      }
      return;
    }

    if (resultado == true) {
      await _cargarDatos();
    }
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
                    trailing: IconButton(
                      tooltip: 'Eliminar usuario',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _eliminarUsuario(usuario),
                    ),
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