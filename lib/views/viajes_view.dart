import 'dart:async';

import 'package:app_bus/controllers/alquiler_controller.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/ruta_controller.dart';
import '../controllers/viaje_controller.dart';
import '../models/ruta_model.dart';
import '../models/viaje_model.dart';
import '../services/session_service.dart';
import 'viaje_detalle_view.dart';
import '../models/alquiler_model.dart';

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
  final AlquilerController _alquilerController = AlquilerController();

  List<ViajeModel> _viajesHoy = [];
  List<ViajeModel> _historial = [];
  List<ViajeModel> _historialFiltrado = [];
  List<RutaModel> _rutas = [];
  List<AlquilerModel> _alquileresActivos = [];
  List<AlquilerModel> _historialAlquileres = [];
  List<AlquilerModel> _historialAlquileresFiltrado = [];
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
      final viajesHoy = viajesActivos;
      final alquileres = await _alquilerController.obtenerAlquileresActivos();
      final historialAlquileres = await _alquilerController.obtenerHistorialAlquileres();

      if (!mounted) return;
      setState(() {
        _usuarioId = adminId;
        _viajesHoy = viajesHoy;
        _rutas = rutas;
        _historial = historial;
        _alquileresActivos = alquileres;
        _historialFiltrado = [];
        _historialAlquileres = historialAlquileres;
        _historialAlquileresFiltrado = [];
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

  Future<void> _cambiarEstadoAlquiler(int idAlquiler, String nuevoEstado) async {
    setState(() => _cargando = true);
    try {
      await _conTimeout(
        _alquilerController.actualizarEstadoAlquiler(idAlquiler, nuevoEstado),
        'actualizar estado del alquiler',
      );
      await _cargarDatos(); 
      
      if (mounted) {
        _mostrarExito('Alquiler actualizado a "$nuevoEstado"');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar alquiler: $e');
        setState(() => _cargando = false);
      }
    }
  }

  // Nueva función que dibuja un SOLO viaje (extraída de tu código original)
  Widget _buildItemViaje(ViajeModel viaje, {bool esHistorial = false}) {
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      // --- AQUÍ AÑADIMOS EL BORDE ---
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: const Color.fromARGB(255, 4, 255, 0), // Color del borde (puedes usar tu verde theme si prefieres)
          width: 1.0, // Grosor del borde
        ),
        borderRadius: BorderRadius.circular(12), // Redondeamos las esquinas para que coincida con tu diseño
      ),
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
  }

  Widget _buildListaMixta(
    List<ViajeModel> viajes, 
    List<AlquilerModel> alquileres, {
    required String emptyText, 
    bool esHistorial = false,
  }) {
    // 1. Unimos todo en una sola lista dinámica
    List<dynamic> mezclados = [...viajes, ...alquileres];

    if (mezclados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(emptyText, style: TextStyle(color: Colors.grey[600])),
      );
    }

    // 2. Ordenamos por fecha y hora exactas
    mezclados.sort((a, b) {
      DateTime fechaA = DateTime.tryParse('${a.fechaSalida} ${a.horaSalida}') ?? DateTime.now();
      DateTime fechaB = DateTime.tryParse('${b.fechaSalida} ${b.horaSalida}') ?? DateTime.now();
      
      // Si es historial, los más recientes van arriba. Si son activos, los más próximos van arriba.
      return esHistorial ? fechaB.compareTo(fechaA) : fechaA.compareTo(fechaB);
    });

    // 3. Dibujamos la columna intercalada
    return Column(
      children: mezclados.map((item) {
        if (item is AlquilerModel) {
          return _buildItemAlquiler(item); // Dibuja la tarjeta naranja
        } else if (item is ViajeModel) {
          return _buildItemViaje(item, esHistorial: esHistorial); // Dibuja la tarjeta blanca
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
  Widget _buildItemAlquiler(AlquilerModel alquiler) {
    Widget widgetEstado = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _colorEstado(alquiler.estado).withAlpha(35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        alquiler.estado,
        style: TextStyle(
          color: _colorEstado(alquiler.estado), 
          fontSize: 12, 
          fontWeight: FontWeight.bold
        ),
      ),
    );

    // 2. Si es Admin, envolvemos la pastilla en el menú clickeable
    if (widget.esAdmin) {
      widgetEstado = PopupMenuButton<String>(
        initialValue: alquiler.estado,
        tooltip: 'Cambiar estado del alquiler',
        onSelected: (nuevoEstado) {
          if (nuevoEstado != alquiler.estado) {
            _cambiarEstadoAlquiler(alquiler.id, nuevoEstado);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 255, 243, 197),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 249, 165, 38)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${alquiler.origen} ➔ ${alquiler.destino}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                widgetEstado,
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Cliente: ${alquiler.nombreCliente}', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${alquiler.fechaSalida}   Hora: ${alquiler.horaSalida.substring(0, 5)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Precio Acordado: Bs. ${alquiler.precioTotal}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
      ),
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
      DateTime? fechaFin = ahora;

      switch (filtro) {
        case 'Esta semana':
          fechaInicio = ahora.subtract(Duration(days: ahora.weekday - 1));
          break;
        case 'Este mes':
          fechaInicio = DateTime(ahora.year, ahora.month, 1);
          break;
        case 'Mes anterior':
          fechaInicio = DateTime(ahora.year, ahora.month - 1, 1);
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

      List<ViajeModel> viajesFiltrados = [];
      List<AlquilerModel> alquileresFiltrados = [];
      
      if (fechaInicio == null || fechaFin == null) {
        // Aprovechamos para traer todo si eligio todos
        viajesFiltrados = await _viajeController.obtenerHistorialViajes(); 
        alquileresFiltrados = await _alquilerController.obtenerHistorialAlquileres();
      } else {
        // Formateamos las fechas (YYYY-MM-DD)
        final inicioStr = fechaInicio.toIso8601String().split('T').first;
        final finStr = fechaFin.toIso8601String().split('T').first;
        
        // ¡Magia! Traemos ambos filtrados
        viajesFiltrados = await _viajeController.obtenerHistorialPorRango(inicioStr, finStr);
        alquileresFiltrados = await _alquilerController.obtenerHistorialAlquileresPorRango(inicioStr, finStr);
      }

      if (!mounted) return;
      setState(() {
        _historialFiltrado = viajesFiltrados;
        _historialAlquileresFiltrado = alquileresFiltrados; // Guardamos el nuevo filtro
      });
      
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
  //alquiler del Bus
  Future<void> _mostrarDialogoCrearAlquiler() async {
    DateTime fecha = DateTime.now();
    TimeOfDay hora = TimeOfDay.now();
    
    // Controladores
    final clienteCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final origenCtrl = TextEditingController();
    final destinoCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final busCtrl = TextEditingController(text: '1'); 

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Alquiler Privado', style: TextStyle(color: Colors.orange)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clienteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Cliente / Institución',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: origenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Origen exacto', 
                    prefixIcon: Icon(Icons.location_on_outlined, color: Colors.green),
                  ),
                ),
                TextField(
                  controller: destinoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Destino exacto', 
                    prefixIcon: Icon(Icons.flag_outlined, color: Colors.red),
                  ),
                ),
                TextField(
                  controller: precioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio Total Acordado', 
                    prefixText: 'Bs ',
                    prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.orange),
                  ),
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
                    if (seleccion != null) setDialogState(() => fecha = seleccion);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text('Hora: ${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final seleccion = await showTimePicker(context: dialogContext, initialTime: hora);
                    if (seleccion != null) setDialogState(() => hora = seleccion);
                  },
                ),
                // --- CAMPO DEL BUS VISIBLE PERO BLOQUEADO ---
                const SizedBox(height: 8),
                TextField(
                  controller: busCtrl,
                  readOnly: true, // <-- ESTO EVITA QUE EL TECLADO APAREZCA
                  decoration: InputDecoration(
                    labelText: 'ID Bus',
                    prefixIcon: const Icon(Icons.directions_bus_outlined),
                    filled: true,
                    fillColor: Colors.grey[200], // Fondo gris claro
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
  onPressed: () async {
    final cliente = clienteCtrl.text.trim();
    final origen = origenCtrl.text.trim();
    final destino = destinoCtrl.text.trim();
    final precio = double.tryParse(precioCtrl.text) ?? 0.0;
    
    // Validaciones básicas
    if (cliente.isEmpty || origen.isEmpty || destino.isEmpty || precio <= 0) {
      _mostrarError('Por favor completa todos los campos.');
      return;
    }

    final adminId = _usuarioId ?? await _resolverAdminIdActual();
    if (!context.mounted) return;
    if (adminId == null) return;

    Navigator.pop(dialogContext); // Cerramos el modal
    setState(() => _cargando = true);

    try {
      await _alquilerController.crearAlquiler(
        idAdmin: adminId,
        cliente: cliente,
        telefono: telefonoCtrl.text.trim(),
        origen: origen,
        destino: destino,
        fecha: fecha.toIso8601String().split('T').first,
        hora: '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00',
        precio: precio,
      );
      
      await _cargarDatos(); // Refrescamos la lista
      _mostrarExito('Alquiler registrado con éxito.');
    } catch (e) {
      _mostrarError(e.toString());
      setState(() => _cargando = false);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange[600],
    foregroundColor: Colors.white,
  ),
  child: const Text('REGISTRAR ALQUILER'),
),
          ],
        ),
      ),
    );
  }
  
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
                      'VIAJES y ALQUILERES DEL BUS ACTIVOS (PROGRAMADOS Y EN MARCHA)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildListaMixta(
                      _viajesHoy,
                      _alquileresActivos,
                      emptyText: 'No hay viajes ni alquileres programados para partir.',
                      esHistorial: false,
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
                        
                        // 1. Mostramos los ALQUILERES filtrados primero
                        _buildListaMixta(
                          _historialFiltrado,
                          _historialAlquileresFiltrado,
                          emptyText: 'No hay viajes en $_filtroActivo.',
                          esHistorial: true,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // --- SI EL FILTRO ES "TODOS", MOSTRAMOS LA LISTA COMPLETA ---
                        const SizedBox(height: 8),
                        
                        // 1. Historial completo de ALQUILERES
                        _buildListaMixta(
                          _historial,
                          _historialAlquileres,
                          emptyText: 'No hay viajes finalizados en el historial.',
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
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // BOTON DE NUEVO ALQUILER (Arriba)
                FloatingActionButton.extended(
                  heroTag: 'btn_nuevo_alquiler', 
                  onPressed: _mostrarDialogoCrearAlquiler, 
                  backgroundColor: Colors.orange[600], 
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.directions_bus_filled),
                  label: const Text('Nuevo alquiler'),
                ),
                
                const SizedBox(height: 16),
                
                //BOTON DE NUEVO VIAJE (Abajo)
                FloatingActionButton.extended(
                  heroTag: 'btn_nuevo_viaje',
                  onPressed: _mostrarDialogoCrearViaje,
                  backgroundColor: const Color(0xFF638541),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo viaje'),
                ),
              ],
            )
          : null,
    );
  }
}
