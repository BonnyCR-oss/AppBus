import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/login_controller.dart';
import '../services/session_service.dart';
import 'main_shell.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginController _controller = LoginController();
  final SessionService _sessionService = SessionService();
  bool _iniciandoSesion = false;

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _irARecuperarContrasenia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente: recuperación de contraseña por correo.'),
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _mostrarError('Completa email y contraseña');
      return;
    }

    setState(() => _iniciandoSesion = true);

    try {
      final usuario = await _controller.buscarUsuarioPorEmail(email);

      if (usuario == null) {
        _mostrarError('Usuario no encontrado');
        return;
      }

      if (!_controller.validarPassword(password, usuario.password)) {
        _mostrarError('Usuario o contraseña incorrectos');
        return;
      }
      if (!usuario.estaActivo) {
        _mostrarError('Tu cuenta está inactiva. Contacta al administrador.');
        return;
      }

      await _sessionService.guardarSesion(
        nombreUsuario: usuario.nombreCompleto,
        contactoUsuario: usuario.email,
        rolUsuarioId: usuario.fkRol,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            nombreUsuario: usuario.nombreCompleto,
            contactoUsuario: usuario.email,
            rolUsuarioId: usuario.fkRol,
            rolDuenoId: LoginController.rolDuenoId,
          ),
        ),
      );
    } on PostgrestException catch (e) {
      _mostrarError(_controller.mensajeErrorBaseDatos(e));
    } catch (_) {
      _mostrarError('No se pudo iniciar sesión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _iniciandoSesion = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF638541),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- SECCIÓN LOGO Y TÍTULO ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF95A781),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset('assets/images/icono.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              const Text('Bus Claros',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const Text('Gestión de viajes',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 60),

              // --- SECCIÓN TARJETA DEL FORMULARIO ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Iniciar sesión',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // --- CAMPO EMAIL ---
                      const Text('Email', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'tu@email.com',
                          filled: true,
                          fillColor: const Color(0xFFEEF3E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- CAMPO CONTRASEÑA ---
                      const Text('Contraseña', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            _iniciandoSesion ? null : _iniciarSesion(),
                        decoration: InputDecoration(
                          hintText: '....',
                          filled: true,
                          fillColor: const Color(0xFFEEF3E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- BOTÓN INGRESAR ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _iniciandoSesion ? null : _iniciarSesion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF638541),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _iniciandoSesion
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Ingresar',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _irARecuperarContrasenia,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),

                      Center(
                        child: Text(
                          'Ingresa con tu correo electrónico',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
