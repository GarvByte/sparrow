import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../data/media_item.dart';
import 'network_media_image.dart';

class ContinueWatchingCard extends StatelessWidget {
  final MediaItem item;
  final double? width;
  final VoidCallback? onTap;

  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cardWidth = width ?? responsive.continueWatchingWidth;
    final cardHeight = cardWidth * (9 / 16);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          // margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media Image
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => ErrorImagePlaceholder(),
                  placeholder: (context, url) => Center(
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

                // Subtle Dim Overlay
                Container(color: Colors.black.withValues(alpha: 0.35)),

                // Center Circular Play Button
                Center(
                  child: Container(
                    width: responsive.scale(42, min: 36, max: 48),
                    height: responsive.scale(42, min: 36, max: 48),
                    decoration: BoxDecoration(
                      color: ColorPalette.surfaceContainerHighest.withValues(
                        alpha: 0.9,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: responsive.iconSize(26, min: 22, max: 30),
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                  ),
                ),

                // Top-Right Time Left Badge
                if (item.durationLeft != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ColorPalette.ghostBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        item.durationLeft!,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(10, min: 8.5, max: 11),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                // Docked Bottom Progress Bar
                if (item.progress != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 3.5,
                      color: ColorPalette.surfaceContainerHighest,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: item.progress!.clamp(0.0, 1.0),
                        child: Container(color: ColorPalette.primaryGreen),
                      ),
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
