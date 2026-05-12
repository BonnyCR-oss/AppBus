import 'package:flutter/material.dart';

import '../controllers/reports_controller.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView>
    with SingleTickerProviderStateMixin {
  final ReportsController _reportsController = ReportsController();

  String _periodSelect = 'mes';
  late TabController _tabController;

  // Estados de carga
  bool _cargandoResumen = false;
  bool _cargandoVentas = false;
  bool _cargandoViajes = false;

  // Datos
  Map<String, dynamic> _resumen = {};
  List<Map<String, dynamic>> _ventasPorUsuario = [];
  List<Map<String, dynamic>> _detallesViajes = [];

  final Map<String, String> _periodLabels = {
    'hoy': 'Hoy',
    'semana': 'Esta Semana',
    '2semanas': 'Últimas 2 Semanas',
    'mes': 'Este Mes',
    'mesAnterior': 'Mes Anterior',
    'anno': 'Este Año',
    'annoAnterior': 'Año Anterior',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarTodosLosReportes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodosLosReportes() async {
    _cargarResumen();
    _cargarVentasPorUsuario();
    _cargarDetallesViajes();
  }

  Future<void> _cargarResumen() async {
    if (!mounted) return;
    setState(() => _cargandoResumen = true);
    try {
      final datos = await _reportsController.obtenerResumen(_periodSelect);
      if (!mounted) return;
      setState(() => _resumen = datos);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _cargandoResumen = false);
    }
  }

  Future<void> _cargarVentasPorUsuario() async {
    if (!mounted) return;
    setState(() => _cargandoVentas = true);
    try {
      final datos = await _reportsController.obtenerVentasPorUsuario(_periodSelect);
      if (!mounted) return;
      setState(() => _ventasPorUsuario = datos);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _cargandoVentas = false);
    }
  }

  Future<void> _cargarDetallesViajes() async {
    if (!mounted) return;
    setState(() => _cargandoViajes = true);
    try {
      final datos = await _reportsController.obtenerDetallesViajes(_periodSelect);
      if (!mounted) return;
      setState(() => _detallesViajes = datos);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _cargandoViajes = false);
    }
  }

  void _cambiarPeriodo(String nuevoPeriodo) {
    setState(() => _periodSelect = nuevoPeriodo);
    _cargarTodosLosReportes();
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

  Widget _buildPeriodoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _periodSelect,
        items: _periodLabels.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (valor) {
          if (valor != null) _cambiarPeriodo(valor);
        },
      ),
    );
  }

  Widget _buildResumenCard(String titulo, dynamic valor, IconData icon,
      {Color? color}) {
    final valorText = valor is double ? valor.toStringAsFixed(2) : valor.toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF638541)).withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? const Color(0xFF638541)).withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? const Color(0xFF638541)),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valorText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabResumen() {
    if (_cargandoResumen) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF638541)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildResumenCard(
                'Ingresos Total',
                'Bs ${_resumen['totalIngresos']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money,
                color: Colors.green,
              ),
              _buildResumenCard(
                'Viajes Completados',
                _resumen['cantidadViajes'] ?? 0,
                Icons.route_outlined,
                color: Colors.blue,
              ),
              _buildResumenCard(
                'Boletos Vendidos',
                _resumen['cantidadBoletos'] ?? 0,
                Icons.confirmation_number_outlined,
                color: Colors.orange,
              ),
              _buildResumenCard(
                'Promedio por Viaje',
                'Bs ${_resumen['promedioPorViaje']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.trending_up,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabVentas() {
    if (_cargandoVentas) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF638541)),
      );
    }

    if (_ventasPorUsuario.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay ventas en este período'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _ventasPorUsuario.asMap().entries.map((entry) {
          final index = entry.key;
          final venta = entry.value;
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF638541),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venta['nombreUsuario'] ?? 'Desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${venta['cantidadVentas']} boleto(s) vendidos',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bs ${(venta['totalIngresos'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF638541),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabViajes() {
    if (_cargandoViajes) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF638541)),
      );
    }

    if (_detallesViajes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No hay viajes en este período'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _detallesViajes.map((viaje) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.directions_bus, color: const Color(0xFF638541)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viaje['ruta'] ?? 'Ruta desconocida',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${viaje['fecha']} - ${viaje['hora']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Boletos: ${viaje['cantidadBoletos']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estado: ${viaje['estado']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: viaje['estado'] == 'finalizado'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Bs ${(viaje['totalIngresos'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF638541),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Ventas por Usuario'),
            Tab(text: 'Viajes'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildPeriodoSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabResumen(),
                _buildTabVentas(),
                _buildTabViajes(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
