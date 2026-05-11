import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/asiento_controller.dart';
import '../controllers/boleto_controller.dart';
import '../models/asiento_model.dart';
import '../models/viaje_model.dart';

class ViajeDetalleView extends StatefulWidget {
  final ViajeModel viaje;

  const ViajeDetalleView({super.key, required this.viaje});

  @override
  State<ViajeDetalleView> createState() => _ViajeDetalleViewState();
}

class _ViajeDetalleViewState extends State<ViajeDetalleView> {
  final BoletoController _boletoController = BoletoController();
  final AsientoController _asientoController = AsientoController();

  bool _cargando = true;
  List<AsientoModel> _asientos = [];
  Map<int, Map<String, dynamic>> _detalleBoletoPorAsiento = {};
  double _totalRecaudado = 0.0;
  Map<int, Map<String, dynamic>> _estadisticasVendedores = {};

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        _asientoController.obtenerAsientosPorBus(widget.viaje.fkBus ?? 0),
        _boletoController.obtenerDetalleBoletosPorViaje(widget.viaje.id),
        _boletoController.obtenerTotalRecaudadoPorViaje(widget.viaje.id),
        _boletoController.obtenerEstadisticasVendedores(widget.viaje.id),
      ]);

      if (!mounted) return;
      setState(() {
        _asientos = resultados[0] as List<AsientoModel>;
        _detalleBoletoPorAsiento =
            resultados[1] as Map<int, Map<String, dynamic>>;
        _totalRecaudado = resultados[2] as double;
        _estadisticasVendedores =
            resultados[3] as Map<int, Map<String, dynamic>>;
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

  Color _colorAsiento(AsientoModel asiento) {
    final tieneBoletoEnViaje = _detalleBoletoPorAsiento.containsKey(asiento.id);
    if (tieneBoletoEnViaje) return Colors.red;

    final estado = asiento.estado.toLowerCase();
    if (estado == 'mantenimiento' || estado == 'inactivo') return Colors.grey;
    return const Color(0xFF638541);
  }

  String _nombreVisibleComprador(AsientoModel asiento) {
    final detalle = _detalleBoletoPorAsiento[asiento.id];
    if (detalle == null) return '';
    final nombre = (detalle['nombre_pasajero'] ?? '').toString().trim();
    if (nombre.isEmpty) return '';
    final partes = nombre.split(RegExp(r'\s+'));
    return partes.first;
  }

  Future<void> _mostrarDetalleBoleto(AsientoModel asiento) async {
    final detalle = _detalleBoletoPorAsiento[asiento.id];
    if (detalle == null) {
      return;
    }

    final nombre = (detalle['nombre_pasajero'] ?? '').toString();
    final ci = (detalle['ci_pasajero'] ?? '').toString();
    final estado = (detalle['estado'] ?? '').toString();
    final vendedorId = (detalle['fk_usuario_vendedor'] ?? '').toString();
    final precio = (detalle['precio'] ?? '').toString();
    final origen = (detalle['origen'] ?? '').toString();
    final destino = (detalle['destino'] ?? '').toString();
    final fechaRaw = detalle['fecha_venta'];
    String nombreVendedor = vendedorId;

    // Formatear fecha
    String fechaFormato = '-';
    if (fechaRaw != null) {
      final parsed = DateTime.tryParse(fechaRaw.toString());
      if (parsed != null) {
        final y = parsed.year.toString().padLeft(4, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        final d = parsed.day.toString().padLeft(2, '0');
        final hh = parsed.hour.toString().padLeft(2, '0');
        final mm = parsed.minute.toString().padLeft(2, '0');
        fechaFormato = '$d/$m/$y $hh:$mm';
      }
    }

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
                  valor: fechaFormato,
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

  Widget _buildGridAsientos() {
    if (_cargando) {
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
          'No hay asientos registrados para el bus ID ${widget.viaje.fkBus ?? '-'}.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final asientosOrdenados = [..._asientos]
      ..sort((a, b) => a.numero.compareTo(b.numero));

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
            Text('Vendido', style: TextStyle(fontSize: 12)),
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
                      final asientosEnFila = porFila[fila]!
                        ..sort((a, b) => a.numero.compareTo(b.numero));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Columna 0: Asiento izquierda 1
                            SizedBox(
                                width: 38,
                                child: _buildAsientoWidget(
                                asientosEnFila.isNotEmpty
                                        ? asientosEnFila[0]
                                        : null)),
                            const SizedBox(width: 6),
                            // Columna 1: Asiento izquierda 2
                            SizedBox(
                                width: 38,
                                child: _buildAsientoWidget(
                                    asientosEnFila.length > 1
                                        ? asientosEnFila[1]
                                        : null)),
                            const SizedBox(width: 16),
                            // Columna 2: PASILLO
                            SizedBox(
                              width: 30,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward,
                                      size: 16, color: Colors.grey[400]),
                                  Text('PASILLO',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[500])),
                                  Icon(Icons.arrow_downward,
                                      size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Columna 3: Asiento derecha 1
                            SizedBox(
                                width: 38,
                                child: _buildAsientoWidget(
                                    asientosEnFila.length > 3
                                        ? asientosEnFila[3]
                                        : null)),
                            const SizedBox(width: 6),
                            // Columna 4: Asiento derecha 2
                            SizedBox(
                                width: 38,
                                child: _buildAsientoWidget(
                                    asientosEnFila.length > 2
                                        ? asientosEnFila[2]
                                        : null)),
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
      ],
    );
  }

  Widget _buildAsientoWidget(AsientoModel? asiento) {
    if (asiento == null) {
      return const SizedBox.shrink();
    }

    final tieneBoleto = _detalleBoletoPorAsiento.containsKey(asiento.id);
    final nombreComprador = _nombreVisibleComprador(asiento);
    final colorEstado = _colorAsiento(asiento);
    final bordeColor = colorEstado;
    final fondo = colorEstado.withAlpha(50);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (tieneBoleto) {
            _mostrarDetalleBoleto(asiento);
            return;
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: bordeColor, width: 1.5),
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
        title: const Text('Detalle del Viaje',
            style: TextStyle(color: Colors.white)),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF638541)))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del viaje
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.viaje.origenRuta ?? 'Ruta ${widget.viaje.fkRuta}'} ➔ ${widget.viaje.destinoRuta ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fecha: ${widget.viaje.fechaSalida}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Hora: ${_formatearHora(widget.viaje.horaSalida)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Bus: ${widget.viaje.fkBus ?? '-'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Estado: ${widget.viaje.estado}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total recaudado
                    Card(
                      elevation: 1,
                      color: const Color(0xFFEEF5E7),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL RECAUDADO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bs ${_totalRecaudado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF638541),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vendedores
                    const Text(
                      'VENDEDORES Y SUS VENTAS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_estadisticasVendedores.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No hay vendedores registrados para este viaje',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ...List.generate(_estadisticasVendedores.length, (index) {
                        final vendedorId =
                            _estadisticasVendedores.keys.toList()[index];
                        final stats = _estadisticasVendedores[vendedorId]!;
                        final nombres = (stats['nombres'] ?? '').toString();
                        final apellidos = (stats['apellidos'] ?? '').toString();
                        final nombreCompleto = '$nombres $apellidos'.trim();
                        final cantidadBoletos = stats['cantidad_boletos'] ?? 0;
                        final totalRecaudado =
                            (stats['total_recaudado'] as num).toDouble();

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombreCompleto.isEmpty
                                      ? 'Vendedor #$vendedorId'
                                      : nombreCompleto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Boletos vendidos: $cantidadBoletos',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      'Bs ${totalRecaudado.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF638541),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),

                    // Mapa de asientos
                    const Text(
                      'MAPA DE ASIENTOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildGridAsientos(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
