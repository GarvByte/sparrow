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
                  Image.asset(
                    'assets/images/sparrow_text_logo.png',
                    height: logoHeight,
                    fit: BoxFit.contain,
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
