import 'package:flutter/material.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final bottomInset = responsive.padding.bottom;
    final navHeight = responsive.bottomNavHeight;

    return Positioned(
      left: responsive.scale(16, min: 12, max: 24),
      right: responsive.scale(16, min: 12, max: 24),
      bottom: bottomInset > 0 ? bottomInset + 4 : 14,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: responsive.bottomNavMaxWidth),
          height: navHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainerLow.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(responsive.radius(32)),
            border: Border.all(color: ColorPalette.ghostBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                selectedIndex: currentIndex,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => onTabSelected(0),
              ),
              _NavItem(
                index: 1,
                selectedIndex: currentIndex,
                icon: Icons.explore_outlined,
                label: 'Search',
                onTap: () => onTabSelected(1),
              ),
              _NavItem(
                index: 2,
                selectedIndex: currentIndex,
                icon: Icons.auto_awesome_rounded,
                label: 'Tv Shows',
                onTap: () => onTabSelected(2),
              ),
              _NavItem(
                index: 3,
                selectedIndex: currentIndex,
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  bool get isSelected => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final targetColor = isSelected
        ? const Color.fromARGB(201, 9, 0, 1)
        : ColorPalette.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? ColorPalette.primaryGreen
                  : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              tween: ColorTween(
                begin: isSelected ? ColorPalette.textMuted : const Color.fromARGB(201, 9, 0, 1),
                end: targetColor,
              ),
              builder: (context, animatedColor, child) {
                final activeColor = animatedColor ?? targetColor;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        icon,
                        size: responsive.iconSize(21, min: 18, max: 24),
                        color: activeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: responsive.sp(10, min: 8.5, max: 11),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                      child: Text(label),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
