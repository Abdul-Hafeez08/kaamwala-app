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
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 68,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final isSelected = index == currentIndex;
                      return Expanded(
                        child: InkWell(
                          onTap: () => onTap(index),
                          splashColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          highlightColor: Colors.transparent,
                          child: _NavItemWidget(
                            item: items[index],
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    const activeColor = Color(0xFFFF9800);
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF757575);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.22 : 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: item.badge != null && !isSelected
                ? Badge(
                    label: item.badge!,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 22,
                    ),
                  )
                : Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: isSelected ? 0.1 : 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
