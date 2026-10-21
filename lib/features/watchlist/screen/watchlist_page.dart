import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/home%20page/widgets/sparrow_header.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/features/watchlist/data/watchlist_item.dart';
import 'package:sparrow/features/watchlist/providers/watchlist_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

enum WatchlistFilter { all, movies, tvShows }

/// Complete Watchlist Screen displaying saved Movies and TV Shows.
///
/// Features:
/// - Single unified list combining movies and series.
/// - Offline persistence via Hive with instantaneous zero-latency local retrieval.
/// - Reactive synchronization with Riverpod state across all tabs and details screens.
/// - Fast category filtering (All, Movies, TV Shows).
/// - Preserves scroll position across tab navigation via [PageStorageKey].
/// - Responsive grid scaling across phone, tablet, and TV displays.
/// - Complete D-pad & keyboard navigation in TV layout.
class WatchlistPage extends ConsumerStatefulWidget {
  const WatchlistPage({super.key});

  @override
  ConsumerState<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends ConsumerState<WatchlistPage>
    with AutomaticKeepAliveClientMixin {
  WatchlistFilter _selectedFilter = WatchlistFilter.all;

  @override
  bool get wantKeepAlive => true;

  void _onMediaTap(WatchlistItem item) {
    final mediaItem = item.toMediaItem();
    if (item.isTvShow) {
      openTvShowDetails(context, mediaItem);
    } else {
      openMovieDetails(context, mediaItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;

    // Reactively watch persisted Watchlist items from Riverpod
    final allItems = ref.watch(watchlistProvider);

    // Filter items based on active category selection
    final filteredItems = allItems.where((item) {
      switch (_selectedFilter) {
        case WatchlistFilter.all:
          return true;
        case WatchlistFilter.movies:
          return !item.isTvShow;
        case WatchlistFilter.tvShows:
          return item.isTvShow;
      }
    }).toList();

    final movieCount = allItems.where((i) => !i.isTvShow).length;
    final tvCount = allItems.where((i) => i.isTvShow).length;

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
            // Scrollable Content
            allItems.isEmpty
                ? _buildEmptyState(context, topPadding + headerHeight)
                : _buildContent(
                    context,
                    filteredItems,
                    allItems.length,
                    movieCount,
                    tvCount,
                    topPadding + headerHeight,
                  ),

            // Fixed Top Header matching Home & Anime Hub
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SparrowHeader(subtitle: 'WATCHLIST'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WatchlistItem> items,
    int totalCount,
    int movieCount,
    int tvCount,
    double topOffset,
  ) {
    final responsive = context.responsive;
    final horizontalPadding = responsive.scale(16, min: 12, max: 24);

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

        final spacing = responsive.scale(12, min: 8, max: 16);

        return SingleChildScrollView(
          key: const PageStorageKey<String>('watchlist_page_scroll'),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: topOffset + 14,
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 110, // Buffer to clear floating bottom nav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Count Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saved Titles',
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(18, min: 16, max: 22),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.surfaceContainerHighest.withValues(
                        alpha: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorPalette.ghostBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$totalCount ${totalCount == 1 ? "title" : "titles"}',
                      style: TextStyle(
                        color: ColorPalette.primaryGreen,
                        fontSize: responsive.sp(11.5, min: 10, max: 13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Tabs (All / Movies / TV Shows)
              _buildFilterChips(totalCount, movieCount, tvCount),
              const SizedBox(height: 18),

              // Empty Filter State
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.filter_list_off_rounded,
                        size: 40,
                        color: ColorPalette.textMuted.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_selectedFilter == WatchlistFilter.movies ? "movies" : "TV shows"} in your watchlist',
                        style: const TextStyle(
                          color: ColorPalette.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Responsive Grid of Saved Posters wrapped in TV DpadRegion
                DpadRegion(
                  memoryKey: 'watchlist/grid',
                  leftEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing + 8,
                      childAspectRatio: 2 / 3.75,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FocusablePosterCard(
                        onSelected: () => _onMediaTap(item),
                        child: DiscoverPosterCard(
                          item: item.toMediaItem(),
                          showRank: false,
                          showBookmark: false,
                          onTap: () => _onMediaTap(item),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(int totalCount, int movieCount, int tvCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All ($totalCount)',
            filter: WatchlistFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Movies ($movieCount)',
            filter: WatchlistFilter.movies,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'TV Shows ($tvCount)',
            filter: WatchlistFilter.tvShows,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required WatchlistFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;
    final chipContent = InkWell(
      onTap: () {
        if (_selectedFilter != filter) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorPalette.primaryGreen
              : ColorPalette.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ColorPalette.primaryGreen
                : ColorPalette.ghostBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : ColorPalette.fontWhite,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );

    return TvFocusable(
      onSelect: () {
        if (_selectedFilter != filter) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: chipContent,
    );
  }

  Widget _buildEmptyState(BuildContext context, double topOffset) {
    final responsive = context.responsive;
    final iconSize = responsive.scale(48, min: 40, max: 56);

    return SingleChildScrollView(
      key: const PageStorageKey<String>('watchlist_page_empty_scroll'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: topOffset,
        bottom: 110,
        left: 24,
        right: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (responsive.height - topOffset - 110).clamp(300.0, 900.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorPalette.ghostBorder,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.bookmarks_outlined,
                  size: iconSize,
                  color: ColorPalette.primaryGreen.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Watchlist is Empty',
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(20, min: 18, max: 24),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: const Text(
                  'Explore trending blockbusters and hit TV series, then tap "My List" to save them here for offline access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TvFocusable(
                onSelect: () => context.go('/'),
                borderRadius: BorderRadius.circular(24),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: const Text(
                    'Explore Titles',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
