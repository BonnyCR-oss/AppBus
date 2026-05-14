import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/login_controller.dart';
import '../models/usuario_model.dart';
import '../services/session_service.dart';
import '../services/smtp_email_service.dart';
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
  final SmtpEmailService _smtpEmailService = SmtpEmailService();
  bool _iniciandoSesion = false;
  bool _procesandoRecuperacion = false;
  bool _mostrarContrasenia = false;

  String? _codigoRecuperacionPendiente;
  DateTime? _expiracionCodigoRecuperacion;
  UsuarioModel? _usuarioRecuperacionPendiente;

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exitoso', style: TextStyle(color: Colors.green)),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _tomarPrefijo(String valor, int largo) {
    final limpio = valor.replaceAll(RegExp(r'\s+'), '');
    if (limpio.isEmpty) return '';
    if (limpio.length <= largo) return limpio;
    return limpio.substring(0, largo);
  }

  String _generarCodigo4Digitos() {
    return (1000 + Random.secure().nextInt(9000)).toString();
  }

  String _generarContraseniaDesdeUsuario(UsuarioModel usuario) {
    final iniNom = _tomarPrefijo(usuario.nombres, 2).toUpperCase();
    final iniApe = _tomarPrefijo(usuario.apellidos, 2).toUpperCase();

    final ciLimpio = usuario.ci.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final colaCi = ciLimpio.isEmpty
        ? '000'
        : ciLimpio.substring(ciLimpio.length > 3 ? ciLimpio.length - 3 : 0);

    final aleatorio = (100 + Random.secure().nextInt(900)).toString();
    final base = '${iniNom.isEmpty ? 'US' : iniNom}${iniApe.isEmpty ? 'ER' : iniApe}';
    return '$base$colaCi$aleatorio';
  }

  void _limpiarEstadoRecuperacion() {
    _codigoRecuperacionPendiente = null;
    _expiracionCodigoRecuperacion = null;
    _usuarioRecuperacionPendiente = null;
  }

  void _irARecuperarContrasenia() {
    final correoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocalState) {
            return AlertDialog(
              title: const Text('Restablecer contrasenia'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo y te enviaremos un codigo de 4 digitos.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _procesandoRecuperacion
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _procesandoRecuperacion
                      ? null
                      : () async {
                          final email = correoController.text
                              .trim()
                              .toLowerCase();

                          if (email.isEmpty || !email.contains('@')) {
                            _mostrarError('Ingresa un correo valido');
                            return;
                          }

                          setState(() => _procesandoRecuperacion = true);
                          setLocalState(() {});

                          try {
                            final usuario = await _controller
                                .buscarUsuarioPorEmail(email);

                            if (usuario == null) {
                              _mostrarError('No existe una cuenta con ese correo');
                              return;
                            }

                            final codigo = _generarCodigo4Digitos();
                            await _smtpEmailService.enviarCodigoRestablecimiento(
                              to: usuario.email,
                              nombre: usuario.nombreCompleto,
                              codigo: codigo,
                            );

                            _codigoRecuperacionPendiente = codigo;
                            _expiracionCodigoRecuperacion = DateTime.now()
                                .add(const Duration(minutes: 10));
                            _usuarioRecuperacionPendiente = usuario;

                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            _mostrarDialogoVerificarCodigo();
                            _mostrarExito('Codigo enviado. Revisa tu correo.');

                          } on PostgrestException catch (e) {
                            _mostrarError(_controller.mensajeErrorBaseDatos(e));
                          } catch (e) {
                            _mostrarError(
                              'No se pudo enviar el codigo: $e',
                            );
                          } finally {
                            if (mounted) {
                              setState(
                                  () => _procesandoRecuperacion = false);
                              setLocalState(() {});
                            }
                          }
                        },
                  child: _procesandoRecuperacion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar codigo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoVerificarCodigo() {
    final codigoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocalState) {
            Future<void> verificarCodigo() async {
              final codigo = codigoController.text.trim();

              if (codigo.length != 4) {
                _mostrarError('El codigo debe tener 4 digitos');
                return;
              }

              if (_codigoRecuperacionPendiente == null ||
                  _usuarioRecuperacionPendiente == null ||
                  _expiracionCodigoRecuperacion == null) {
                _mostrarError('La solicitud ya no es valida. Intenta otra vez.');
                Navigator.of(dialogContext).pop();
                return;
              }

              if (DateTime.now().isAfter(_expiracionCodigoRecuperacion!)) {
                _limpiarEstadoRecuperacion();
                _mostrarError('El codigo ha expirado. Solicita uno nuevo.');
                Navigator.of(dialogContext).pop();
                return;
              }

              if (codigo != _codigoRecuperacionPendiente) {
                _mostrarError('Codigo incorrecto');
                return;
              }

              setState(() => _procesandoRecuperacion = true);
              setLocalState(() {});

              try {
                final usuario = _usuarioRecuperacionPendiente!;
                final contraseniaNueva = _generarContraseniaDesdeUsuario(usuario);

                final hashAnterior = usuario.password;
                final hashNuevo =
                    _controller.generarHashContrasenia(contraseniaNueva);

                await _controller.actualizarContraseniaUsuarioHash(
                  usuarioId: usuario.id,
                  hashContrasenia: hashNuevo,
                );

                try {
                  await _smtpEmailService.enviarNuevaContraseniaRestablecida(
                    to: usuario.email,
                    nombre: usuario.nombreCompleto,
                    contrasenia: contraseniaNueva,
                  );
                } catch (e) {
                  await _controller.actualizarContraseniaUsuarioHash(
                    usuarioId: usuario.id,
                    hashContrasenia: hashAnterior,
                  );
                  rethrow;
                }

                _limpiarEstadoRecuperacion();
                if (!mounted || !dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();
                _mostrarExito('Contrasenia restablecida y enviada a tu correo.');

              } catch (e) {
                _mostrarError('No se pudo completar el restablecimiento: $e');
              } finally {
                if (mounted) {
                  setState(() => _procesandoRecuperacion = false);
                  setLocalState(() {});
                }
              }
            }

            return AlertDialog(
              title: const Text('Verificar codigo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa el codigo de 4 digitos para continuar.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codigoController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Codigo',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.trim().length == 4 && !_procesandoRecuperacion) {
                        verificarCodigo();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _procesandoRecuperacion
                      ? null
                      : () {
                          _limpiarEstadoRecuperacion();
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _procesandoRecuperacion ? null : verificarCodigo,
                  child: _procesandoRecuperacion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar codigo'),
                ),
              ],
            );
          },
        );
      },
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
        telefonoUsuario: usuario.contacto,
        rolUsuarioId: usuario.fkRol,
        usuarioId: usuario.id,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(
            nombreUsuario: usuario.nombreCompleto,
            telefonoUsuario: usuario.contacto,
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
                  borderRadius: BorderRadius.circular(100),
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
                        obscureText: !_mostrarContrasenia,
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarContrasenia ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF638541),
                            ),
                            onPressed: () {
                              setState(() {
                                _mostrarContrasenia = !_mostrarContrasenia;
                              });
                            },
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
