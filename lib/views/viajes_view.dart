import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/ruta_controller.dart';
import '../controllers/viaje_controller.dart';
import '../models/ruta_model.dart';
import '../models/viaje_model.dart';
import '../services/session_service.dart';
import 'viaje_detalle_view.dart';

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
  List<ViajeModel> _historialHoy = [];
  List<ViajeModel> _historialAyer = [];
  List<ViajeModel> _historialFiltrado = [];
  List<RutaModel> _rutas = [];
  bool _cargando = true;
  int? _usuarioId;
  DateTime? _fechaFiltroHistorial;

  Future<int?> _resolverAdminIdActual() async {
    final sesion = await _sessionService.leerSesion();
    if (sesion?.usuarioId != null) {
      return sesion!.usuarioId;
    }

    final contacto = sesion?.contactoUsuario.trim();
    if (contacto == null || contacto.isEmpty) return null;

    try {
      final data = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .eq('email', contacto)
          .maybeSingle();

      if (data == null) return null;
      final id = data['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return int.tryParse(id?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  String _fechaYMD(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _recalcularListasHistorial() {
    final hoy = DateTime.now();
    final hoyYMD = _fechaYMD(hoy);
    final ayerYMD = _fechaYMD(hoy.subtract(const Duration(days: 1)));

    _historialHoy = _historial.where((v) => v.fechaSalida == hoyYMD).toList();
    _historialAyer = _historial.where((v) => v.fechaSalida == ayerYMD).toList();
  }

  void _mostrarMensaje(String titulo, String mensaje, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: TextStyle(color: color)),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) => _mostrarMensaje('Error', mensaje, Colors.red);
  void _mostrarExito(String mensaje) => _mostrarMensaje('Exitoso', mensaje, Colors.green);
  void _mostrarAdvertencia(String mensaje) => _mostrarMensaje('Advertencia', mensaje, Colors.orange);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final adminId = await _resolverAdminIdActual();
      final resultados = await Future.wait([
        _viajeController.obtenerViajesActivos(),
        widget.esAdmin
            ? _rutaController.obtenerRutas()
            : Future.value(<RutaModel>[]),
        widget.esAdmin
            ? _viajeController.obtenerHistorialViajes()
            : Future.value(<ViajeModel>[]),
      ]);

      final viajesActivos = resultados[0] as List<ViajeModel>;
      final rutas = resultados[1] as List<RutaModel>;
      final historial = resultados[2] as List<ViajeModel>;

      final hoyYMD = _fechaYMD(DateTime.now());
      final viajesHoy = viajesActivos.where((v) => v.fechaSalida == hoyYMD).toList();

      if (!mounted) return;
      setState(() {
        _usuarioId = adminId;
        _viajesHoy = viajesHoy;
        _rutas = rutas;
        _historial = historial;
        _fechaFiltroHistorial = null;
        _historialFiltrado = [];
        _recalcularListasHistorial();
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString());
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
        _mostrarExito('Estado actualizado a "$nuevoEstado"');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar: $e');
        setState(() => _cargando = false);
      }
    }
  }

  Widget _buildListaViajes(List<ViajeModel> viajes, {required String emptyText, bool esHistorial = false}) {
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

        if (widget.esAdmin && !esHistorial) {
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
            onTap: esHistorial ? () => _abrirDetalleViaje(viaje) : null,
            title: Text(
              '${viaje.origenRuta ?? 'Ruta ${viaje.fkRuta}'} ➔ ${viaje.destinoRuta ?? ''}'.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Fecha: ${viaje.fechaSalida}  Hora: ${_formatearHora(viaje.horaSalida)}\nBus: ${viaje.fkBus ?? '-'}',
            ),
            trailing: widgetEstado,
          ),
        );
      }).toList(),
    );
  }

  void _abrirDetalleViaje(ViajeModel viaje) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViajeDetalleView(viaje: viaje),
      ),
    );
  }

  Future<void> _filtrarHistorialPorFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaFiltroHistorial ?? DateTime.now().subtract(const Duration(days: 2)),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
    );

    if (seleccion == null) return;

    setState(() => _cargando = true);
    try {
      final fechaStr = _fechaYMD(seleccion);
      final filtrados = await _viajeController.obtenerHistorialViajesPorFecha(fechaStr);
      if (!mounted) return;

      setState(() {
        _fechaFiltroHistorial = seleccion;
        _historialFiltrado = filtrados;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _limpiarFiltroHistorial() {
    setState(() {
      _fechaFiltroHistorial = null;
      _historialFiltrado = [];
    });
  }

  Future<void> _mostrarDialogoCrearViaje() async {
    final adminId = _usuarioId ?? await _resolverAdminIdActual();
    if (!mounted) return;

    if (adminId == null) {
      _mostrarError('No se pudo verificar quién es el admin actual. Cierra sesión e inicia de nuevo.');
      return;
    }

    if (_usuarioId != adminId && mounted) {
      setState(() => _usuarioId = adminId);
    }

    if (_rutas.isEmpty) {
      _mostrarError('No hay rutas disponibles para crear viajes.');
      return;
    }

    int rutaId = _rutas.first.id;
    DateTime fecha = DateTime.now();
    TimeOfDay hora = TimeOfDay.now();

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
                  initialValue: rutaId,
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
                      firstDate: DateTime.now(),
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
                const busId = 1;

                // Validar que la fecha y hora no sean pasadas
                final ahora = DateTime.now();
                final fechaHoy = DateTime(ahora.year, ahora.month, ahora.day);
                final fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);

                if (fechaSeleccionada.isBefore(fechaHoy)) {
                  _mostrarError('No puedes crear viajes con fechas anteriores.');
                  return;
                }

                // Si es hoy, validar que la hora no sea pasada
                if (fechaSeleccionada.isAtSameMomentAs(fechaHoy)) {
                  final horaActual = TimeOfDay.fromDateTime(ahora);
                  if (hora.hour < horaActual.hour ||
                      (hora.hour == horaActual.hour &&
                          hora.minute < horaActual.minute)) {
                    _mostrarError('La hora del viaje no puede ser pasada.');
                    return;
                  }
                }

                final fechaStr = fecha.toIso8601String().split('T').first;
                final horaStr = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';

                Navigator.pop(dialogContext);

                setState(() => _cargando = true);
                try {
                  await _viajeController.crearViaje(
                    idRuta: rutaId,
                    idAdmin: adminId,
                    idBus: busId,
                    fechaSalida: fechaStr,
                    horaSalida: horaStr,
                  );

                  await _cargarDatos();
                  if (mounted) {
                    _mostrarExito('Viaje creado correctamente.');
                  }
                } catch (e) {
                  if (mounted) {
                    _mostrarError(e.toString());
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'HISTORIAL (HOY Y AYER)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _filtrarHistorialPorFecha,
                            icon: const Icon(Icons.filter_alt_outlined, size: 18),
                            label: const Text('Filtrar fecha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_fechaFiltroHistorial != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Filtro aplicado: ${_fechaYMD(_fechaFiltroHistorial!)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: _limpiarFiltroHistorial,
                                child: const Text('Quitar filtro'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildListaViajes(
                          _historialFiltrado,
                          emptyText: 'No hay viajes en la fecha seleccionada.',
                          esHistorial: true,
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'Hoy',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _buildListaViajes(
                        _historialHoy,
                        emptyText: 'No hay viajes finalizados hoy.',
                        esHistorial: true,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ayer',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _buildListaViajes(
                        _historialAyer,
                        emptyText: 'No hay viajes finalizados ayer.',
                        esHistorial: true,
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
