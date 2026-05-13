import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/asiento_controller.dart';
import '../controllers/boleto_controller.dart';
import '../controllers/ruta_controller.dart';
import '../controllers/viaje_controller.dart';
import '../models/asiento_model.dart';
import '../models/ruta_model.dart';
import '../models/viaje_model.dart';
import '../services/session_service.dart';

class VentaView extends StatefulWidget {
  const VentaView({super.key});

  @override
  State<VentaView> createState() => _VentaViewState();
}

class _VentaViewState extends State<VentaView> {
  final ViajeController _viajeController = ViajeController();
  final AsientoController _asientoController = AsientoController();
  final RutaController _rutaController = RutaController();
  final BoletoController _boletoController = BoletoController();
  final SessionService _sessionService = SessionService();

  bool _cargandoViajes = true;
  bool _cargandoAsientos = false;
  List<ViajeModel> _viajesHoy = [];
  Map<String, List<ViajeModel>> _viajesPorFecha = {};
  List<RutaModel> _rutas = [];
  List<AsientoModel> _asientos = [];
  Map<int, Map<String, dynamic>> _detalleBoletoPorAsiento = {};
  final Set<int> _asientosSeleccionadosIds = <int>{};
  ViajeModel? _viajeSeleccionado;
  RealtimeChannel? _suscripcionBoletosEnTiempoReal;
  RealtimeChannel? _suscripcionAsientosBloqueados;
  Timer? _timerSincronizacion;
  List<int> _asientosBloqueados = [];
  int? _usuarioActualId;
  bool _sincronizandoBoletos = false;
  bool _sincronizandoBloqueos = false;
  DateTime? _ultimoAvisoAsientoBloqueado;

