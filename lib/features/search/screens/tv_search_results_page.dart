import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/category_results_provider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/scroll_aware_header.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Riverpod family provider fetching results strictly for the submitted TV query.
///
/// Reactively adapts when [searchMediaTypeProvider] changes without making redundant requests
/// on unrelated rebuilds.
final tvSearchQueryResultsProvider =
    FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final clean = query.trim();
  if (clean.isEmpty) return [];

  final tmdbService = ref.read(tmdbServiceProvider);
  final mediaType = ref.watch(searchMediaTypeProvider);

  if (mediaType == SearchMediaType.tvShows) {
    return tmdbService.searchTvShows(clean);
  } else {
    return tmdbService.searchMovies(clean);
  }
});

/// Dedicated TV Search Results Page.
///
/// Displayed exclusively on TV when a search query or category is explicitly submitted.
/// Features:
/// - Fully D-pad navigable with high-visibility focused states.
/// - Clear submitted query and media type badge.
/// - Resilient Loading, Error, Empty, and Populated results states.
/// - Smooth scroll-aware app bar that slides out on scroll down and reappears on scroll up.
/// - Standard back stack navigation (Details -> Results -> Search Input).
class TvSearchResultsPage extends ConsumerStatefulWidget {
  final String query;
  final CategoryItem? category;

  const TvSearchResultsPage({
    super.key,
    this.query = '',
    this.category,
  });

  @override
  ConsumerState<TvSearchResultsPage> createState() => _TvSearchResultsPageState();
}

class _TvSearchResultsPageState extends ConsumerState<TvSearchResultsPage> {
  late final ScrollAwareHeaderController _headerController;

