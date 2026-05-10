import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../controllers/usuario_form_controller.dart';

class UsuarioFormView extends StatefulWidget {
  final UsuarioModel? usuarioActual;

  const UsuarioFormView({super.key, this.usuarioActual});

  @override
  State<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends State<UsuarioFormView> {
  final TextEditingController _nombresCtrl = TextEditingController();
  final TextEditingController _apellidosCtrl = TextEditingController();
  final TextEditingController _ciCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  
  String _rolSeleccionado = 'Vendedor';
  bool _estaActivo = true;
  bool get esEdicion => widget.usuarioActual != null;
  
  final UsuarioFormController _controller = UsuarioFormController();
  bool _estaGuardando = false;

  @override
  void initState() {
    super.initState();
    if (esEdicion) {
      final user = widget.usuarioActual!;
      _nombresCtrl.text = user.nombres;
      _apellidosCtrl.text = user.apellidos;
      _ciCtrl.text = user.ci;
      _emailCtrl.text = user.email;
      _estaActivo = user.estaActivo; 
      
      final rolBD = user.nombreRol.toLowerCase();
      if (rolBD == 'admin') {
        _rolSeleccionado = 'Admin';
      } else {
        _rolSeleccionado = 'Vendedor';
      }
    }
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _ciCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
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

  Future<void> _guardar() async {
    if (_nombresCtrl.text.isEmpty ||
        _apellidosCtrl.text.isEmpty ||
        _ciCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty) {
      await _mostrarModal(
        titulo: 'Campos requeridos',
        mensaje: 'Completa todos los campos obligatorios.',
      );
      return;
    }

    setState(() => _estaGuardando = true);

    try {
      final aviso = await _controller.guardarUsuario(
        id: widget.usuarioActual?.id,
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        ci: _ciCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        rolSeleccionado: _rolSeleccionado,
        estaActivo: _estaActivo,
      );

      if (mounted) {
        if (esEdicion) {
          await _mostrarModal(
            titulo: 'Actualización exitosa',
            mensaje: 'Usuario actualizado correctamente.',
          );
          if (!mounted) return;
          Navigator.pop(context, true);
          return;
        }

        final contraseniaGenerada = aviso ?? '';
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usuario creado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contrasenia generada:'),
                const SizedBox(height: 8),
                SelectableText(
                  contraseniaGenerada,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Guardala para entregarla al usuario.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        await _mostrarModal(
          titulo: 'Error',
          mensaje: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _estaGuardando = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label, hintText: hint, filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(esEdicion ? 'Editar Usuario' : 'Añadir Usuario', style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _nombresCtrl, decoration: _inputDecoration('Nombres')),
            const SizedBox(height: 16),
            TextField(controller: _apellidosCtrl, decoration: _inputDecoration('Apellidos')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _ciCtrl, decoration: _inputDecoration('CI'))),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _rolSeleccionado,
                    decoration: _inputDecoration('Rol'),
                    items: ['Admin', 'Vendedor'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _rolSeleccionado = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl, decoration: _inputDecoration('Email')),
            
            const SizedBox(height: 24),
            
            // Aviso sobre contraseña automática
            if (!esEdicion)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF638541).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF638541), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF638541),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La contrasenia se generara automaticamente y se mostrara al guardar.',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('¿Usuario Activo?'),
                subtitle: Text(_estaActivo ? 'Puede entrar a la app' : 'Acceso bloqueado'),
                value: _estaActivo,
                activeThumbColor: const Color(0xFF638541),
                onChanged: esEdicion ? (val) => setState(() => _estaActivo = val) : null,
                secondary: Icon(_estaActivo ? Icons.check_circle : Icons.cancel, color: _estaActivo ? Colors.green : Colors.red),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _estaGuardando ? null : _guardar,
                icon: _estaGuardando ? const CircularProgressIndicator() : const Icon(Icons.save),
                label: const Text('GUARDAR'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638541), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}