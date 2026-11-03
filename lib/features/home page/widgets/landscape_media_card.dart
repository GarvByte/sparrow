import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../../../shared/media_item.dart';

class LandscapeMediaCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  final VoidCallback? onTap;

  const LandscapeMediaCard({
    super.key,
    required this.item,
    this.width = 240.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final height = width * (9 / 16);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Landscape Artwork
                Container(
                  color: ColorPalette.placeholder,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: ColorPalette.error),
                        Text(
                          "Poster unavailable",
                          style: TextStyle(
                            color: ColorPalette.textSecondary,
                            fontSize: responsive.sp(10, min: 8.5, max: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 360,
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  errorWidget: (context, url, error) => const ErrorImagePlaceholder(),
                  placeholder: (context, url) => Container(
                    color: ColorPalette.surfaceContainerLow,
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                      splashColor: ColorPalette.fontWhite.withValues(
                        alpha: 0.35,
                      ),
                      highlightColor: ColorPalette.primaryGreen.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        responsive.radius(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
