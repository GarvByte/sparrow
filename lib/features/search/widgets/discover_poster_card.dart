import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class DiscoverPosterCard extends StatelessWidget {
  final MediaItem item;
  final double? width;
  final bool showRank;
  final int rank;
  final bool showBookmark;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  const DiscoverPosterCard({
    super.key,
    required this.item,
    this.width,
    this.showRank = false,
    this.rank = 1,
    this.showBookmark = true,
    this.onTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cardWidth = width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poster Image Container
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(responsive.radius(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const ErrorImagePlaceholder(),
                            placeholder: (context, url) => Container(
                              color: ColorPalette.surfaceContainerLow,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ColorPalette.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const ErrorImagePlaceholder(),

                    // Scrim gradient at bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.55, 1.0],
                            colors: [
                              Colors.transparent,
                              ColorPalette.surface.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top-Left Rank Badge (#1, #2)
                    if (showRank)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorPalette.backgroundBlack.withValues(
                              alpha: 0.82,
                            ),
                            borderRadius: BorderRadius.circular(
                              responsive.radius(6),
                            ),
                            border: Border.all(
                              color: ColorPalette.ghostBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: ColorPalette.primaryGreen,
                              fontSize: responsive.sp(11, min: 9.5, max: 13),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                    // Top-Right Bookmark Button
                    if (showBookmark)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: onBookmarkTap ?? () {},
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: ColorPalette.backgroundBlack.withValues(
                                alpha: 0.70,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorPalette.ghostBorder,
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.bookmark_border_rounded,
                              size: 16,
                              color: ColorPalette.textSecondary,
                            ),
                          ),
                        ),
                      ),

                    // Bottom Overlay Chips: Quality & Star Rating
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Quality Tag
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.surfaceContainerHighest
                                    .withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(
                                  responsive.radius(4),
                                ),
                              ),
                              child: Text(
                                item.bottomBadge ?? '4K HDR',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorPalette.primaryGreen,
                                  fontSize: responsive.sp(
                                    8.5,
                                    min: 7.5,
                                    max: 9.5,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Rating
                          if (item.rating != null && item.rating! > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFF84FFA8),
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  item.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: ColorPalette.fontWhite,
                                    fontSize: responsive.sp(
                                      10.0,
                                      min: 8.5,
                                      max: 11.5,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Perimeter border overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              responsive.radius(16),
                            ),
                            border: Border.all(
                              color: ColorPalette.ghostBorder,
                              width: 0.8,
                            ),
                          ),
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

            const SizedBox(height: 6),

            // Title
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(13, min: 11, max: 15),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 2),

            // Metadata Subtitle (Genre • Year)
            Text(
              _buildSubtitle(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(10.5, min: 9, max: 12),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(MediaItem item) {
    final parts = <String>[];
    if (item.genres.isNotEmpty) {
      parts.add(item.genres.first.toString());
    }
    if (item.releaseDate != null && item.releaseDate!.length >= 4) {
      parts.add(item.releaseDate!.substring(0, 4));
    } else if (item.durationLeft != null) {
      parts.add(item.durationLeft!);
    } else {
      parts.add('2024');
    }
    return parts.join(' • ');
  }
}
