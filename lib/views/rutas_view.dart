import 'package:flutter/material.dart';
import '../models/ruta_model.dart';
import '../models/viaje_model.dart';
import '../controllers/ruta_controller.dart';
import '../controllers/viaje_controller.dart';

class RutasView extends StatefulWidget {
  const RutasView({super.key});

  @override
  State<RutasView> createState() => _RutasViewState();
}

class _RutasViewState extends State<RutasView> {
  final RutaController _rutaController = RutaController();
  final ViajeController _viajeController = ViajeController();
  
  List<RutaModel> _rutas = [];
  ViajeModel? _viajeActual;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  // Carga tanto los precios como el semáforo del viaje actual
  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final rutas = await _rutaController.obtenerRutas();
      final viaje = await _viajeController.obtenerViajeActivo();
      setState(() {
        _rutas = rutas;
        _viajeActual = viaje;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirViajeConSeleccion(int idRuta) async {


    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Selecciona la fecha de salida',
    );

    if (fecha == null) return;

    if (!mounted) return;
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecciona la hora de salida',
    );

    if (hora == null) return; 

    // 3. Formatear para Postgres (YYYY-MM-DD y HH:MM:SS)
    final fechaStr = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    final horaStr = "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00";

    // 4. Guardar en la Base de Datos
    setState(() => _cargando = true);
    try {
      await _viajeController.abrirNuevoViaje(
        idRuta: idRuta,
        idAdmin: 3,
        idBus: 1, 
        fechaSalida:fechaStr,
        horaSalida: horaStr,
      );
      await _cargarTodo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Viaje programado con éxito!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _cargando = false);
    }
  }

  Future<void> _cerrarViaje() async {
    setState(() => _cargando = true);
    try {
      await _viajeController.finalizarViajeActivo();
      await _cargarTodo();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viaje finalizado'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _cargando = false);
    }
  }

  void _mostrarDialogoEdicion(RutaModel ruta) {
    final TextEditingController precioCtrl = TextEditingController(text: ruta.precio.toString());
    
    showDialog(
      context: context, 
      
      builder: (dialogContext) => AlertDialog(
        title: const Text('Actualizar Precio Base'),
        content: TextField(
          controller: precioCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Nuevo Precio', prefixText: 'Bs. '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('CANCELAR')
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevoPrecio = double.tryParse(precioCtrl.text);
              if (nuevoPrecio != null && nuevoPrecio > 0) {
                
                Navigator.pop(dialogContext);
                
                setState(() => _cargando = true);
                try {
                  await _rutaController.actualizarPrecio(ruta.id, nuevoPrecio);
                  await _cargarTodo();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
                    );
                  }
                } finally {
                  if (mounted) setState(() => _cargando = false); 
                }
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        title: const Text('Gestión de Rutas y Viajes', style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF638541)))
          : RefreshIndicator(
              onRefresh: _cargarTodo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    const Text('ESTADO ACTUAL DEL BUS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _viajeActual != null ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _viajeActual != null ? Colors.green : Colors.red),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _viajeActual != null ? Icons.directions_bus : Icons.bus_alert,
                            size: 40,
                            color: _viajeActual != null ? Colors.green.shade800 : Colors.red.shade800,
                          ),

                          const SizedBox(height: 8),
                          Text(
                            _viajeActual != null 
                                ? 'Ventas Abiertas:\n${_rutas.firstWhere((r) => r.id == _viajeActual!.fkRuta).origen} ➔ ${_rutas.firstWhere((r) => r.id == _viajeActual!.fkRuta).destino}' 
                                : 'Ventas Cerradas.\nNingún bus está cargando pasajeros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: _viajeActual != null ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Botones que cambian según el estado
                          if (_viajeActual == null) ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Iniciar Quillacollo ➔ St. Domingo'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638541), foregroundColor: Colors.white),
                              onPressed: () => _abrirViajeConSeleccion(1), // Asegúrate que 1 sea el ID correcto
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Iniciar St. Domingo ➔ Quillacollo'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638541), foregroundColor: Colors.white),
                              onPressed: () => _abrirViajeConSeleccion(2), // Asegúrate que 2 sea el ID correcto
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.stop),
                              label: const Text('FINALIZAR ESTE VIAJE'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: _cerrarViaje,
                            ),
                          ]
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    const Text('PRECIOS BASE DE LAS RUTAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ..._rutas.map((ruta) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('${ruta.origen} ➔ ${ruta.destino}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Precio de extremo a extremo: Bs. ${ruta.precio}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF638541)),
                              onPressed: () => _mostrarDialogoEdicion(ruta),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}