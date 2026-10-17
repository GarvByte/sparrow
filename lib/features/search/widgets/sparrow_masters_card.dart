import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/features/search/providers/master_movie_cover.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/theme/color_palette.dart';

class SparrowMastersCard extends ConsumerWidget {
  final VoidCallback? onPlayTap;
  final ValueChanged<MediaItem>? onTap;

  const SparrowMastersCard({super.key, this.onPlayTap, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final masterCover = ref.watch(masterCoverProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
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
                  const SizedBox(width: 8),
                  Text(
                    'Sparrow Masters',
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(18, min: 15, max: 21),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Master Featured Showcase Card
          masterCover.when(
            data: (movie) {
              if (movie.isEmpty) return const SizedBox.shrink();
              return _MasterShowcase(
                movie: MediaItem(
                  id: movie['id'].toString(),
                  title: movie['title'],
                  imageUrl: movie['backdrop_path'],
                  genres: movie['genre'],
                  overview: movie['overview'],
                ),
                onPlayTap: onPlayTap,
                // onTap: () => onTap?.call(movie),
              );
            },
            loading: () => Container(
              height: 240,
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainer,
                borderRadius: BorderRadius.circular(responsive.radius(16)),
              ),
              child: const Center(
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
            error: (err, stack) => Text("error $err"),
          ),
        ],
      ),
    );
  }
}

class _MasterShowcase extends StatelessWidget {
  final MediaItem movie;
  final VoidCallback? onPlayTap;
  final VoidCallback? onTap;

  const _MasterShowcase({required this.movie, this.onPlayTap, this.onTap});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final bannerHeight = responsive.scale(190, min: 160, max: 240);

    final imageUrl = responsive.isTvOrDesktop
        ? imageBaseUrl2 + movie.imageUrl
        : imageBaseUrl + movie.imageUrl;
    final title = movie.title;
    final overview = movie.overview ?? 'No overview';
    final rating = movie.rating ?? 9.4;

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer,
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Play Button & Telemetry Chips
          Stack(
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const ErrorImagePlaceholder(),
                ),
              ),

              // Gradient Scrim to Surface Container
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        ColorPalette.surfaceContainer.withValues(alpha: 0.3),
                        ColorPalette.surfaceContainer,
                      ],
                    ),
                  ),
                ),
              ),

              // Top-Left Chips: ORIGINAL & 4K UHD
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ColorPalette.backgroundBlack.withValues(
                          alpha: 0.82,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ColorPalette.ghostBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: ColorPalette.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Trending #1',
                            style: TextStyle(
                              color: ColorPalette.primaryGreen,
                              fontSize: responsive.sp(9.5, min: 8.5, max: 11),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom-Right Glowing Circular Play Button
              Positioned(
                bottom: 12,
                right: 12,
                child: InkWell(
                  onTap: onPlayTap ?? () {},
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.45,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Metadata & Narrative Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(17, min: 14.5, max: 19),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFF84FFA8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: ColorPalette.fontWhite,
                            fontSize: responsive.sp(13.5, min: 12, max: 15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Narrative Synopsis (2 lines clamped)
                Text(
                  overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: responsive.sp(12, min: 10.5, max: 13.5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Row: Quality Chips & Bookmark Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: movie.genres
                          .map<Widget>(
                            (genre) => _MetaChip(text: genre.toString()),
                          )
                          .toList(),
                    ),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ColorPalette.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorPalette.ghostBorder,
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark_add_outlined,
                          size: 18,
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;

  const _MetaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      margin: EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(responsive.radius(4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ColorPalette.textSecondary,
          fontSize: responsive.sp(10, min: 9, max: 11),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
