import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../../../shared/media_item.dart';

class PortraitPosterCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  final VoidCallback? onTap;
  final bool trending;
  final int index;

  const PortraitPosterCard({
    super.key,
    required this.item,
    this.width = 165.0,
    this.onTap,
    this.trending = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final height = width * 1.5; // Strict 2:3 aspect ratio

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(responsive.radius(16)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster Image
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const ErrorImagePlaceholder(),
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ColorPalette.primaryGreen,
                  ),
                ),
              ),
            ),

            // Top-Left Rank Badge (e.g., #1, #2)
            if (trending == true)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(173, 0, 0, 0),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(24, min: 10, max: 40),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  splashColor: ColorPalette.fontWhite.withValues(alpha: 0.35),
                  highlightColor: ColorPalette.primaryGreen.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(responsive.radius(16)),
                ),
              ),
            ),
            // Border overlay — must be the LAST Stack child.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(responsive.radius(16)),
                    border: Border.all(
                      color: const Color.fromARGB(70, 255, 255, 255),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
