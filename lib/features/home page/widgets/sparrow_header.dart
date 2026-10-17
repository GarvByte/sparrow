import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';

class SparrowHeader extends ConsumerWidget implements PreferredSizeWidget {
  const SparrowHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final headerHeight = responsive.headerHeight;
    final logoSize = responsive.scale(36, min: 30, max: 40);
    final avatarSize = responsive.scale(34, min: 30, max: 38);
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
                        'HOME',
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

              // Action Buttons: Search, Notifications, Profile
              Row(
                children: [
                  _HeaderCircleButton(
                    icon: Icons.search_rounded,
                    size: buttonSize,
                    onTap: () {
                      context.go('/search');
                    },
                  ),
                  const SizedBox(width: 8),
                  _HeaderCircleButton(
                    icon: Icons.notifications_none_rounded,
                    size: buttonSize,
                    hasBadge: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  // Profile avatar with neon green outline
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorPalette.primaryGreen,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBzw6KngHnEuEUQZgpirQJpydvWlo7sYvciVj5v6folIX3wZ35CrwnANIQ9PpogR_GWkR9r_oxBwUjJePVluMVe7njr2Jy8-L9x9UfStxxHHazAL9kbHJwkn_o4WIm2TPvou8AdajUyQDwyE9M2o-EZ9KD5xI1LptNq1758npagA7jv3oTUOV7EzS094DweR3aXdMBIq6V5SPHZ_l4cRZSAH8mdyU8lC208plJ-7N2KUcYPfnlJaOILrw',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              size: 20,
                              color: ColorPalette.fontWhite,
                            ),
                      ),
                    ),
                  ),
                ],
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
  final bool hasBadge;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    this.size = 38.0,
    this.hasBadge = false,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: (size * 0.52).clamp(16.0, 22.0),
              color: ColorPalette.fontWhite,
            ),
            if (hasBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ColorPalette.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
