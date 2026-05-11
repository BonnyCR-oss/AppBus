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
    const colorBase = Color(0xFF638541);
    return MaterialApp(
      title: 'Bus Claros - Gesti�n de Viajes',
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
    );
  }
}
