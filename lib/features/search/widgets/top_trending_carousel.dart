import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/theme/color_palette.dart';

class TopTrendingCarousel extends ConsumerWidget {
  final VoidCallback? onSeeAllTap;
  final ValueChanged<MediaItem>? onMovieTap;

  const TopTrendingCarousel({super.key, this.onSeeAllTap, this.onMovieTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final trendingAsync = ref.watch(trendingNowProvider);
    final cardWidth = responsive.scale(136, min: 120, max: 160);
    // 2:3 aspect ratio height + text metadata buffer
    final containerHeight = (cardWidth * 1.5) + 52.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(16, min: 12, max: 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 20,
                    color: ColorPalette.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Top Trending Today',
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(18, min: 15, max: 21),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onSeeAllTap ?? () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: ColorPalette.primaryGreen,
                          fontSize: responsive.sp(12, min: 10.5, max: 13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: ColorPalette.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Carousel
        SizedBox(
          height: containerHeight,
          child: trendingAsync.when(
            data: (rawList) {
              if (rawList.isEmpty) {
                return const Center(
                  child: Text(
                    'No trending movies currently available.',
                    style: TextStyle(color: ColorPalette.textMuted),
                  ),
                );
              }

              final qualityBadges = ['4K HDR', 'IMAX 4K', 'REMUX', 'DOLBY'];

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.scale(16, min: 12, max: 20),
                ),
                itemCount: rawList.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: responsive.scale(10, min: 8, max: 14)),
                itemBuilder: (context, index) {
                  final movie = rawList[index];
                  final posterPath = movie['poster_path'] as String?;
                  final item = MediaItem(
                    id: movie['id'].toString(),
                    title: movie['title'] ?? 'Untitled',
                    imageUrl: posterPath != null && posterPath.isNotEmpty
                        ? '$imageBaseUrl$posterPath'
                        : '',
                    genres: movie['genre'] ?? [],
                    rating: (movie['vote_average'] as num?)?.toDouble(),
                    ratingCount: movie['vote_count']?.toString(),
                    bottomBadge: qualityBadges[index % qualityBadges.length],
                    releaseDate: movie['release_date'] as String?,
                  );

                  return DiscoverPosterCard(
                    item: item,
                    width: cardWidth,
                    showRank: false,
                    rank: index + 1,
                    onTap: () => onMovieTap?.call(item),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: ColorPalette.primaryGreen,
                ),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load trending movies',
                style: TextStyle(
                  color: ColorPalette.error,
                  fontSize: responsive.sp(12, min: 10, max: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
