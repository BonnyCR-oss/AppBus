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

class _SplashViewState extends State<SplashView>
  with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    _controller.forward();
    _resolverNavegacionInicial();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/LogoApp.png',
              width: 250,
            ),
          ),
        ),
      ),
    );
  }
}
