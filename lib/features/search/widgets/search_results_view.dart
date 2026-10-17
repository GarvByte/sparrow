import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/category_results_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
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
    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final resultsAsync = ref.watch(searchResultsNotifier);
    final categoryResults = ref.watch(categoryResultsNotifier);
    final results = selectedCategory != null ? categoryResults : resultsAsync;

    final title = query.isNotEmpty
        ? 'Results for "$query"'
        : (selectedCategory != null
              ? '${selectedCategory.title} Movies'
              : 'Search Results');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Active Query and Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
              InkWell(
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
            ],
          ),
          const SizedBox(height: 14),

          // Results Content
          results.when(
            data: (movies) {
              if (movies.isEmpty) {
                return _buildEmptyState(context, query);
              }
              debugPrint("searched reasults = $movies");
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

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing + 8,
                      childAspectRatio: 2 / 3.75,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      final item = MediaItem(
                        id: movie['id'].toString(),
                        title: movie['title'],
                        imageUrl: movie['poster_path'] == null
                            ? ""
                            : imageBaseUrl + movie['poster_path'],
                        genres: movie['genre'],
                        releaseDate: movie['release_date'],
                      );
                      return DiscoverPosterCard(
                        item: item,
                        showRank: false,
                        onTap: () => onMovieTap?.call(item),
                      );
                    },
                  );
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
                      'Searching movies...',
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
                    ElevatedButton.icon(
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query) {
    final responsive = context.responsive;

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
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: ColorPalette.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'No movies found for "$query"'
                  : 'No movies found in this category',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(15, min: 13, max: 17),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try checking for typos or searching for a different actor, director, or title.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(11.5, min: 10, max: 13),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
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
          ],
        ),
      ),
    );
  }
}