  @override
  void initState() {
    super.initState();
    _headerController = ScrollAwareHeaderController();

    if (widget.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(categoryResultsNotifier.notifier)
            .fetchMoviesByGenre(widget.category!.tmdbGenreId);
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _onMediaSelected(MediaItem item) {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (item.isTvShow) {
      openTvShowDetails(context, item);
    } else {
      openMovieDetails(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;
    final mediaType = ref.watch(searchMediaTypeProvider);
    final isTvShowMode = mediaType == SearchMediaType.tvShows;

    final isCategoryMode = widget.category != null;
    final displayQuery = widget.query.trim();

    final AsyncValue<List<dynamic>> resultsAsync;
    if (isCategoryMode) {
      resultsAsync = ref.watch(categoryResultsNotifier);
    } else {
      resultsAsync = ref.watch(tvSearchQueryResultsProvider(displayQuery));
    }

    final pageTitle = isCategoryMode
        ? '${widget.category!.title} Movies'
        : (displayQuery.isNotEmpty
            ? 'Results for "$displayQuery"'
            : (isTvShowMode ? 'TV Show Results' : 'Movie Results'));

    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorPalette.backgroundBlack, ColorPalette.gradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable Results Content
            NotificationListener<ScrollNotification>(
              onNotification: _headerController.handleScrollNotification,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topPadding + headerHeight + 16,
                  bottom: 80,
                  left: responsive.scale(24, min: 16, max: 32),
                  right: responsive.scale(24, min: 16, max: 32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    resultsAsync.when(
                      data: (itemsList) {
                        if (itemsList.isEmpty) {
                          return _buildEmptyState(responsive, displayQuery);
                        }
                        return _buildResultsGrid(
                          context,
                          itemsList,
                          responsive,
                          isTvShowMode,
                        );
                      },
                      loading: () => _buildLoadingState(responsive, isTvShowMode),
                      error: (err, stack) => _buildErrorState(
                        responsive,
                        onRetry: () {
                          if (isCategoryMode) {
                            ref
                                .read(categoryResultsNotifier.notifier)
                                .fetchMoviesByGenre(widget.category!.tmdbGenreId);
                          } else {
                            ref.invalidate(
                              tvSearchQueryResultsProvider(displayQuery),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pinned Scroll-Aware Top App Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _headerController,
                builder: (context, _) {
                  return ScrollAwareHeader(
                    isVisible: _headerController.isVisible,
                    child: _buildHeaderBar(
                      context,
                      topPadding,
                      responsive,
                      pageTitle,
                      isTvShowMode,
                      isCategoryMode,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    double topPadding,
    SparrowResponsive responsive,
    String title,
    bool isTvShowMode,
    bool isCategoryMode,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 10,
        bottom: 12,
        left: responsive.scale(20, min: 16, max: 28),
        right: responsive.scale(20, min: 16, max: 28),
      ),
      decoration: BoxDecoration(
        color: ColorPalette.backgroundBlack.withValues(alpha: 0.90),
        border: const Border(
          bottom: BorderSide(color: ColorPalette.ghostBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Back Button to return to TV Search Input Page
          TvFocusable(
            onSelect: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: ColorPalette.fontWhite,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Query Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: responsive.sp(18, min: 15, max: 22),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'D-pad navigate • Press Select to view details',
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: responsive.sp(11.5, min: 10, max: 13),
                  ),
                ),
              ],
            ),
          ),

          // Media Type Badge / Selector (Movies vs TV)
          if (!isCategoryMode) ...[
            TvFocusable(
              onSelect: () {
                final next = isTvShowMode
                    ? SearchMediaType.movies
                    : SearchMediaType.tvShows;
                ref.read(searchMediaTypeProvider.notifier).setType(next);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ColorPalette.primaryGreen.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTvShowMode
                          ? Icons.live_tv_rounded
                          : Icons.movie_outlined,
                      size: 15,
                      color: ColorPalette.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTvShowMode ? 'TV SHOWS' : 'MOVIES',
                      style: TextStyle(
                        color: ColorPalette.primaryGreen,
                        fontSize: responsive.sp(11, min: 10, max: 13),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsGrid(
    BuildContext context,
    List<dynamic> itemsList,
    SparrowResponsive responsive,
    bool isTvShowMode,
  ) {
    final width = responsive.width;
    int crossAxisCount = 5;
    if (width >= 1600) {
      crossAxisCount = 7;
    } else if (width >= 1200) {
      crossAxisCount = 6;
    } else if (width >= 900) {
      crossAxisCount = 5;
    } else {
      crossAxisCount = 4;
    }

    final spacing = responsive.scale(12, min: 10, max: 18);

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
          title: (raw['name'] ?? raw['title'] ?? 'Untitled').toString(),
          imageUrl: posterPath != null && posterPath.isNotEmpty
              ? imageBaseUrl + posterPath
              : (backdropPath != null && backdropPath.isNotEmpty
                  ? imageBaseUrl + backdropPath
                  : ''),
          genres: raw['genre'] is List ? (raw['genre'] as List) : [],
          isAdult: raw['adult'] as bool? ?? false,
          releaseDate:
              (raw['first_air_date'] ?? raw['release_date']) as String?,
          mediaType: itemIsTv ? 'tv' : 'movie',
          overview: raw['overview'] as String?,
          rating: (raw['vote_average'] as num?)?.toDouble(),
          ratingCount: raw['vote_count']?.toString(),
          backdropUrl: backdropPath != null && backdropPath.isNotEmpty
              ? '$imageBaseUrl2$backdropPath'
              : null,
        );

        return DiscoverPosterCard(
          item: item,
          showRank: false,
          onTap: () => _onMediaSelected(item),
        );
      },
    );

    return DpadRegion(
      leftEdge: DpadEdgeBehavior.leave,
      child: grid,
    );
  }

  Widget _buildEmptyState(SparrowResponsive responsive, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: ColorPalette.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isNotEmpty
                  ? 'No results found for "$query"'
                  : 'No results available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(18, min: 16, max: 22),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try checking for typos or searching for a different title.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(13, min: 11, max: 15),
              ),
            ),
            const SizedBox(height: 24),
            TvFocusable(
              onSelect: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(
                  'Change Search Query',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryGreen,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(SparrowResponsive responsive, bool isTvShowMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: ColorPalette.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTvShowMode ? 'Searching TV shows...' : 'Searching movies...',
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(13, min: 11, max: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    SparrowResponsive responsive, {
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: ColorPalette.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'Unable to load search results',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(16, min: 14, max: 18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TvFocusable(
              onSelect: onRetry,
              borderRadius: BorderRadius.circular(18),
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Retry Search',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryGreen,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
