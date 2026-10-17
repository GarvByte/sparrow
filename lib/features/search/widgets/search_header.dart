import 'package:flutter/material.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchHeader extends StatelessWidget implements PreferredSizeWidget {
  const SearchHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final headerHeight = responsive.headerHeight;
    final logoSize = responsive.scale(32, min: 28, max: 36);
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
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        'SPARROW',
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(18, min: 15, max: 21),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorPalette.primaryGreen.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Buttons: Cast & Profile Avatar
              Row(
                children: [
                  _HeaderCircleButton(
                    icon: Icons.cast_rounded,
                    size: buttonSize,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Casting device scanner activated'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
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
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBWAiGeH4w35HDOJUtw2KNp78Roc2pUP5ZebEI3EJMMkx3xO5rvB-r13yWMF8hgr2HDhaSfIazpRIfx6X_a7RGazLWhTPAVt56yNPljCWx0PbMzc9TmTSpKzMGQnKQllSZAOP4Z3qegFm3teCmt9AJgBFoQam3JGz9x7pNLAGrcFcHumJVZQKczIxulrgvqK3YvFdm8UA3Jw1j2r0pvjDc_UEV_jHObqIg5ILlpwPcpWd7fUIVdy17DMA',
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
        child: Icon(
          icon,
          size: (size * 0.52).clamp(16.0, 22.0),
          color: ColorPalette.fontWhite,
        ),
      ),
    );
  }
}
