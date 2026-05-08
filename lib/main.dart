import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart'; // Asegúrate de que esta ruta coincida con tu archivo

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
      home: const PantallaLogin(),
    );
  }
}

// AHORA ES UN STATEFUL WIDGET: Esto nos permite manejar variables que cambian (como el texto)
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // 1. Controladores: Estas variables son las "pinzas" que atrapan el texto
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _estadoConexion = 'Sin comprobar';
  bool _probandoConexion = false;

  // 2. La función que simulará tu backend por ahora
  void _iniciarSesion() {
    // Obtenemos el texto exacto que escribió el usuario
    String usuarioEscrito = _usuarioController.text;
    String passwordEscrita = _passwordController.text;

    // --- AQUÍ IRÁ TU CÓDIGO HTTP POST HACIA C# Y SQL SERVER ---
    
    // Por ahora, usamos un IF para simular que el servidor nos dio luz verde
    if ((usuarioEscrito == 'Carlos' || usuarioEscrito == 'Ana') && passwordEscrita == '1234') {
      // Todo es correcto -> Navegamos al Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaDashboard()),
      );
    } else {
      // Algo falló -> Mostramos un mensaje de error estilo "pop-up" abajo (SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _probarConexionSupabase() async {
    setState(() {
      _probandoConexion = true;
      _estadoConexion = 'Probando...';
    });

    try {
      // Usamos el cliente Supabase ya inicializado para comprobar la conexión
      Supabase.instance.client.auth.currentSession;
      setState(() {
        _estadoConexion = '✓ Conexión exitosa con Supabase';
      });
    } catch (e) {
      setState(() {
        _estadoConexion = 'Error: $e';
      });
    } finally {
      setState(() {
        _probandoConexion = false;
      });
    }
  }

  // 3. Buenas prácticas: Liberar memoria cuando la pantalla se cierre
  @override
  void dispose() {
    _usuarioController.dispose();
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
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF95A781),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.directions_bus_filled_outlined, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Bus Claros', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Gestión de viajes', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                      const Text('Iniciar sesión', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // --- CAMPO USUARIO ---
                      const Text('Usuario', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usuarioController, // Vinculamos la "pinza" al campo
                        decoration: InputDecoration(
                          hintText: 'Carlos o Ana',
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
                        controller: _passwordController, // Vinculamos la "pinza" al campo
                        obscureText: true,
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
                          onPressed: _iniciarSesion, // Ejecutamos la función de validación
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF638541),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Ingresar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _probandoConexion ? null : _probarConexionSupabase,
                          child: Text(
                            _probandoConexion
                                ? 'Probando conexión...'
                                : 'Probar conexión Supabase',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estado Supabase: $_estadoConexion',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      
                      Center(
                        child: Text(
                          'Demo: Carlos (chofer) - Ana (vendedora) - clave 1234',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

