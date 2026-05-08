import 'package:flutter/material.dart';
import '../models/usuario_model.dart';

class UsuarioFormView extends StatefulWidget {
  // recibe el modelo si es null sabemos que es un Nuevo Usuario.
  final UsuarioModel? usuarioActual;

  const UsuarioFormView({super.key, this.usuarioActual});

  @override
  State<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends State<UsuarioFormView> {
  @override
  Widget build(BuildContext context) {
    
    // Variable auxiliar para saber en que modo estamos
    final esEdicion = widget.usuarioActual != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          esEdicion ? 'Editar Usuario' : 'Añadir Usuario',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            esEdicion
                ? 'Aquí trabajaremos el formulario para editar a:\n\n${widget.usuarioActual!.nombreCompleto}\n(CI: ${widget.usuarioActual!.ci})'
                : 'Aquí trabajaremos el formulario vacío para crear un Nuevo Usuario.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}