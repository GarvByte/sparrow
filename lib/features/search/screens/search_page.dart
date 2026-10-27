import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/category_results_provider.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/widgets/curated_taste_grid.dart';
import 'package:sparrow/features/search/widgets/explore_categories_grid.dart';
import 'package:sparrow/features/search/widgets/random_genre_hero_banners.dart';
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
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final isTv = context.responsive.isTvOrDesktop;
    // On TV, keystrokes must NOT trigger search requests
    if (isTv) {
      return;
    }

    final clean = query.trim();
    if (clean.isEmpty) {
      ref.read(searchQueryProvider.notifier).clear();
      ref.read(selectedCategoryProvider.notifier).clear();
      ref.read(searchResultsNotifier.notifier).clear();
      return;
    }

    // Debounce by 1 second to avoid excessive network requests and UI churn during typing
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        final cleanQuery = query.trim();
        if (cleanQuery.isNotEmpty) {
          ref.read(searchQueryProvider.notifier).setQuery(cleanQuery);
          ref.read(searchResultsNotifier.notifier).search(query: cleanQuery);
          ref.read(selectedCategoryProvider.notifier).clear();
        } else {
          _clearSearch();
        }
      }
    });
  }

  void _onQuerySubmitted(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    if (clean.isEmpty) {
      if (!context.responsive.isTvOrDesktop) {
        _clearSearch();
      }
      return;
    }

    final isTv = context.responsive.isTvOrDesktop;
    ref.read(searchQueryProvider.notifier).setQuery(clean);
    ref.read(searchResultsNotifier.notifier).search(query: clean);
    ref.read(selectedCategoryProvider.notifier).clear();

    if (isTv) {
      context.push('/search/results', extra: clean);
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(selectedCategoryProvider.notifier).clear();
    ref.read(searchResultsNotifier.notifier).clear();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isTv = context.responsive.isTvOrDesktop;
    if (isTv) {
      // On TV, Back press on the search page is handled by standard navigation
      return KeyEventResult.ignored;
    }

    final query = ref.read(searchQueryProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);
    final isSearching = query.trim().isNotEmpty || selectedCategory != null;

    if (!isSearching) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.gameButtonB) {
      final primary = FocusManager.instance.primaryFocus;
      final isEditingText =
          primary?.context?.findAncestorStateOfType<EditableTextState>() != null;
      if (key == LogicalKeyboardKey.escape || !isEditingText) {
        _clearSearch();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _unfocusAndOpenMovie(dynamic item) {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    openMovieDetails(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;

    final isSearching = ref.watch(
          searchQueryProvider.select((q) => q.trim().isNotEmpty),
        ) ||
        ref.watch(selectedCategoryProvider.select((c) => c != null));

    final showInlineResults = !isTv && isSearching;

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

    return PopScope(
      canPop: isTv || !isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!isTv && isSearching) {
          _clearSearch();
        }
      },
      child: Focus(
        skipTraversal: true,
        onKeyEvent: _handleSearchKeyEvent,
        child: Scaffold(
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
                          focusNode: _searchFocusNode,
                          onChanged: _onQueryChanged,
                          onSubmitted: _onQuerySubmitted,
                          onClear: _clearSearch,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content Switcher: Search Results View OR Discover Home Deck
                      if (showInlineResults)
                        SearchResultsView(
                          onClear: _clearSearch,
                          onMovieTap: (item) {
                            _searchFocusNode.unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
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
                            if (isTv) {
                              _searchFocusNode.unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                              context.push('/search/results', extra: category);
                            }
                          },
                        ),

                        SizedBox(height: responsive.scale(22, min: 16, max: 28)),

                        // 2. Top Trending Today
                        TopTrendingCarousel(
                          onSeeAllTap: () {},
                          onMovieTap: _unfocusAndOpenMovie,
                        ),

                        SizedBox(height: responsive.scale(24, min: 18, max: 30)),

                        // 3. Sparrow Masters Featured Showcase
                        SparrowMastersCard(
                          onPlayTap: () {},
                          onTap: _unfocusAndOpenMovie,
                        ),

                        SizedBox(height: responsive.scale(24, min: 18, max: 30)),

                        // 4. Curated For Your Taste
                        CuratedTasteGrid(
                          onMovieTap: _unfocusAndOpenMovie,
                        ),

                        // 5. Vertically stacked hero banner cards for randomly selected genres
                        RandomGenreHeroBanners(
                          onMovieTap: _unfocusAndOpenMovie,
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
        ),
      ),
    );
  }
}
