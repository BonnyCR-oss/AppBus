import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import '../services/session_service.dart';
import 'login_view.dart';
import 'main_shell.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _resolverNavegacionInicial();
  }

  Future<void> _resolverNavegacionInicial() async {
    await Future.delayed(const Duration(seconds: 2));
    final sesion = await _sessionService.leerSesion();
    if (!mounted) return;

    if (sesion != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(
            nombreUsuario: sesion.nombreUsuario,
            contactoUsuario: sesion.contactoUsuario,
            rolUsuarioId: sesion.rolUsuarioId,
            rolDuenoId: LoginController.rolDuenoId,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/LogoApp.png',
          width: 250,
        ),
      ),
    );
  }
}
