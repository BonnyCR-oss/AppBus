import 'package:flutter/material.dart';

// Modelo para cada botón de la barra
class BottomNavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

// El Widget visual de la barra
class CustomBottomNavBar extends StatelessWidget {
  final List<BottomNavItem> items;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;
  
  // --- NUEVO: La variable que recibe qué pantalla está activa ---
  final int currentIndex; 

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.backgroundColor,
    required this.activeColor,
    required this.inactiveColor,
    this.currentIndex = 0, // Por defecto será el 0 (Venta)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          
          // --- MAGIA: Comparamos si este botón es el que está seleccionado ---
          final isSelected = index == currentIndex; 

          return GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  // Si está seleccionado, brilla. Si no, se apaga.
                  color: isSelected ? activeColor : inactiveColor,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}