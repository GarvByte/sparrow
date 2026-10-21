import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';

class SparrowHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String subtitle;
  const SparrowHeader({super.key, this.subtitle = 'HOME'});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final headerHeight = responsive.headerHeight;
    final logoSize = responsive.scale(36, min: 30, max: 40);
    final buttonSize = responsive.scale(38, min: 34, max: 42);

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.backgroundBlack.withValues(alpha: 0.88),
        border: const Border(
          bottom: BorderSide(color: ColorPalette.ghostBorder, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: headerHeight,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(16, min: 12, max: 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & App Title
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(responsive.radius(8)),
                    child: Image.asset(
                      'assets/images/sparrow_logo.png',
                      height: logoSize,
                      width: logoSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SPARROW',
                            style: TextStyle(
                              color: ColorPalette.fontWhite,
                              fontSize: responsive.sp(18, min: 15, max: 21),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: ColorPalette.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: ColorPalette.textMuted,
                          fontSize: responsive.sp(10, min: 8.5, max: 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Button: Search (Notifications & Profile removed across all layouts)
              TvFocusable(
                onSelect: () => context.go('/search'),
                borderRadius: BorderRadius.circular(buttonSize / 2),
                child: _HeaderCircleButton(
                  icon: Icons.search_rounded,
                  size: buttonSize,
                  onTap: () {
                    context.go('/search');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    this.size = 38.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainer.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
        ),
        child: Center(
          child: Icon(
            icon,
            size: (size * 0.52).clamp(16.0, 22.0),
            color: ColorPalette.fontWhite,
          ),
        ),
      ),
    );
  }
}
