import 'package:flutter/material.dart';

class CurvedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavItem> items;

  const CurvedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;

    return SizedBox(
      height: 80 + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Curved background
          Positioned.fill(
            child: CustomPaint(
              painter: _CurvedNavPainter(
                color: bgColor,
                shadowColor: isDark ? Colors.black54 : Colors.black12,
                selectedIndex: currentIndex,
                itemCount: items.length,
              ),
            ),
          ),

          // Nav items
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = index == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: _NavItemWidget(
                      item: items[index],
                      isSelected: isSelected,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget? badge;

  const CurvedNavItem({
    required this.icon,
    IconData? activeIcon,
    required this.label,
    this.badge,
  }) : activeIcon = activeIcon ?? icon;
}

class _NavItemWidget extends StatelessWidget {
  final CurvedNavItem item;
  final bool isSelected;

  const _NavItemWidget({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const selectedColor = Color(0xFFFF9800);
    final unselectedColor = isDark ? Colors.white60 : Colors.black54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating selected indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: isSelected ? const EdgeInsets.all(10) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: item.badge != null && !isSelected
                  ? Badge(
                      label: item.badge!,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? Colors.white : unselectedColor,
                        size: isSelected ? 24 : 22,
                      ),
                    )
                  : Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? Colors.white : unselectedColor,
                      size: isSelected ? 24 : 22,
                    ),
            ),
          ),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isSelected ? 11 : 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

class _CurvedNavPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final int selectedIndex;
  final int itemCount;

  _CurvedNavPainter({
    required this.color,
    required this.shadowColor,
    required this.selectedIndex,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final itemWidth = size.width / itemCount;
    final centerX = (selectedIndex * itemWidth) + (itemWidth / 2);

    const notchRadius = 32.0;
    const notchDepth = 12.0;
    const curveSpread = 40.0;

    final path = Path();

    // Start from top-left
    path.moveTo(0, 14);

    // Line to the start of the notch curve
    final notchStartX = centerX - notchRadius - curveSpread;
    if (notchStartX > 0) {
      path.lineTo(notchStartX, 14);
    }

    // First curve down into the notch
    path.cubicTo(
      centerX - notchRadius - 10,
      14,
      centerX - notchRadius + 5,
      14 - notchDepth,
      centerX,
      14 - notchDepth,
    );

    // Second curve up out of the notch
    path.cubicTo(
      centerX + notchRadius - 5,
      14 - notchDepth,
      centerX + notchRadius + 10,
      14,
      centerX + notchRadius + curveSpread,
      14,
    );

    // Line to top-right
    path.lineTo(size.width, 14);

    // Right side, bottom, left side
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow first
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);

    // Draw the background
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNavPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.color != color ||
        oldDelegate.itemCount != itemCount;
  }
}
