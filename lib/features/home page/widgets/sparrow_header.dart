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
    final buttonSize = responsive.scale(38, min: 34, max: 42);
    final logoHeight = responsive.isTvOrDesktop
        ? 34.0
        : responsive.scale(26.0, min: 22.0, max: 30.0);

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
              // Weathered Pirate Sparrow Logo branding area
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 0,
                    height: 0,
                    child: Text(
                      'SPARROW',
                      style: TextStyle(fontSize: 0, color: Colors.transparent),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/sparrow_text_logo.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: responsive.sp(9, min: 8.0, max: 10.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
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
