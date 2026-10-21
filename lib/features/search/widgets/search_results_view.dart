import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/category_results_provider.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchResultsView extends ConsumerWidget {
  final VoidCallback onClear;
  final ValueChanged<MediaItem>? onMovieTap;

  const SearchResultsView({super.key, required this.onClear, this.onMovieTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;
    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final mediaType = ref.watch(searchMediaTypeProvider);
    final sortFilter = ref.watch(searchFilterProvider);
    final isTvShowMode = mediaType == SearchMediaType.tvShows;

    final resultsAsync = ref.watch(searchResultsNotifier);
    final categoryResults = ref.watch(categoryResultsNotifier);
    final results = selectedCategory != null ? categoryResults : resultsAsync;

    final title = query.isNotEmpty
        ? 'Results for "$query"'
        : (selectedCategory != null
              ? '${selectedCategory.title} Movies'
              : (isTvShowMode ? 'TV Show Results' : 'Movie Results'));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Active Query, Media Type indicator, and Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryGreen.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.4,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isTvShowMode ? 'TV' : 'MOVIE',
                        style: TextStyle(
                          color: ColorPalette.primaryGreen,
                          fontSize: responsive.sp(9.5, min: 8.5, max: 11),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TvFocusable(
                borderRadius: BorderRadius.circular(12),
                onSelect: onClear,
                child: InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: ColorPalette.primaryGreen,
                            fontSize: responsive.sp(12, min: 10.5, max: 13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: ColorPalette.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Results Content
          results.when(
            data: (rawList) {
              if (rawList.isEmpty) {
                return _buildEmptyState(context, query, isTvShowMode);
              }

              // Apply client-side sorting if needed
              final itemsList = List<dynamic>.from(rawList);
              switch (sortFilter) {
                case SearchSortFilter.popularity:
                  itemsList.sort((a, b) {
                    final popA = (a['popularity'] as num?)?.toDouble() ?? 0.0;
                    final popB = (b['popularity'] as num?)?.toDouble() ?? 0.0;
                    return popB.compareTo(popA);
                  });
                  break;
                case SearchSortFilter.topRated:
                  itemsList.sort((a, b) {
                    final rateA =
                        (a['vote_average'] as num?)?.toDouble() ?? 0.0;
                    final rateB =
                        (b['vote_average'] as num?)?.toDouble() ?? 0.0;
                    return rateB.compareTo(rateA);
                  });
                  break;
                case SearchSortFilter.releaseDate:
                  itemsList.sort((a, b) {
                    final dateA = (a['release_date'] ??
                            a['first_air_date'] ??
                            '')
                        .toString();
                    final dateB = (b['release_date'] ??
                            b['first_air_date'] ??
                            '')
                        .toString();
                    return dateB.compareTo(dateA);
                  });
                  break;
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
                      childAspectRatio: 2 / 3.75,
                    ),
                    itemCount: itemsList.length,
                    itemBuilder: (context, index) {
                      final raw = itemsList[index];
                      final itemIsTv = isTvShowMode ||
                          raw['media_type'] == 'tv' ||
                          (raw['name'] != null && raw['title'] == null);

                      final posterPath = raw['poster_path'] as String?;
                      final backdropPath = raw['backdrop_path'] as String?;

                      final item = MediaItem(
                        id: raw['id'].toString(),
                        title: (raw['name'] ?? raw['title'] ?? 'Untitled')
                            .toString(),
                        imageUrl: posterPath != null && posterPath.isNotEmpty
                            ? imageBaseUrl + posterPath
                            : (backdropPath != null && backdropPath.isNotEmpty
                                ? imageBaseUrl + backdropPath
                                : ''),
                        genres: raw['genre'] is List
                            ? (raw['genre'] as List)
                            : [],
                        isAdult: raw['adult'] as bool? ?? false,
                        releaseDate: (raw['first_air_date'] ??
                            raw['release_date']) as String?,
                        mediaType: itemIsTv ? 'tv' : 'movie',
                        overview: raw['overview'] as String?,
                        rating: (raw['vote_average'] as num?)?.toDouble(),
                        ratingCount: raw['vote_count']?.toString(),
                        backdropUrl: backdropPath != null &&
                                backdropPath.isNotEmpty
                            ? '$imageBaseUrl2$backdropPath'
                            : null,
                      );

                      return DiscoverPosterCard(
                        item: item,
                        showRank: false,
                        onTap: () {
                          if (onMovieTap != null) {
                            onMovieTap!(item);
                          } else if (item.isTvShow) {
                            openTvShowDetails(context, item);
                          } else {
                            openMovieDetails(context, item);
                          }
                        },
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
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTvShowMode ? 'Searching TV shows...' : 'Searching movies...',
                      style: TextStyle(
                        color: ColorPalette.textMuted,
                        fontSize: responsive.sp(12, min: 10, max: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: ColorPalette.error,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load search results',
                      style: TextStyle(
                        color: ColorPalette.fontWhite,
                        fontSize: responsive.sp(14, min: 12, max: 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please check your network connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorPalette.textMuted,
                        fontSize: responsive.sp(11.5, min: 10, max: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvFocusable(
                      borderRadius: BorderRadius.circular(20),
                      onSelect: () => ref.refresh(searchResultsNotifier),
                      child: ElevatedButton.icon(
                        onPressed: () => ref.refresh(searchResultsNotifier),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.surfaceContainerHigh,
                          foregroundColor: ColorPalette.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: ColorPalette.primaryGreen,
                              width: 0.8,
                            ),
                          ),
                        ),
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

  Widget _buildEmptyState(BuildContext context, String query, bool isTvShowMode) {
    final responsive = context.responsive;
    final entity = isTvShowMode ? 'TV shows' : 'movies';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 20.0),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
              ),
              child: Icon(
                isTvShowMode ? Icons.tv_off_rounded : Icons.search_off_rounded,
                size: 32,
                color: ColorPalette.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No $entity found for "$query"'
                  : 'No $entity found in this category',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(15, min: 13, max: 17),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try checking for typos or searching for a different title or creator.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(11.5, min: 10, max: 13),
              ),
            ),
            const SizedBox(height: 20),
            TvFocusable(
              borderRadius: BorderRadius.circular(20),
              onSelect: onClear,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorPalette.primaryGreen,
                  side: const BorderSide(color: ColorPalette.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Back to Discover'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
