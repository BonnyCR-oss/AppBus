import 'package:flutter/material.dart';

import '../controllers/asiento_controller.dart';
import '../controllers/viaje_controller.dart';
import '../models/asiento_model.dart';
import '../models/viaje_model.dart';

class VentaView extends StatefulWidget {
  const VentaView({super.key});

  @override
  State<VentaView> createState() => _VentaViewState();
}

class _VentaViewState extends State<VentaView> {
  final ViajeController _viajeController = ViajeController();
  final AsientoController _asientoController = AsientoController();

  bool _cargandoViajes = true;
  bool _cargandoAsientos = false;
  List<ViajeModel> _viajesHoy = [];
  List<AsientoModel> _asientos = [];
  ViajeModel? _viajeSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarViajesHoy();
  }

  Future<void> _cargarViajesHoy() async {
    setState(() => _cargandoViajes = true);
    try {
      final viajes = await _viajeController.obtenerViajesDeHoy();
      if (!mounted) return;
      setState(() {
        _viajesHoy = viajes;
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
    });

    try {
      final asientos = await _asientoController.obtenerAsientosPorBus(viaje.fkBus!);
      if (!mounted) return;
      setState(() {
        _asientos = asientos;
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
    final estado = asiento.estado.toLowerCase();
    if (estado == 'ocupado' || estado == 'vendido') return Colors.red;
    if (estado == 'mantenimiento' || estado == 'inactivo') return Colors.grey;
    return const Color(0xFF638541);
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

    // Ordena asientos por número
    final asientosOrdenados = [..._asientos]..sort((a, b) => a.numero.compareTo(b.numero));

    // Agrupa asientos por fila (4 asientos por fila: 1-4, 5-8, etc.)
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
                SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 2 ? asientosEnFila[2] : null)),
                const SizedBox(width: 6),
                // Columna 4: Asiento derecha 2
                SizedBox(width: 38, child: _buildAsientoWidget(asientosEnFila.length > 3 ? asientosEnFila[3] : null)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAsientoWidget(AsientoModel? asiento) {
    if (asiento == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: asiento.estaDisponible
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Asiento ${asiento.numero} seleccionado')),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: _colorAsiento(asiento).withAlpha(50),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _colorAsiento(asiento), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.airline_seat_recline_normal,
                color: _colorAsiento(asiento),
                size: 18,
              ),
              Text(
                '${asiento.numero}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _colorAsiento(asiento),
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
                        'VIAJES DE HOY',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_viajesHoy.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No hay viajes para hoy.'),
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
