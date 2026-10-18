import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/category_results_provider.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/widgets/curated_taste_grid.dart';
import 'package:sparrow/features/search/widgets/explore_categories_grid.dart';
import 'package:sparrow/features/search/widgets/search_bar_deck.dart';
import 'package:sparrow/features/search/widgets/search_header.dart';
import 'package:sparrow/features/search/widgets/search_results_view.dart';
import 'package:sparrow/features/search/widgets/sparrow_masters_card.dart';
import 'package:sparrow/features/search/widgets/top_trending_carousel.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).setQuery(query);
        ref.read(searchResultsNotifier.notifier).search(query: query);
        ref.read(selectedCategoryProvider.notifier).clear();
      }
    });
  }

  void _onQuerySubmitted(String query) {
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).setQuery(query);
    ref.read(searchResultsNotifier.notifier).search(query: query);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(selectedCategoryProvider.notifier).clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;

    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final isSearching = query.trim().isNotEmpty || selectedCategory != null;

    // Reactively refresh search results when media type (Movies vs TV Shows) changes
    ref.listen<SearchMediaType>(searchMediaTypeProvider, (prev, next) {
      if (prev != null && prev != next) {
        final currentQuery = ref.read(searchQueryProvider);
        if (currentQuery.trim().isNotEmpty) {
          ref.read(searchResultsNotifier.notifier).search(
                query: currentQuery,
                mediaType: next,
              );
        }
      }
    });

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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: topPadding + headerHeight + 8,
                bottom: 110, // Clears the floating bottom nav dock
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & Filter Input Deck
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.scale(16, min: 12, max: 20),
                    ),
                    child: SearchBarDeck(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      onSubmitted: _onQuerySubmitted,
                      onClear: _clearSearch,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content Switcher: Search Results View OR Discover Home Deck
                  if (isSearching)
                    SearchResultsView(
                      onClear: _clearSearch,
                      onMovieTap: (item) {
                        if (item.isTvShow) {
                          openTvShowDetails(context, item);
                        } else {
                          openMovieDetails(context, item);
                        }
                      },
                    )
                  else ...[
                    // 1. Explore Categories
                    ExploreCategoriesGrid(
                      onCategoryTap: (CategoryItem category) {
                        // Tapping selects category and switches to results mode
                        ref
                            .read(selectedCategoryProvider.notifier)
                            .setCategory(category);
                        ref
                            .read(categoryResultsNotifier.notifier)
                            .fetchMoviesByGenre(category.tmdbGenreId);
                      },
                    ),

                    SizedBox(height: responsive.scale(22, min: 16, max: 28)),

                    // 2. Top Trending Today
                    TopTrendingCarousel(
                      onSeeAllTap: () {},
                      onMovieTap: (item) => openMovieDetails(context, item),
                    ),

                    SizedBox(height: responsive.scale(24, min: 18, max: 30)),

                    // 3. Sparrow Masters Featured Showcase
                    SparrowMastersCard(
                      onPlayTap: () {},
                      onTap: (item) => openMovieDetails(context, item),
                    ),

                    SizedBox(height: responsive.scale(24, min: 18, max: 30)),

                    // 4. Curated For Your Taste
                    CuratedTasteGrid(
                      onMovieTap: (item) => openMovieDetails(context, item),
                    ),
                  ],
                ],
              ),
            ),

            // Pinned Top Frosted Search Header
            const Positioned(top: 0, left: 0, right: 0, child: SearchHeader()),
          ],
        ),
      ),
    );
  }
}
