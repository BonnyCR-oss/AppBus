import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'views/splash_view.dart';

const String _supabaseUrl = 'https://ndxsenuscxmwpvjudzni.supabase.co';
const String _supabaseAnonKey = 'sb_publishable_Yl-K7t4yc-Khy_nF_akqSw_5XjDifu9';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const MiAppDeBuses());
}

class MiAppDeBuses extends StatefulWidget {
  const MiAppDeBuses({super.key});

  @override
  State<MiAppDeBuses> createState() => _MiAppDeBusesState();
}

class _MiAppDeBusesState extends State<MiAppDeBuses>
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _verificacionPeriodica;
  bool _sinConexion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarConexion();
  }

  Future<void> _inicializarConexion() async {
    await _refrescarEstadoConexion();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _refrescarEstadoConexion();
    });

    // Fallback para dispositivos donde el stream no notifica todos los cambios.
    _verificacionPeriodica = Timer.periodic(const Duration(seconds: 4), (_) {
      _refrescarEstadoConexion();
    });
  }

  Future<bool> _tieneInternetReal() async {
    const hosts = ['google.com', 'one.one.one.one'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Intentamos con el siguiente host.
      }
    }
    return false;
  }

  Future<void> _refrescarEstadoConexion() async {
    final current = await _connectivity.checkConnectivity();
    final hayInternet = await _tieneInternetReal();
    final sinConexion =
        current.contains(ConnectivityResult.none) || !hayInternet;

    if (!mounted || _sinConexion == sinConexion) return;
    setState(() {
      _sinConexion = sinConexion;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refrescarEstadoConexion();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _verificacionPeriodica?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorBase = Color(0xFF638541);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Claros - Gestion de Viajes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: colorBase),
        useMaterial3: true,
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE3E8DD)),
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFF1F2A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          contentTextStyle: const TextStyle(
            color: Color(0xFF2F3A2A),
            fontSize: 14,
            height: 1.35,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4D5A44),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorBase,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9F4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DECC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DECC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorBase, width: 1.6),
          ),
          labelStyle: const TextStyle(color: Color(0xFF4A5640)),
        ),
      ),
      home: const SplashView(),
      builder: (context, child) {
        final contenido = child ?? const SizedBox.shrink();
        if (!_sinConexion) return contenido;

        return Stack(
          children: [
            contenido,
            _OfflineView(onRetry: _refrescarEstadoConexion),
          ],
        );
      },
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAF7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5E9),
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: Color(0xFF638541),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sin conexion a internet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2A1A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Conectate a internet o verifica tu conexion para continuar usando la app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5640),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF638541),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
