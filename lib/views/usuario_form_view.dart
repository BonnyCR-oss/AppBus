import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _contactoCtrl = TextEditingController();
  String _rolSeleccionado = 'Vendedor';
  bool _estaActivo = true;
  bool get esEdicion => widget.usuarioActual != null;
  
  final UsuarioFormController _controller = UsuarioFormController();
  bool _estaGuardando = false;

  String? _validarCampos() {
    final nombres = _nombresCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    final ci = _ciCtrl.text.trim();
    final contacto = _contactoCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (nombres.isEmpty ||
        apellidos.isEmpty ||
        ci.isEmpty ||
        email.isEmpty) {
      return 'Completa todos los campos obligatorios.';
    }

    if (nombres.length < 2 || apellidos.length < 2) {
      return 'Nombres y apellidos deben tener al menos 2 caracteres.';
    }

    final regexNombre = RegExp(r'^[A-Za-z ]+$');
    if (!regexNombre.hasMatch(nombres) || !regexNombre.hasMatch(apellidos)) {
      return 'Nombres y apellidos solo pueden contener letras y espacios.';
    }

    final regexCi = RegExp(r'^[0-9]{6,14}$');
    if (!regexCi.hasMatch(ci)) {
      return 'El CI debe contener solo numeros (entre 6 y 14 digitos).';
    }
    final regexContacto = RegExp(r'^[0-9]{8,8}$');
    if (!regexContacto.hasMatch(contacto)){
      return 'El numero de celular debe tener 8 numeros. ';
    }

    final regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regexEmail.hasMatch(email)) {
      return 'Ingresa un correo electronico valido.';
    }

    if (!['Admin', 'Vendedor'].contains(_rolSeleccionado)) {
      return 'Selecciona un rol valido.';
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    if (esEdicion) {
      final user = widget.usuarioActual!;
      _nombresCtrl.text = user.nombres;
      _apellidosCtrl.text = user.apellidos;
      _ciCtrl.text = user.ci;
      _contactoCtrl.text = user.contacto;
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
    _contactoCtrl.dispose();
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
    final errorValidacion = _validarCampos();
    if (errorValidacion != null) {
      await _mostrarModal(
        titulo: 'Validacion',
        mensaje: errorValidacion,
      );
      return;
    }

    setState(() => _estaGuardando = true);

    try {
      await _controller.guardarUsuario(
        id: widget.usuarioActual?.id,
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        ci: _ciCtrl.text.trim(),
        contacto: _contactoCtrl.text.trim(),
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

        await _mostrarModal(
          titulo: 'Usuario creado',
          mensaje:
              'La contrasenia temporal fue enviada al correo del usuario.',
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
            TextField(
              controller: _nombresCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
              ],
              decoration: _inputDecoration('Nombres'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidosCtrl,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
              ],
              decoration: _inputDecoration('Apellidos'),
            ),
            const SizedBox(height: 16),
      
            TextField(
              controller: _contactoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              decoration: _inputDecoration('telefono'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ciCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                    ],
                    decoration: _inputDecoration('CI'),
                  ),
                ),
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
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration('Email'),
            ),
            
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
                        'La contrasenia se generara automaticamente y se enviara al correo del usuario.',
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