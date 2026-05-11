import 'package:flutter/material.dart';

import '../controllers/ruta_controller.dart';
import '../controllers/viaje_controller.dart';
import '../models/ruta_model.dart';
import '../models/viaje_model.dart';
import '../services/session_service.dart';

class ViajesView extends StatefulWidget {
  const ViajesView({
    super.key,
    required this.esAdmin,
  });

  final bool esAdmin;

  @override
  State<ViajesView> createState() => _ViajesViewState();
}

class _ViajesViewState extends State<ViajesView> {
  final ViajeController _viajeController = ViajeController();
  final RutaController _rutaController = RutaController();
  final SessionService _sessionService = SessionService();

  List<ViajeModel> _viajesHoy = [];
  List<ViajeModel> _historial = [];
  List<RutaModel> _rutas = [];
  bool _cargando = true;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final sesion = await _sessionService.leerSesion();
      final viajesHoy = await _viajeController.obtenerViajesActivos();
      final rutas = widget.esAdmin ? await _rutaController.obtenerRutas() : <RutaModel>[];
      final historial = widget.esAdmin
          ? await _viajeController.obtenerHistorialViajes()
          : <ViajeModel>[];

      if (!mounted) return;
      setState(() {
        _usuarioId = sesion?.usuarioId;
        _viajesHoy = viajesHoy;
        _rutas = rutas;
        _historial = historial;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatearHora(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    return '${partes[0]}:${partes[1]}';
  }

  Color _colorEstado(String estado) {
    final value = estado.toLowerCase();
    if (value == 'en marcha' || value == 'activo') return Colors.green;
    if (value == 'finalizado') return Colors.grey;
    return Colors.orange;
  }

  Future<void> _cambiarEstadoViaje(int idViaje, String nuevoEstado) async {
    setState(() => _cargando = true);
    try {
      await _viajeController.actualizarEstadoViaje(idViaje, nuevoEstado);
      await _cargarDatos(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a "$nuevoEstado"'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
        setState(() => _cargando = false);
      }
    }
  }

  Widget _buildListaViajes(List<ViajeModel> viajes, {required String emptyText}) {
    if (viajes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          emptyText,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: viajes.map((viaje) {
        
        Widget widgetEstado = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _colorEstado(viaje.estado).withAlpha(35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            viaje.estado,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _colorEstado(viaje.estado),
            ),
          ),
        );

        if (widget.esAdmin) {
          widgetEstado = PopupMenuButton<String>(
            initialValue: viaje.estado,
            tooltip: 'Cambiar estado',
            onSelected: (nuevoEstado) {
              if (nuevoEstado != viaje.estado) {
                _cambiarEstadoViaje(viaje.id, nuevoEstado);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Programado', child: Text('Programado')),
              const PopupMenuItem(value: 'En marcha', child: Text('En marcha')),
              const PopupMenuItem(value: 'Finalizado', child: Text('Finalizado')),
            ],
            child: widgetEstado,
          );
        }

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              '${viaje.origenRuta ?? 'Ruta ${viaje.fkRuta}'} ➔ ${viaje.destinoRuta ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Fecha: ${viaje.fechaSalida}  Hora: ${_formatearHora(viaje.horaSalida)}\nBus: ${viaje.fkBus ?? '-'}',
            ),
            trailing: widgetEstado, // Aquí insertamos nuestro widget dinámico
          ),
        );
      }).toList(),
    );
  }

  Future<void> _mostrarDialogoCrearViaje() async {
    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar al admin actual. Cierra sesión e inicia de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rutas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay rutas disponibles para crear viajes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int rutaId = _rutas.first.id;
    DateTime fecha = DateTime.now();
    TimeOfDay hora = TimeOfDay.now();
    final busCtrl = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear viaje'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: rutaId,
                  decoration: const InputDecoration(labelText: 'Ruta'),
                  items: _rutas
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text('${r.origen} ➔ ${r.destino}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => rutaId = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text('Fecha: ${fecha.toIso8601String().split('T').first}'),
                  onTap: () async {
                    final seleccion = await showDatePicker(
                      context: dialogContext,
                      initialDate: fecha,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (seleccion != null) {
                      setDialogState(() => fecha = seleccion);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text('Hora: ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final seleccion = await showTimePicker(
                      context: dialogContext,
                      initialTime: hora,
                    );
                    if (seleccion != null) {
                      setDialogState(() => hora = seleccion);
                    }
                  },
                ),
                TextField(
                  controller: busCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID de bus',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final busId = int.tryParse(busCtrl.text.trim());
                if (busId == null || busId <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa un ID de bus válido.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final fechaStr = fecha.toIso8601String().split('T').first;
                final horaStr = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';

                Navigator.pop(dialogContext);

                setState(() => _cargando = true);
                try {
                  await _viajeController.crearViaje(
                    idRuta: rutaId,
                    idAdmin: _usuarioId!,
                    idBus: busId,
                    fechaSalida: fechaStr,
                    horaSalida: horaStr,
                  );

                  await _cargarDatos();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Viaje creado correctamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                    setState(() => _cargando = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF638541),
                foregroundColor: Colors.white,
              ),
              child: const Text('CREAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        title: const Text('Viajes', style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF638541)))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'VIAJES ACTIVOS (PROGRAMADOS Y EN MARCHA)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildListaViajes(
                      _viajesHoy,
                      emptyText: 'No hay viajes programados para partir.',
                    ),
                    if (widget.esAdmin) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'HISTORIAL DE VIAJES ANTERIORES',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _buildListaViajes(
                        _historial,
                        emptyText: 'No hay viajes anteriores en el historial.',
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearViaje,
              backgroundColor: const Color(0xFF638541),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo viaje'),
            )
          : null,
    );
  }
}
