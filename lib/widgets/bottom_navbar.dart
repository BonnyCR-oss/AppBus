import 'package:flutter/material.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });
}

class CustomBottomNavBar extends StatefulWidget {
  final List<BottomNavItem> items;
  final int initialIndex;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.backgroundColor = const Color(0xFF638541),
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white54,
    this.height = 70,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != _currentIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.items.length,
          (index) {
            final item = widget.items[index];
            final isActive = _currentIndex == index;
            final isEnabled = item.isEnabled;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled
                      ? () {
                          setState(() => _currentIndex = index);
                          item.onTap();
                        }
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive && isEnabled
                            ? widget.activeColor
                            : widget.inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive && isEnabled
                              ? widget.activeColor
                              : widget.inactiveColor,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
