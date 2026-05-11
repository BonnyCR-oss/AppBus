import 'package:flutter/material.dart';
import '../models/ruta_model.dart';
import '../controllers/ruta_controller.dart';

class RutasView extends StatefulWidget {
  const RutasView({
    super.key,
    required this.esAdmin,
  });

  final bool esAdmin;

  @override
  State<RutasView> createState() => _RutasViewState();
}

class _RutasViewState extends State<RutasView> {
  final RutaController _rutaController = RutaController();
  
  List<RutaModel> _rutas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final rutas = await _rutaController.obtenerRutas();
      setState(() {
        _rutas = rutas;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargando = false);
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

  void _mostrarDialogoNuevaRuta() {
    final TextEditingController origenCtrl = TextEditingController();
    final TextEditingController destinoCtrl = TextEditingController();
    final TextEditingController precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Ruta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: origenCtrl,
              decoration: const InputDecoration(labelText: 'Origen'),
            ),
            TextField(
              controller: destinoCtrl,
              decoration: const InputDecoration(labelText: 'Destino'),
            ),
            TextField(
              controller: precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio', prefixText: 'Bs. '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              final origen = origenCtrl.text.trim();
              final destino = destinoCtrl.text.trim();
              final precio = double.tryParse(precioCtrl.text.trim());

              if (origen.isEmpty || destino.isEmpty || precio == null || precio <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa los campos correctamente'), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.pop(dialogContext);

              setState(() => _cargando = true);
              try {
                await _rutaController.crearRuta(
                  origen: origen,
                  destino: destino,
                  precio: precio,
                );
                await _cargarTodo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ruta creada correctamente'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
                if (mounted) setState(() => _cargando = false);
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
        title: const Text('Rutas', style: TextStyle(color: Colors.white)),
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
                    const Text('RUTAS DISPONIBLES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ..._rutas.map((ruta) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('${ruta.origen} ➔ ${ruta.destino}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Precio de extremo a extremo: Bs. ${ruta.precio}'),
                            trailing: widget.esAdmin
                                ? IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF638541)),
                                    onPressed: () => _mostrarDialogoEdicion(ruta),
                                  )
                                : null,
                          ),
                        )),
                  ],
                ),
              ),
            ),
      floatingActionButton: widget.esAdmin
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoNuevaRuta,
              backgroundColor: const Color(0xFF638541),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva ruta'),
            )
          : null,
    );
  }
}