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
  List<RutaModel> _rutas = [];
  List<AsientoModel> _asientos = [];
  Map<int, Map<String, dynamic>> _detalleBoletoPorAsiento = {};
  Set<int> _asientosSeleccionadosIds = <int>{};
  ViajeModel? _viajeSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarViajesHoy();
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
      setState(() {
        _viajesHoy = viajes;
        _rutas = rutas;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoViajes = false);
    }
  }

  Future<void> _seleccionarViaje(ViajeModel viaje) async {
    if (viaje.fkBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este viaje no tiene bus asignado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _viajeSeleccionado = viaje;
      _cargandoAsientos = true;
      _asientos = [];
      _detalleBoletoPorAsiento = {};
      _asientosSeleccionadosIds.clear();
    });

    try {
      final resultados = await Future.wait([
        _asientoController.obtenerAsientosPorBus(viaje.fkBus!),
        _boletoController.obtenerDetalleBoletosPorViaje(viaje.id),
      ]);
      final asientos = resultados[0] as List<AsientoModel>;
      final detalleBoletos = resultados[1] as Map<int, Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _asientos = asientos;
        _detalleBoletoPorAsiento = detalleBoletos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoAsientos = false);
    }
  }

  String _formatearHora(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    return '${partes[0]}:${partes[1]}';
  }

  Color _colorAsiento(AsientoModel asiento) {
    final tieneBoletoEnViaje = _detalleBoletoPorAsiento.containsKey(asiento.id);
    if (tieneBoletoEnViaje) return Colors.red;

    final estado = asiento.estado.toLowerCase();
    if (estado == 'mantenimiento' || estado == 'inactivo') return Colors.grey;
    return const Color(0xFF638541);
  }

  bool _asientoBloqueadoPorEstado(AsientoModel asiento) {
    final estado = asiento.estado.toLowerCase();
    return estado == 'mantenimiento' || estado == 'inactivo';
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

  List<AsientoModel> _asientosSeleccionados() {
    final seleccionados = _asientos
        .where((a) => _asientosSeleccionadosIds.contains(a.id))
        .toList();
    seleccionados.sort((a, b) => a.numero.compareTo(b.numero));
    return seleccionados;
  }

  void _toggleSeleccionAsiento(AsientoModel asiento) {
    if (_detalleBoletoPorAsiento.containsKey(asiento.id)) return;
    if (_asientoBloqueadoPorEstado(asiento)) return;

    setState(() {
      if (_asientosSeleccionadosIds.contains(asiento.id)) {
        _asientosSeleccionadosIds.remove(asiento.id);
      } else {
        _asientosSeleccionadosIds.add(asiento.id);
      }
    });
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
          title: Text('Detalle del asiento ${asiento.numero}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comprador: ${nombre.isEmpty ? '-' : nombre}'),
              Text('CI: ${ci.isEmpty ? '-' : ci}'),
              Text('Precio: Bs ${precio.isEmpty ? '-' : precio}'),
              Text('Fecha venta: $fecha'),
              Text('Estado: ${estado.isEmpty ? '-' : estado}'),
              Text('Origen: $origen'),
              Text('Destino: $destino'),
              // mostramos el nombre completo del vendedor
              Text('Vendedor: ${nombreVendedor.isEmpty ? '-' : nombreVendedor}',
              ),
            ],
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

    final sesion = await _sessionService.leerSesion();

    await _boletoController.registrarVenta(
      viajeId: _viajeSeleccionado!.id,
      asientos: seleccionados,
      nombrePasajero: nombreComprador,
      ciPasajero: ciComprador,
      precioUnitario: precio,
      vendedorId: sesion?.usuarioId,
      origen: origen,
      destino: destino,     
    );

    final resultados = await Future.wait([
      _asientoController.obtenerAsientosPorBus(_viajeSeleccionado!.fkBus!),
      _boletoController.obtenerDetalleBoletosPorViaje(_viajeSeleccionado!.id),
    ]);
    final asientosActualizados = resultados[0] as List<AsientoModel>;
    final detalleBoletos = resultados[1] as Map<int, Map<String, dynamic>>;

    if (!mounted) return;
    setState(() {
      _asientos = asientosActualizados;
      _detalleBoletoPorAsiento = detalleBoletos;
      _asientosSeleccionadosIds.clear();
    });
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
                      decoration: const InputDecoration(labelText: 'Nombre del comprador'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ciCtrl,
                      decoration: const InputDecoration(labelText: 'CI del comprador'),
                    ),
                    const SizedBox(height: 14),

                    // editar precio
                    TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio por asiento (Bs)',
                        prefixText: 'Bs ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // forzamos a que el total se actualice mientras escriben
                        setModalState(() {}); 
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: origenSeleccionado,
                      decoration: const InputDecoration(labelText: 'Sube en'),
                      items: paradas.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setModalState(() => origenSeleccionado = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: destinoSeleccionado,
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
                  onPressed: guardando ? null : () async {
                    final nombre = nombreCtrl.text.trim();
                    final ci = ciCtrl.text.trim();
                    final precioFinal = double.tryParse(precioCtrl.text) ?? 0.0;

                    if (nombre.isEmpty || ci.isEmpty || precioFinal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa todos los datos y el precio.')),
                      );
                      return;
                    }

                    setModalState(() => guardando = true);
                    try {
                      await _registrarVenta(
                        nombreComprador: nombre,
                        ciComprador: ci,
                        origen: origenSeleccionado,
                        destino: destinoSeleccionado,
                        precio: precioFinal,
                      );
                      if (!mounted) return;
                      Navigator.of(contextoModal).pop();
                    } catch (e) {
                      setModalState(() => guardando = false);
                      // Manejar error...
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF638541), foregroundColor: Colors.white),
                  child: guardando ? const CircularProgressIndicator() : const Text('Confirmar venta'),
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
        // Leyenda
        Row(
          children: const [
            Icon(Icons.airline_seat_recline_normal, color: Color(0xFF638541), size: 18),
            SizedBox(width: 4),
            Text('Disponible', style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.airline_seat_recline_normal, color: Colors.red, size: 18),
            SizedBox(width: 4),
            Text('Ocupado', style: TextStyle(fontSize: 12)),
            SizedBox(width: 12),
            Icon(Icons.airline_seat_recline_normal, color: Colors.grey, size: 18),
            SizedBox(width: 4),
            Text('Inactivo', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 460,
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
                            SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 0 ? asientosEnFila[0] : null)),
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
                                  Text('PASILLO', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _mostrarModalRegistrarVenta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF638541),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Registrar venta'),
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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: bordeColor, width: seleccionado ? 2.2 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                color: bordeColor,
                size: 18,
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
                  size: 10,
                  color: Colors.blue,
                ),
            ],
          ),
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
                      const Text(
                        'VIAJES PROGRAMADOS O EN MARCHA',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_viajesHoy.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No hay viajes PROGRAMADOS O EN MARCHA.'),
                        )
                      else
                        ..._viajesHoy.map(_buildItemViaje),
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
    );
  }
}
