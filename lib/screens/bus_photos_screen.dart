import 'package:flutter/material.dart';

class PantallaFotosBus extends StatelessWidget {
  const PantallaFotosBus({super.key});

  // --- NUEVA FUNCIÓN: Muestra la foto en grande (popup) ---
  void _mostrarFotoGrande(BuildContext context, String imagenPath, int index) {
    showDialog(
      context: context,
      // barrierDismissible: true permite cerrar tocando fuera de la foto
      builder: (BuildContext context) {
        // Usamos Dialog (en lugar de AlertDialog) para controlar mejor el tamaño
        return Dialog(
          backgroundColor: Colors.transparent, // Fondo transparente alrededor de la foto
          insetPadding: const EdgeInsets.all(10), // Margen mínimo con los bordes de la pantalla
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Contenedor de la Imagen
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ],
                ),
                // ClipRRect para que la imagen siga el borde redondeado
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagenPath,
                    // BoxFit.contain asegura que la foto se vea COMPLETA sin cortarse
                    fit: BoxFit.contain, 
                    // Ajustamos el tamaño máximo para que quepa en pantalla
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.8,
                  ),
                ),
              ),
              
              // 2. Botón de Cerrar (X) arriba a la derecha de la foto
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54, // Círculo semitransparente
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context), // Cerrar el diálogo
                  ),
                ),
              ),
              
              // 3. Etiqueta con el número de foto abajo (Opcional)
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Foto ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tus tres imágenes de la carpeta assets/images/
    final List<String> fotosBuses = [
      'assets/images/bus_frente.jpeg',
      'assets/images/bus_frente1.jpeg',
      'assets/images/bus_izquierda.jpeg',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638541),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Galería del Bus',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 fotos por fila
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: fotosBuses.length,
        itemBuilder: (context, index) {
          // --- CAMBIO AQUÍ: Envolvemos todo en InkWell ---
          return InkWell(
            onTap: () {
              // Llamamos a la función de zoom pasando la ruta de la foto y el índice
              _mostrarFotoGrande(context, fotosBuses[index], index);
            },
            borderRadius: BorderRadius.circular(16), // Para que el efecto de toque siga el borde
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  fotosBuses[index],
                  // BoxFit.cover es perfecto para la cuadrícula (recorta un poco pero llena el cuadrado)
                  fit: BoxFit.cover, 
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}