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
            ],
          ),
        ),
      ),
    );
  }
}
