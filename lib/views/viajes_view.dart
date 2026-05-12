import 'dart:async';

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
  List<ViajeModel> _historialFiltrado = [];
  List<RutaModel> _rutas = [];
  bool _cargando = true;
  String _filtroActivo = 'Todos';
  int? _usuarioId;

  Future<T> _conTimeout<T>(Future<T> future, String accion) {
    return future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Tiempo de espera agotado al $accion. Revisa tu conexion e intenta de nuevo.',
      ),
    );
  }

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
    _historialHoy = _historial.where((v) => v.fechaSalida == hoyYMD).toList();
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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final adminId = await _conTimeout(
        _resolverAdminIdActual(),
        'verificar el admin actual',
      );
      final resultados = await _conTimeout(Future.wait([
        _viajeController.obtenerViajesActivos(),
        widget.esAdmin
            ? _rutaController.obtenerRutas()
            : Future.value(<RutaModel>[]),
        widget.esAdmin
            ? _viajeController.obtenerHistorialViajes()
            : Future.value(<ViajeModel>[]),
      ]), 'cargar datos de viajes');

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
      await _conTimeout(
        _viajeController.actualizarEstadoViaje(idViaje, nuevoEstado),
        'actualizar estado del viaje',
      );
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

  Future<void> _mostrarOpcionesFiltro() async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Filtrar historial'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Esta semana'),
              child: const Padding(padding: EdgeInsets.all(8.0), child: Text('Esta semana')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Este mes'),
              child: const Padding(padding: EdgeInsets.all(8.0), child: Text('Este mes')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Mes anterior'),
              child: const Padding(padding: EdgeInsets.all(8.0), child: Text('Mes anterior')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Últimos 6 meses'),
              child: const Padding(padding: EdgeInsets.all(8.0), child: Text('Últimos 6 meses')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Todos'),
              child: const Padding(padding: EdgeInsets.all(8.0), child: Text('Todos', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ],
        );
      }
    );

    if (opcion != null && opcion != _filtroActivo) {
      _aplicarFiltro(opcion);
    }
  }

  Future<void> _aplicarFiltro(String filtro) async {
    setState(() {
      _filtroActivo = filtro;
      _cargando = true;
    });

    try {
      DateTime ahora = DateTime.now();
      DateTime? fechaInicio;
      DateTime? fechaFin = ahora; // Casi todos los filtros terminan hoy

      switch (filtro) {
        case 'Esta semana':
          fechaInicio = ahora.subtract(Duration(days: ahora.weekday - 1));
          break;
        case 'Este mes':
          fechaInicio = DateTime(ahora.year, ahora.month, 1);
          break;
        case 'Mes anterior':
          fechaInicio = DateTime(ahora.year, ahora.month - 1, 1);
          // El día 0 del mes actual equivale al último día del mes anterior
          fechaFin = DateTime(ahora.year, ahora.month, 0); 
          break;
        case 'Últimos 6 meses':
          fechaInicio = DateTime(ahora.year, ahora.month - 6, 1);
          break;
        case 'Todos':
        default:
          fechaInicio = null;
          fechaFin = null;
          break;
      }

      List<ViajeModel> filtrados = [];
      
      if (fechaInicio == null || fechaFin == null) {
        // Aprovechamos la función normal si eligió "Todos"
        filtrados = await _viajeController.obtenerHistorialViajes(); 
      } else {
        // Formateamos las fechas (YYYY-MM-DD) para Postgres
        final inicioStr = fechaInicio.toIso8601String().split('T').first;
        final finStr = fechaFin.toIso8601String().split('T').first;
        
        filtrados = await _viajeController.obtenerHistorialPorRango(inicioStr, finStr);
      }

      if (!mounted) return;
      setState(() => _historialFiltrado = filtrados);
      
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
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
                  await _conTimeout(
                    _viajeController.crearViaje(
                    idRuta: rutaId,
                    idAdmin: adminId,
                    idBus: busId,
                    fechaSalida: fechaStr,
                    horaSalida: horaStr,
                    ),
                    'crear viaje',
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
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
                              'HISTORIAL',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          // --- AQUÍ LLAMAMOS AL NUEVO MENÚ DE FILTROS ---
                          TextButton.icon(
                            onPressed: _mostrarOpcionesFiltro,
                            icon: const Icon(Icons.filter_list, size: 18),
                            label: const Text('Filtrar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // --- AQUÍ EVALUAMOS QUÉ FILTRO ESTÁ ACTIVO ---
                      if (_filtroActivo != 'Todos') ...[
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
                                  'Filtro: $_filtroActivo',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _aplicarFiltro('Todos'),
                                child: const Text('Quitar filtro'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildListaViajes(
                          _historialFiltrado,
                          emptyText: 'No hay viajes en $_filtroActivo.',
                          esHistorial: true,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // --- SI EL FILTRO ES "TODOS", MOSTRAMOS HOY Y AYER ---
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
                        
                        
                      ],
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
