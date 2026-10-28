import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/curated_taste_provider.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/theme/color_palette.dart';

class CuratedTasteGrid extends ConsumerWidget {
  final ValueChanged<MediaItem>? onMovieTap;

  const CuratedTasteGrid({super.key, this.onMovieTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;
    final curatedAsync = ref.watch(curatedTasteProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: ColorPalette.primaryGreen,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Curated For Your Taste',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: responsive.sp(18, min: 15, max: 21),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive Adaptive Poster Grid
          curatedAsync.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No curated movies found at the moment.',
                      style: TextStyle(color: ColorPalette.textMuted),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width >= 1200) {
                    crossAxisCount = 6;
                  } else if (width >= 900) {
                    crossAxisCount = 4;
                  } else if (width >= 600) {
                    crossAxisCount = 3;
                  }

                  final spacing = responsive.scale(10, min: 8, max: 14);

                  Widget grid = GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing + 8,
                      childAspectRatio: 2 / 3.75, // 2:3 poster + titles
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      final poster = movie['poster_path'] as String?;
                      final item = MediaItem(
                        id: movie['id'].toString(),
                        title: movie['title'].toString(),
                        imageUrl: poster != null && poster.isNotEmpty
                            ? imageBaseUrl + poster
                            : '',
                        genres: movie['genre'] is List ? movie['genre'] : [],
                        isAdult: movie['adult'] as bool? ?? false,
                      );
                      return DiscoverPosterCard(
                        item: item,
                        showRank: false,
                        onTap: () => onMovieTap?.call(item),
                      );
                    },
                  );

                  if (isTv) {
                    grid = DpadRegion(
                      leftEdge: DpadEdgeBehavior.leave,
                      child: grid,
                    );
                  }

                  return grid;
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
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
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Failed to load recommendations',
                      style: TextStyle(
                        color: ColorPalette.error,
                        fontSize: responsive.sp(12, min: 10, max: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