  Future<T> _conTimeout<T>(Future<T> future, String accion) {
    return future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Tiempo de espera agotado al $accion. Revisa tu conexion e intenta de nuevo.',
      ),
    );
  }

  Widget _buildCampoDetalle({
    required IconData icon,
    required String etiqueta,
    required String valor,
    Color? valorColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF638541)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF2F3A2A), fontSize: 14),
                children: [
                  TextSpan(
                    text: '$etiqueta: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: valor,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: valorColor ?? const Color(0xFF2F3A2A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
    _cargarViajesHoy();
  }

  Future<void> _cargarUsuarioActual() async {
    final sesion = await _sessionService.leerSesion();
    if (!mounted) return;
    setState(() => _usuarioActualId = sesion?.usuarioId);
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
  void dispose() {
    // Desbloquear todos los asientos que estaban seleccionados
    if (_viajeSeleccionado != null) {
      final sesion = _sessionService.leerSesion();
      sesion.then((s) {
        if (s != null) {
          _asientoController.desbloquearTodosEnViaje(
            viajeId: _viajeSeleccionado!.id,
            vendedorId: s.usuarioId,
          );
        }
      });
    }

    // Limpiar suscripciones
    _timerSincronizacion?.cancel();
    _suscripcionBoletosEnTiempoReal?.unsubscribe();
    _suscripcionAsientosBloqueados?.unsubscribe();
    super.dispose();
  }

  Future<void> _cargarViajesHoy() async {
    setState(() => _cargandoViajes = true);
    try {
      final resultados = await Future.wait([
        _viajeController.obtenerViajesActivos(),
        _rutaController.obtenerRutas(),
      ]);
      final viajes = resultados[0] as List<ViajeModel>;
      final rutas = resultados[1] as List<RutaModel>;
      if (!mounted) return;

      final hoy = _obtenerFechaHoy();
      
      // Mantenemos el nombre de tus variables para no romper la interfaz visual
      final viajesHoy = <ViajeModel>[]; 
      final viajesPorFecha = <String, List<ViajeModel>>{};

      for (final viaje in viajes) {
        // CORRECCIÓN: Si el viaje es de hoy O de una fecha anterior (<= 0), va a la lista principal
        if (viaje.fechaSalida.compareTo(hoy) <= 0) {
          viajesHoy.add(viaje);
        } 
        // Si el viaje es estrictamente del futuro (mañana en adelante), se agrupa
        else {
          viajesPorFecha.putIfAbsent(viaje.fechaSalida, () => []).add(viaje);
        }
      }

      // Ordenar viajes dentro de cada fecha
      for (final lista in viajesPorFecha.values) {
        lista.sort((a, b) => a.horaSalida.compareTo(b.horaSalida));
      }

      setState(() {
        _viajesHoy = viajesHoy;
        _viajesPorFecha = viajesPorFecha;
        _rutas = rutas;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _cargandoViajes = false);
    }
  }

  Future<void> _seleccionarViaje(ViajeModel viaje) async {
    if (viaje.fkBus == null) {
      _mostrarError('Este viaje no tiene bus asignado.');
      return;
    }

    // Limpiar suscripciones anteriores
    _timerSincronizacion?.cancel();
    await _suscripcionBoletosEnTiempoReal?.unsubscribe();
    await _suscripcionAsientosBloqueados?.unsubscribe();

    setState(() {
      _viajeSeleccionado = viaje;
      _cargandoAsientos = true;
      _asientos = [];
      _detalleBoletoPorAsiento = {};
      _asientosSeleccionadosIds.clear();
      _asientosBloqueados = [];
    });

    try {
      final resultados = await Future.wait([
        _asientoController.obtenerAsientosPorBus(viaje.fkBus!),
        _boletoController.obtenerDetalleBoletosPorViaje(viaje.id),
        _asientoController.obtenerAsientosBloqueados(
          viaje.id,
          excluirVendedorId: _usuarioActualId,
        ),
      ]);
      final asientos = resultados[0] as List<AsientoModel>;
      final detalleBoletos = resultados[1] as Map<int, Map<String, dynamic>>;
      final bloqueados = resultados[2] as List<int>;
      if (!mounted) return;
      setState(() {
        _asientos = asientos;
        _detalleBoletoPorAsiento = detalleBoletos;
        _asientosBloqueados = bloqueados;
      });

      // Escuchar cambios en tiempo real
      _escucharCambiosEnBoletos(viaje.id);
      _escucharCambiosEnAsientosBloqueados(viaje.id);
      _iniciarSincronizacionPeriodica();
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _cargandoAsientos = false);
    }
  }

  void _escucharCambiosEnBoletos(int viajeId) {
    _suscripcionBoletosEnTiempoReal = Supabase.instance.client
        .channel('boletos_viaje_$viajeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'boletos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'fk_viaje',
            value: viajeId.toString(),
          ),
          callback: (payload) {
            // Nuevo boleto insertado, actualizar detalles
            _actualizarAsientosDisponibes();
          },
        )
        .subscribe();
  }

  void _escucharCambiosEnAsientosBloqueados(int viajeId) {
    _suscripcionAsientosBloqueados = Supabase.instance.client
        .channel('asientos_bloqueados_viaje_$viajeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'asientos_bloqueados',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'fk_viaje',
            value: viajeId.toString(),
          ),
          callback: (payload) {
            // Se bloqueó/desbloqueó un asiento, actualizar lista
            _actualizarAsientosBloqueados();
          },
        )
        .subscribe();
  }

  Future<void> _actualizarAsientosBloqueados() async {
    if (_viajeSeleccionado == null || _sincronizandoBloqueos) return;
    _sincronizandoBloqueos = true;
    try {
      final bloqueados = await _asientoController
          .obtenerAsientosBloqueados(
            _viajeSeleccionado!.id,
            excluirVendedorId: _usuarioActualId,
          );
      if (!mounted) return;

      if (!_mismaListaDeAsientos(_asientosBloqueados, bloqueados)) {
        setState(() {
          _asientosBloqueados = bloqueados;
        });
      }
    } catch (e) {
      debugPrint('Error actualizando asientos bloqueados: $e');
    } finally {
      _sincronizandoBloqueos = false;
    }
  }

  void _iniciarSincronizacionPeriodica() {
    _timerSincronizacion?.cancel();
    _timerSincronizacion = Timer.periodic(const Duration(seconds: 3), (_) {
      _actualizarAsientosDisponibes();
      _actualizarAsientosBloqueados();
    });
  }

  bool _mismaListaDeAsientos(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  Future<void> _actualizarAsientosDisponibes() async {
    if (_viajeSeleccionado == null || _sincronizandoBoletos) return;
    _sincronizandoBoletos = true;
    try {
      final detalleBoletos = await _boletoController
          .obtenerDetalleBoletosPorViaje(_viajeSeleccionado!.id);
      if (!mounted) return;

      // Verificar si algún asiento seleccionado fue vendido
      final asientosAhoraVendidos = <int>[];
      for (final asientoId in _asientosSeleccionadosIds) {
        if (detalleBoletos.containsKey(asientoId)) {
          asientosAhoraVendidos.add(asientoId);
        }
      }

      if (_detalleBoletoPorAsiento.length != detalleBoletos.length) {
        setState(() {
          _detalleBoletoPorAsiento = detalleBoletos;
        });
      }

      // Si algún asiento fue vendido, mostrar advertencia
      if (asientosAhoraVendidos.isNotEmpty) {
        final asientosText = asientosAhoraVendidos.join(', ');
        _mostrarAdvertencia('Asiento(s) $asientosText fue(ron) vendido(s) por otro vendedor');
        // Deseleccionar los asientos vendidos
        setState(() {
          for (final asientoId in asientosAhoraVendidos) {
            _asientosSeleccionadosIds.remove(asientoId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error actualizando asientos: $e');
    } finally {
      _sincronizandoBoletos = false;
    }
  }

  String _formatearHora(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    return '${partes[0]}:${partes[1]}';
  }

  String _obtenerFechaHoy() {
    final hoy = DateTime.now();
    return '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  String _formatearFechaDisplay(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      final hoy = DateTime.now();
      final manana = hoy.add(const Duration(days: 1));

      final hoyISO = '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final mananaISO = '${manana.year.toString().padLeft(4, '0')}-${manana.month.toString().padLeft(2, '0')}-${manana.day.toString().padLeft(2, '0')}';

      if (fechaISO == hoyISO) return 'HOY';
      if (fechaISO == mananaISO) return 'MANANA';

      final meses = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      final dias = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];

      return '${dias[fecha.weekday % 7]} ${fecha.day} de ${meses[fecha.month]}';
    } catch (e) {
      return fechaISO;
    }
  }

  Color _colorAsiento(AsientoModel asiento) {
    // Primero verificar si está vendido (rojo)
    final tieneBoletoEnViaje = _detalleBoletoPorAsiento.containsKey(asiento.id);
    if (tieneBoletoEnViaje) return Colors.red;

    // Luego verificar si está bloqueado por otro vendedor (amarillo/naranja)
    final estaBloqueado = _asientosBloqueados.contains(asiento.id);
    if (estaBloqueado) return Colors.amber;

    // Luego verificar estado (gris si inactivo/mantenimiento)
    final estado = asiento.estado.toLowerCase();
    if (estado == 'mantenimiento' || estado == 'inactivo') return Colors.grey;

    // Si está seleccionado por este usuario (verde claro)
    if (_asientosSeleccionadosIds.contains(asiento.id)) {
      return const Color(0xFF638541);
    }

    // Disponible (verde)
    return const Color(0xFF638541);
  }

  bool _asientoBloqueadoPorEstado(AsientoModel asiento) {
    final estado = asiento.estado.toLowerCase();
    return estado == 'mantenimiento' || estado == 'inactivo';
  }

  bool _asientoBloqueadoPorOtroUsuario(AsientoModel asiento) {
    return _asientosBloqueados.contains(asiento.id);
  }

  double _precioUnitarioActual() {
    if (_viajeSeleccionado == null) return 0;
    final rutaId = _viajeSeleccionado!.fkRuta;
    for (final ruta in _rutas) {
      if (ruta.id == rutaId) {
        return ruta.precio;
      }
    }
    return 0;
  }

  int _cantidadVendidos() {
    return _detalleBoletoPorAsiento.length;
  }

  int _cantidadReservados() {
    return _asientosBloqueados.length;
  }

  int _cantidadInactivos() {
    return _asientos
        .where((a) => _asientoBloqueadoPorEstado(a))
        .length;
  }

  int _cantidadDisponibles() {
    final noDisponibles =
        _cantidadVendidos() + _cantidadReservados() + _cantidadInactivos();
    final disponibles = _asientos.length - noDisponibles;
    return disponibles < 0 ? 0 : disponibles;
  }

  List<AsientoModel> _asientosSeleccionados() {
    final seleccionados = _asientos
        .where((a) => _asientosSeleccionadosIds.contains(a.id))
        .toList();
    seleccionados.sort((a, b) => a.numero.compareTo(b.numero));
    return seleccionados;
  }

  void _toggleSeleccionAsiento(AsientoModel asiento) async {
    if (_detalleBoletoPorAsiento.containsKey(asiento.id)) return;
    if (_asientoBloqueadoPorEstado(asiento)) return;
    if (_asientoBloqueadoPorOtroUsuario(asiento)) {
      final ahora = DateTime.now();
      final puedeAvisar = _ultimoAvisoAsientoBloqueado == null ||
          ahora.difference(_ultimoAvisoAsientoBloqueado!).inMilliseconds > 1200;
      if (!puedeAvisar) return;
      _ultimoAvisoAsientoBloqueado = ahora;

      _mostrarAdvertencia(
        'Este asiento esta siendo seleccionado por otro vendedor.',
      );
      return;
    }

    if (_usuarioActualId == null) {
      await _cargarUsuarioActual();
      if (_usuarioActualId == null) return;
    }

    if (_asientosSeleccionadosIds.contains(asiento.id)) {
      // Deseleccionar y desbloquear
      setState(() {
        _asientosSeleccionadosIds.remove(asiento.id);
      });
      await _asientoController.desbloquearAsiento(
        asientoId: asiento.id,
        viajeId: _viajeSeleccionado!.id,
        vendedorId: _usuarioActualId,
      );
    } else {
      // Seleccionar y bloquear
      setState(() {
        _asientosSeleccionadosIds.add(asiento.id);
      });
      await _asientoController.bloquearAsiento(
        asientoId: asiento.id,
        viajeId: _viajeSeleccionado!.id,
        vendedorId: _usuarioActualId,
      );
    }
  }

  String _nombreVisibleComprador(AsientoModel asiento) {
    final detalle = _detalleBoletoPorAsiento[asiento.id];
    if (detalle == null) return '';
    final nombre = (detalle['nombre_pasajero'] ?? '').toString().trim();
    if (nombre.isEmpty) return '';
    final partes = nombre.split(RegExp(r'\s+'));
    return partes.first;
  }

  String _valorDetalle(Map<String, dynamic> detalle, String campo) {
    return (detalle[campo] ?? '').toString();
  }

  String _formatearFechaVenta(dynamic fechaRaw) {
    if (fechaRaw == null) return '-';
    final valor = fechaRaw.toString();
    final parsed = DateTime.tryParse(valor);
    if (parsed == null) return valor;
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Future<void> _mostrarDetalleBoleto(AsientoModel asiento) async {
    final detalle = _detalleBoletoPorAsiento[asiento.id];
    if (detalle == null) {
      return;
    }

    final nombre = _valorDetalle(detalle, 'nombre_pasajero');
    final ci = _valorDetalle(detalle, 'ci_pasajero');
    final estado = _valorDetalle(detalle, 'estado');
    final vendedorId = _valorDetalle(detalle, 'fk_usuario_vendedor');
    final precio = _valorDetalle(detalle, 'precio');
    final fecha = _formatearFechaVenta(detalle['fecha_venta']);
    final origen = _valorDetalle(detalle, 'origen');
    final destino = _valorDetalle(detalle, 'destino');
    String nombreVendedor = vendedorId; 
    
    if (vendedorId.isNotEmpty && vendedorId != '-') {
      try {
        final respuesta = await Supabase.instance.client
            .from('usuarios')
            .select('nombres, apellidos') 
            .eq('id', vendedorId)
            .maybeSingle();

        if (respuesta != null) {
          final nombresBD = respuesta['nombres'] ?? '';
          final apellidosBD = respuesta['apellidos'] ?? '';
          final nombreCompleto = '$nombresBD $apellidosBD'.trim();
          
          if (nombreCompleto.isNotEmpty) {
            nombreVendedor = nombreCompleto;
          }
        }
      } catch (e) {
        debugPrint('Error al cargar nombre del vendedor: $e');
      }
    }

    if (!mounted) return; 

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.airline_seat_recline_normal,
                color: Color(0xFF638541),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('Detalle del asiento ${asiento.numero}')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCampoDetalle(
                  icon: Icons.person_outline,
                  etiqueta: 'Comprador',
                  valor: nombre.isEmpty ? '-' : nombre,
                ),
                _buildCampoDetalle(
                  icon: Icons.badge_outlined,
                  etiqueta: 'CI',
                  valor: ci.isEmpty ? '-' : ci,
                ),
                _buildCampoDetalle(
                  icon: Icons.payments_outlined,
                  etiqueta: 'Precio',
                  valor: 'Bs ${precio.isEmpty ? '-' : precio}',
                  valorColor: const Color(0xFF638541),
                ),
                _buildCampoDetalle(
                  icon: Icons.calendar_month_outlined,
                  etiqueta: 'Fecha venta',
                  valor: fecha,
                ),
                _buildCampoDetalle(
                  icon: Icons.flag_outlined,
                  etiqueta: 'Estado',
                  valor: estado.isEmpty ? '-' : estado,
                ),
                _buildCampoDetalle(
                  icon: Icons.trip_origin,
                  etiqueta: 'Origen',
                  valor: origen.isEmpty ? '-' : origen,
                ),
                _buildCampoDetalle(
                  icon: Icons.place_outlined,
                  etiqueta: 'Destino',
                  valor: destino.isEmpty ? '-' : destino,
                ),
                _buildCampoDetalle(
                  icon: Icons.support_agent,
                  etiqueta: 'Vendedor',
                  valor: nombreVendedor.isEmpty ? '-' : nombreVendedor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registrarVenta({
    required String nombreComprador,
    required String ciComprador,
    required String origen,  
    required String destino,  
    required double precio,
  }) async {
    if (_viajeSeleccionado == null || _viajeSeleccionado!.fkBus == null) {
      throw 'Debes seleccionar un viaje válido.';
    }

    final seleccionados = _asientosSeleccionados();
    if (seleccionados.isEmpty) {
      throw 'Debes seleccionar al menos un asiento.';
    }

    final sesion = await _conTimeout(
      _sessionService.leerSesion(),
      'leer sesion de usuario',
    );

    await _conTimeout(
      _boletoController.registrarVenta(
      viajeId: _viajeSeleccionado!.id,
      asientos: seleccionados,
      nombrePasajero: nombreComprador,
      ciPasajero: ciComprador,
      precioUnitario: precio,
      vendedorId: sesion?.usuarioId,
      origen: origen,
      destino: destino,     
    ),
      'registrar venta',
    );

    final resultados = await _conTimeout(Future.wait([
      _asientoController.obtenerAsientosPorBus(_viajeSeleccionado!.fkBus!),
      _boletoController.obtenerDetalleBoletosPorViaje(_viajeSeleccionado!.id),
    ]), 'actualizar datos de asientos y boletos');
    final asientosActualizados = resultados[0] as List<AsientoModel>;
    final detalleBoletos = resultados[1] as Map<int, Map<String, dynamic>>;

    if (!mounted) return;
    setState(() {
      _asientos = asientosActualizados;
      _detalleBoletoPorAsiento = detalleBoletos;
      _asientosSeleccionadosIds.clear();
    });

    await _conTimeout(
      _asientoController.desbloquearAsientosVendidos(
        viajeId: _viajeSeleccionado!.id,
        asientosIds: seleccionados.map((a) => a.id).toList(),
      ),
      'liberar asientos vendidos',
    );
  }

  
  bool _esNombreValido(String nombre) {
    if (nombre.isEmpty) return false;
    // Solo letras y espacios
    return RegExp(r"^[a-záéíóúàèìòùäëïöüñ\s]+$", caseSensitive: false)
        .hasMatch(nombre);
  }

  bool _esCIValido(String ci) {
    if (ci.isEmpty) return false;
    // Solo números
    if (!RegExp(r"^\d+$").hasMatch(ci)) return false;
    // Entre 8 y 14 dígitos
    return ci.length >= 8 && ci.length <= 14;
  }

  bool _esPrecioValido(String precio) {
    if (precio.isEmpty) return false;
    final precioNum = double.tryParse(precio);
    return precioNum != null && precioNum > 0;
  }

  String _obtenerErrorNombre(String nombre) {
    if (nombre.isEmpty) return 'Ingresa el nombre del comprador';
    if (!_esNombreValido(nombre)) return 'Solo letras y espacios permitidos';
    return '';
  }

  String _obtenerErrorCI(String ci) {
    if (ci.isEmpty) return 'Ingresa el CI';
    if (!RegExp(r"^\d+$").hasMatch(ci)) return 'Solo números permitidos';
    if (ci.length < 8) return 'CI debe tener mínimo 8 dígitos';
    if (ci.length > 14) return 'CI debe tener máximo 14 dígitos';
    return '';
  }

  String _obtenerErrorPrecio(String precio) {
    if (precio.isEmpty) return 'Ingresa el precio';
    if (!RegExp(r"^\d+(\.\d{1,2})?$").hasMatch(precio)) {
      return 'Solo números y decimales permitidos';
    }
    final precioNum = double.tryParse(precio);
    if (precioNum == null || precioNum <= 0) return 'Precio debe ser mayor a 0';
    return '';
  }

  // registrar venta
  Future<void> _mostrarModalRegistrarVenta() async {
    final seleccionados = _asientosSeleccionados();
    if (seleccionados.isEmpty) return;

    final List<String> paradas = [
      'Quillacollo',
      'Peñas',
      'calientes',
      'Laca laca',
      'Choro',
      'Tetillas',
      'Jatum pampa',
      'falsuri',
      'San Cristóbal',
      'Quebrada',
      'Maravillas',
      'Justiciado',
      'Sequerrancho',
      'SantoDomingo',
    ];

    String origenSeleccionado = paradas.first;
    String destinoSeleccionado = paradas.last;

    final nombreCtrl = TextEditingController();
    final ciCtrl = TextEditingController();
  
    final precioBase = _precioUnitarioActual();
    final precioCtrl = TextEditingController(text: precioBase.toStringAsFixed(2));

    final asientosTexto = seleccionados.map((a) => a.numero.toString()).join(', ');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (contextoModal) {
        bool guardando = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            double precioEscrito = double.tryParse(precioCtrl.text) ?? 0.0;
            double total = precioEscrito * seleccionados.length;

            final nombreValido = _esNombreValido(nombreCtrl.text.trim());
            final ciValido = _esCIValido(ciCtrl.text.trim());
            final precioValido = _esPrecioValido(precioCtrl.text.trim());
            final todosValidos = nombreValido && ciValido && precioValido;

            return AlertDialog(
              title: const Text('Registrar venta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nombre del comprador',
                        errorText: nombreCtrl.text.isNotEmpty
                            ? _obtenerErrorNombre(nombreCtrl.text.trim())
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: nombreCtrl.text.isNotEmpty && !nombreValido
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ciCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CI del comprador (8-14 dígitos)',
                        errorText: ciCtrl.text.isNotEmpty
                            ? _obtenerErrorCI(ciCtrl.text.trim())
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ciCtrl.text.isNotEmpty && !ciValido
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Precio por asiento (Bs)',
                        prefixText: 'Bs ',
                        errorText: precioCtrl.text.isNotEmpty
                            ? _obtenerErrorPrecio(precioCtrl.text.trim())
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: precioCtrl.text.isNotEmpty && !precioValido
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      onChanged: (value) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: origenSeleccionado,
                      decoration: const InputDecoration(labelText: 'Sube en'),
                      items: paradas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setModalState(() => origenSeleccionado = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: destinoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Baja en'),
                      items: paradas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setModalState(() => destinoSeleccionado = v!),
                    ),
                    const SizedBox(height: 14),
                    Text('Asientos: $asientosTexto'),
                    Text(
                      'Total a pagar: Bs ${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.of(contextoModal).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: (guardando || !todosValidos) ? null : () async {
                    final navigator = Navigator.of(contextoModal);
                    final nombre = nombreCtrl.text.trim();
                    final ci = ciCtrl.text.trim();
                    final precioFinal = double.tryParse(precioCtrl.text) ?? 0.0;
                    var ventaExitosa = false;

                    setModalState(() => guardando = true);
                    try {
                      // Verificación final: asegurarse que los asientos siguen disponibles
                      final detalleBoletos = await _conTimeout(
                        _boletoController.obtenerDetalleBoletosPorViaje(_viajeSeleccionado!.id),
                        'verificar disponibilidad de asientos',
                      );
                      
                      // Verificar si algún asiento fue vendido
                      final asientosNoDisponibles = <int>[];
                      for (final asientoId in _asientosSeleccionadosIds) {
                        if (detalleBoletos.containsKey(asientoId)) {
                          asientosNoDisponibles.add(asientoId);
                        }
                      }

                      if (asientosNoDisponibles.isNotEmpty) {
                        setModalState(() => guardando = false);
                        final asientosText = asientosNoDisponibles.join(', ');
                        _mostrarAdvertencia(
                          'Asiento(s) $asientosText fue(ron) vendido(s) por otro vendedor. Por favor, selecciona otros asientos.',
                        );
                        return;
                      }

                      await _registrarVenta(
                        nombreComprador: nombre,
                        ciComprador: ci,
                        origen: origenSeleccionado,
                        destino: destinoSeleccionado,
                        precio: precioFinal,
                      );
                      if (!mounted) return;
                      ventaExitosa = true;
                      navigator.pop();
                      _mostrarExito('Venta registrada correctamente.');
                    } catch (e) {
                      if (contextoModal.mounted) {
                        setModalState(() => guardando = false);
                      }
                      _mostrarError('Error: ${e.toString()}');
                    } finally {
                      if (!ventaExitosa && contextoModal.mounted) {
                        setModalState(() => guardando = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: todosValidos
                        ? const Color(0xFF638541)
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                  ),
                  child: guardando
                      ? const CircularProgressIndicator()
                      : const Text('Confirmar venta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemViaje(ViajeModel viaje) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _seleccionarViaje(viaje),
        leading: const Icon(Icons.directions_bus, color: Color(0xFF638541)),
        title: Text(
          '${viaje.origenRuta ?? 'Ruta ${viaje.fkRuta}'} ➔ ${viaje.destinoRuta ?? ''}'.trim(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Hora: ${_formatearHora(viaje.horaSalida)}   Bus: ${viaje.fkBus ?? '-'}\nEstado: ${viaje.estado}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildGridAsientos() {
    if (_cargandoAsientos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF638541)),
        ),
      );
    }

    if (_asientos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No hay asientos registrados para el bus ID ${_viajeSeleccionado?.fkBus ?? '-'}.'
          ' Si en la base hay datos, revisa permisos de lectura (RLS) en asientos.',
        ),
      );
    }

    final asientosOrdenados = [..._asientos]..sort((a, b) => a.numero.compareTo(b.numero));

    final Map<int, List<AsientoModel>> porFila = {};
    for (final asiento in asientosOrdenados) {
      final fila = asiento.fila;
      porFila.putIfAbsent(fila, () => []).add(asiento);
    }

    final filas = porFila.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildResumenChip('Disponibles', _cantidadDisponibles(), const Color(0xFF638541)),
            _buildResumenChip('Vendidos', _cantidadVendidos(), Colors.red),
            _buildResumenChip('Reservados', _cantidadReservados(), Colors.amber),
            _buildResumenChip('Inactivos', _cantidadInactivos(), Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        // Leyenda
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: const [
            _LegendItem(color: Color(0xFF638541), texto: 'Disponible'),
            _LegendItem(color: Colors.red, texto: 'Vendido'),
            _LegendItem(color: Colors.amber, texto: 'Reservado'),
            _LegendItem(color: Colors.grey, texto: 'Inactivo'),
            _LegendItem(color: Colors.blue, texto: 'Seleccionado'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 500,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(120),
              constrained: false,
              child: SizedBox(
                width: 270,
                child: Column(
                  children: [
                    // Layout de 5 columnas: 2 izq | pasillo | 2 der
                    ...filas.map((fila) {
                      final asientosEnFila = porFila[fila]!..sort((a, b) => a.numero.compareTo(b.numero));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Columna 0: Asiento izquierda 1
                            SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.isNotEmpty ? asientosEnFila[0] : null)),
                            const SizedBox(width: 6),
                            // Columna 1: Asiento izquierda 2
                            SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 1 ? asientosEnFila[1] : null)),
                            const SizedBox(width: 16),
                            // Columna 2: PASILLO
                            SizedBox(
                              width: 30,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward, size: 16, color: Colors.grey[400]),
                                  Text('PASILLO', style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                                  Icon(Icons.arrow_downward, size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Columna 3: Asiento derecha 1
                            SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 3 ? asientosEnFila[3] : null)),
                            const SizedBox(width: 6),
                            // Columna 4: Asiento derecha 2
                            SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 2 ? asientosEnFila[2] : null)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Usa dos dedos para hacer zoom y arrastrar el mapa',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        if (_asientosSeleccionadosIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: const Color(0xFFEEF5E7),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_asientosSeleccionadosIds.length} asiento(s) seleccionado(s)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: Bs ${(_precioUnitarioActual() * _asientosSeleccionadosIds.length).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona "Confirmar venta" en la barra inferior.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAsientoWidget(AsientoModel? asiento) {
    if (asiento == null) {
      return const SizedBox.shrink();
    }

    final tieneBoleto = _detalleBoletoPorAsiento.containsKey(asiento.id);
    final estaBloqueado = _asientoBloqueadoPorEstado(asiento);
    final nombreComprador = _nombreVisibleComprador(asiento);
    final seleccionado = _asientosSeleccionadosIds.contains(asiento.id);
    final colorEstado = _colorAsiento(asiento);
    final bordeColor = seleccionado ? Colors.blue : colorEstado;
    final fondo = seleccionado ? Colors.blue.withAlpha(35) : colorEstado.withAlpha(50);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (tieneBoleto) {
            _mostrarDetalleBoleto(asiento);
            return;
          }
          if (estaBloqueado) {
            return;
          }
          _toggleSeleccionAsiento(asiento);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: bordeColor, width: seleccionado ? 2.2 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                color: bordeColor,
                size: 20,
              ),
              Text(
                '${asiento.numero}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: bordeColor,
                ),
              ),
              if (tieneBoleto && nombreComprador.isNotEmpty)
                Text(
                  nombreComprador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              if (seleccionado)
                const Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenChip(String titulo, int cantidad, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 6),
          Text(
            '$titulo: $cantidad',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSeleccionado =
        _precioUnitarioActual() * _asientosSeleccionadosIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Venta de Boletos',
            style: TextStyle(color: Colors.white)),
      ),
      body: _cargandoViajes
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF638541)))
          : RefreshIndicator(
              onRefresh: _cargarViajesHoy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_viajeSeleccionado == null) ...[
                      // Sección de hoy
                      if (_viajesHoy.isNotEmpty) ...[
                        const Text(
                          'VIAJES PROGRAMADOS Y EN MARCHA',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ..._viajesHoy.map(_buildItemViaje),
                        const SizedBox(height: 16),
                      ],
                      // Secciones de viajes futuros agrupados por fecha
                      ..._viajesPorFecha.entries.map((entry) {
                        final fecha = entry.key;
                        final viajes = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'VIAJES - ${_formatearFechaDisplay(fecha).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ...viajes.map(_buildItemViaje),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                      // Mensaje si no hay viajes en absoluto
                      if (_viajesHoy.isEmpty && _viajesPorFecha.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No hay viajes disponibles.'),
                        ),
                    ] else ...[
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _viajeSeleccionado = null;
                                        _asientos = [];
                                        _detalleBoletoPorAsiento = {};
                                        _asientosSeleccionadosIds.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Mapa de Asientos',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_viajeSeleccionado!.origenRuta ?? 'Ruta ${_viajeSeleccionado!.fkRuta}'} ➔ ${_viajeSeleccionado!.destinoRuta ?? ''}'.trim(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Hora: ${_formatearHora(_viajeSeleccionado!.horaSalida)}   Bus: ${_viajeSeleccionado!.fkBus ?? '-'}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGridAsientos(),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _viajeSeleccionado != null &&
              _asientosSeleccionadosIds.isNotEmpty
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE6D3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_asientosSeleccionadosIds.length} asiento(s) seleccionados',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: Bs ${totalSeleccionado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F3A2A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _mostrarModalRegistrarVenta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF638541),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('Confirmar venta'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.airline_seat_recline_normal, color: color, size: 17),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
