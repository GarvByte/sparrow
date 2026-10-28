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
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/shared/scroll_aware_header.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final FocusScopeNode _searchScopeNode;
  late final ScrollAwareHeaderController _headerController;
  Timer? _debounceTimer;
  bool _isNavigatingToTvResults = false;
  bool _isSubrouteActive = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);
    _searchFocusNode = FocusNode(
      debugLabel: 'SearchFieldFocusNode',
      skipTraversal: true,
    );
    _searchScopeNode = FocusScopeNode(debugLabel: 'SearchPageScope');
    _headerController = ScrollAwareHeaderController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTv = context.responsive.isTvOrDesktop;
    _searchFocusNode.skipTraversal = !isTv;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _headerController.dispose();
    _searchScopeNode.dispose();
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
    if (!context.responsive.isTvOrDesktop) {
      _searchScopeNode.requestScopeFocus();
    }
    _searchScopeNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    _searchFocusNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );

    final isTv = context.responsive.isTvOrDesktop;

    if (clean.isEmpty) {
      if (!isTv) {
        _clearSearch();
      }
      return;
    }

    // On TV: push dedicated search results page without triggering requests for keystrokes
    if (isTv) {
      if (_isNavigatingToTvResults) return;
      _isNavigatingToTvResults = true;
      context.push('/search/results', extra: clean).then((_) {
        if (mounted) {
          _isNavigatingToTvResults = false;
          _searchScopeNode.unfocus();
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
      return;
    }

    // Mobile: trigger inline live search
    ref.read(searchQueryProvider.notifier).setQuery(clean);
    ref.read(searchResultsNotifier.notifier).search(query: clean);
    ref.read(selectedCategoryProvider.notifier).clear();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(selectedCategoryProvider.notifier).clear();
    ref.read(searchResultsNotifier.notifier).clear();
    if (mounted && !context.responsive.isTvOrDesktop) {
      _searchScopeNode.requestScopeFocus();
    }
    _searchScopeNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    _searchFocusNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
  }

  bool get _isTopRoute {
    if (_isSubrouteActive) return false;
    if (appRouter.canPop()) return false;
    final modalRoute = ModalRoute.of(context);
    return modalRoute?.isCurrent ?? true;
  }

  void _navigateToDetails(dynamic item) {
    if (!context.responsive.isTvOrDesktop) {
      _searchScopeNode.requestScopeFocus();
    }
    _searchScopeNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    _searchFocusNode.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );

    setState(() {
      _isSubrouteActive = true;
    });

    final isTv = item is MediaItem
        ? item.isTvShow
        : (item is Map &&
            (item['media_type'] == 'tv' || item['is_tv'] == true));

    final Future<dynamic> future = isTv
        ? openTvShowDetails(context, item)
        : openMovieDetails(context, item);

    future.then((_) {
      if (mounted) {
        if (!context.responsive.isTvOrDesktop) {
          _searchScopeNode.requestScopeFocus();
        }
        _searchScopeNode.unfocus(
          disposition: UnfocusDisposition.previouslyFocusedChild,
        );
        _searchFocusNode.unfocus(
          disposition: UnfocusDisposition.previouslyFocusedChild,
        );
        FocusManager.instance.primaryFocus?.unfocus(
          disposition: UnfocusDisposition.previouslyFocusedChild,
        );
        setState(() {
          _isSubrouteActive = false;
        });
      }
    });
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (!_isTopRoute) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    final isBackKey =
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.gameButtonB;

    if (!isBackKey) {
      return KeyEventResult.ignored;
    }

    final isTv = context.responsive.isTvOrDesktop;

    // Preserve normal TV navigation when the search field
    // is no longer focused.
    if (isTv) {
      return KeyEventResult.ignored;
    }

    // Escape always clears active search immediately (e.g. desktop/web/tests)
    if (key == LogicalKeyboardKey.escape) {
      _clearSearch();
      return KeyEventResult.handled;
    }

    // Priority 1: Dismiss the focused search input on back key.
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      return KeyEventResult.handled;
    }

    // Priority 2: Clear active mobile search.
    final query = ref.read(searchQueryProvider);
    final selectedCategory = ref.read(selectedCategoryProvider);

    final isSearching = query.trim().isNotEmpty || selectedCategory != null;

    if (isSearching) {
      _clearSearch();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _unfocusAndOpenMovie(dynamic item) {
    _navigateToDetails(item);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;

    final isSearching =
        ref.watch(searchQueryProvider.select((q) => q.trim().isNotEmpty)) ||
        ref.watch(selectedCategoryProvider.select((c) => c != null));

    final showInlineResults = !isTv && isSearching;

    // Reactively refresh search results when media type (Movies vs TV Shows) changes
    ref.listen<SearchMediaType>(searchMediaTypeProvider, (prev, next) {
      if (prev != null && prev != next) {
        final currentQuery = ref.read(searchQueryProvider);
        if (currentQuery.trim().isNotEmpty) {
          ref
              .read(searchResultsNotifier.notifier)
              .search(query: currentQuery, mediaType: next);
        }
      }
    });

    return PopScope(
      canPop: !_isTopRoute || isTv || (!_searchFocusNode.hasFocus && !isSearching),

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_isTopRoute) return;

        // Priority 1: Dismiss the focused search field.
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }

        // Priority 2: Clear active inline search on mobile.
        if (!isTv && isSearching) {
          _clearSearch();
        }
      },
      child: FocusScope(
        node: _searchScopeNode,
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
                  colors: [
                    ColorPalette.backgroundBlack,
                    ColorPalette.gradientEnd,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Scrollable Content
                  NotificationListener<ScrollNotification>(
                    onNotification: _headerController.handleScrollNotification,
                    child: SingleChildScrollView(
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
                              horizontal: responsive.scale(
                                16,
                                min: 12,
                                max: 20,
                              ),
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
                              onMovieTap: _navigateToDetails,
                            )
                          else ...[
                            // 1. Explore Categories
                            ExploreCategoriesGrid(
                              onCategoryTap: (CategoryItem category) {
                                if (isTv) {
                                  if (_isNavigatingToTvResults) return;
                                  _isNavigatingToTvResults = true;
                                  _searchScopeNode.unfocus();
                                  _searchFocusNode.unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  context
                                      .push('/search/results', extra: category)
                                      .then((_) {
                                        if (mounted) {
                                          _isNavigatingToTvResults = false;
                                          _searchScopeNode.unfocus();
                                          _searchFocusNode.unfocus();
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        }
                                      });
                                  return;
                                }

                                // Mobile: Tapping selects category and switches to results mode
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .setCategory(category);
                                ref
                                    .read(categoryResultsNotifier.notifier)
                                    .fetchMoviesByGenre(category.tmdbGenreId);
                              },
                            ),

                            SizedBox(
                              height: responsive.scale(22, min: 16, max: 28),
                            ),

                            // 2. Top Trending Today
                            TopTrendingCarousel(
                              onSeeAllTap: () {},
                              onMovieTap: _unfocusAndOpenMovie,
                            ),

                            SizedBox(
                              height: responsive.scale(24, min: 18, max: 30),
                            ),

                            // 3. Sparrow Masters Featured Showcase
                            SparrowMastersCard(
                              onPlayTap: () {},
                              onTap: _unfocusAndOpenMovie,
                            ),

                            SizedBox(
                              height: responsive.scale(24, min: 18, max: 30),
                            ),

                            // 4. Curated For Your Taste
                            CuratedTasteGrid(onMovieTap: _unfocusAndOpenMovie),

                            // 5. Vertically stacked hero banner cards for randomly selected genres
                            RandomGenreHeroBanners(
                              onMovieTap: _unfocusAndOpenMovie,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Pinned Top Frosted Search Header with Scroll-Aware Hide/Show
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _headerController,
                      builder: (context, _) {
                        return ScrollAwareHeader(
                          isVisible: _headerController.isVisible,
                          child: const SearchHeader(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
