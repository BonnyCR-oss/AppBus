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

class MiAppDeBuses extends StatelessWidget {
  const MiAppDeBuses({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Claros - Gestión de Viajes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF638541)),
        useMaterial3: true,
      ),
      home: const SplashView(),
    );
  }
}
