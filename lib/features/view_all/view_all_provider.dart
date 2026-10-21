import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/anime%20hub/providers/anime_tv_providers.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/media_item.dart';

class ViewAllState {
  final List<MediaItem> items;
  final int lastLoadedPage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final Set<int> loadedPages;

  const ViewAllState({
    this.items = const [],
    this.lastLoadedPage = 0,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.loadedPages = const {},
  });

  ViewAllState copyWith({
    List<MediaItem>? items,
    int? lastLoadedPage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    Set<int>? loadedPages,
  }) {
    return ViewAllState(
      items: items ?? this.items,
      lastLoadedPage: lastLoadedPage ?? this.lastLoadedPage,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      loadedPages: loadedPages ?? this.loadedPages,
    );
  }
}

class ViewAllNotifier extends Notifier<ViewAllState> {
  final ViewAllArgs arg;

  ViewAllNotifier(this.arg);

  @override
  ViewAllState build() {
    Future.microtask(() => init());
    return const ViewAllState();
  }

  /// Initial load: fetches page 1 and immediately page 2.
  Future<void> init() async {
    if (state.lastLoadedPage > 0 || state.isLoadingInitial) return;

    state = state.copyWith(isLoadingInitial: true, errorMessage: null);

    try {
      // 1. Fetch Page 1
      final page1Raw = await _fetchRawPage(1);
      final page1Items = _mapResults(page1Raw);

      if (page1Items.isEmpty) {
        state = state.copyWith(
          items: [],
          lastLoadedPage: 1,
          isLoadingInitial: false,
          hasMore: false,
          loadedPages: {1},
        );
        return;
      }

      final updatedLoadedPages = <int>{1};
      var accumulated = _deduplicate(page1Items);

      state = state.copyWith(
        items: accumulated,
        lastLoadedPage: 1,
        isLoadingInitial: false,
        loadedPages: updatedLoadedPages,
        hasMore: page1Items.length >= 10,
      );

      // 2. Immediately fetch Page 2 if more results are available
      if (state.hasMore) {
        try {
          final page2Raw = await _fetchRawPage(2);
          final page2Items = _mapResults(page2Raw);

          if (page2Items.isNotEmpty) {
            accumulated = _deduplicate([...accumulated, ...page2Items]);
            updatedLoadedPages.add(2);
            state = state.copyWith(
              items: accumulated,
              lastLoadedPage: 2,
              loadedPages: updatedLoadedPages,
              hasMore: page2Items.length >= 10,
            );
          } else {
            state = state.copyWith(hasMore: false);
          }
        } catch (_) {
          // If page 2 fetch fails, page 1 is preserved and user can load more / retry
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: 'Unable to load content: ${e.toString()}',
      );
    }
  }

  /// Fetch subsequent pages (Page 3, 4, etc.) via the bottom arrow.
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoadingInitial || !state.hasMore) return;

    final nextPage = state.lastLoadedPage + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final rawResults = await _fetchRawPage(nextPage);
      final newItems = _mapResults(rawResults);

      if (newItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final updatedPages = Set<int>.from(state.loadedPages)..add(nextPage);
      final accumulated = _deduplicate([...state.items, ...newItems]);

      state = state.copyWith(
        items: accumulated,
        lastLoadedPage: nextPage,
        isLoadingMore: false,
        hasMore: newItems.length >= 10,
        loadedPages: updatedPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Failed to load page $nextPage. Tap arrow to retry.',
      );
    }
  }

  Future<void> retry() async {
    if (state.lastLoadedPage == 0) {
      await init();
    } else {
      await loadMore();
    }
  }

  Future<List<dynamic>> _fetchRawPage(int page) async {
    final service = ref.read(tmdbServiceProvider);
    switch (arg.categoryType) {
      case 'genre':
        final genreId = arg.genreId ?? 28;
        if (arg.isTv) {
          return service.fetchTvByGenre(genreId, page: page);
        } else {
          return service.fetchByGenre(genreId, page: page);
        }

      case 'trending':
        if (arg.isTv) {
          return service.fetchMovies('trending/tv/day?language=en-US&page=$page');
        } else {
          return service.fetchMovies(
            'trending/movie/day?language=en-US&page=$page',
          );
        }

      case 'popular':
        if (arg.isTv) {
          return service.fetchMovies('tv/popular?language=en-US&page=$page');
        } else {
          return service.fetchMovies('movie/popular?language=en-US&page=$page');
        }

      case 'top_rated':
        if (arg.isTv) {
          return service.fetchMovies('tv/top_rated?language=en-US&page=$page');
        } else {
          return service.fetchMovies(
            'movie/top_rated?language=en-US&page=$page',
          );
        }

      case 'on_the_air':
        return service.fetchMovies('tv/on_the_air?language=en-US&page=$page');

      default:
        if (arg.isTv) {
          return service.fetchMovies('tv/popular?language=en-US&page=$page');
        } else {
          return service.fetchMovies('movie/popular?language=en-US&page=$page');
        }
    }
  }

  List<MediaItem> _mapResults(List<dynamic> raw) {
    if (arg.isTv) {
      return raw.map(mapTvJsonToMediaItem).toList();
    } else {
      return raw.map(mapMovieJsonToMediaItem).toList();
    }
  }

  List<MediaItem> _deduplicate(List<MediaItem> items) {
    final seen = <String>{};
    final result = <MediaItem>[];
    for (final item in items) {
      if (item.id.isNotEmpty && seen.add(item.id)) {
        result.add(item);
      }
    }
    return result;
  }
}

/// Provider family caching ViewAllState per unique ViewAllArgs.
/// Not auto-disposed so loaded results remain cached when switching tabs.
final viewAllProvider =
    NotifierProvider.family<ViewAllNotifier, ViewAllState, ViewAllArgs>(
  (arg) => ViewAllNotifier(arg),
);
