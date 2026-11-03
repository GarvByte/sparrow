import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';

class SearchResultsProvider extends AsyncNotifier<List<dynamic>> {
  @override
  List<dynamic> build() {
    return [];
  }

  int _requestId = 0;
  String? _currentExecutingQuery;
  SearchMediaType? _currentExecutingType;
  Future<List<dynamic>>? _inFlightFuture;

  /// Clear the active search results and invalidate any in-flight requests.
  void clear() {
    _requestId++;
    _currentExecutingQuery = null;
    _currentExecutingType = null;
    _inFlightFuture = null;
    state = const AsyncValue.data([]);
  }

  /// Retries the most recent search query with force refresh.
  Future<List<dynamic>> retry() async {
    final query = _currentExecutingQuery ?? ref.read(searchQueryProvider);
    final mediaType =
        _currentExecutingType ?? ref.read(searchMediaTypeProvider);
    return search(query: query, mediaType: mediaType, force: true);
  }

  /// Search movies or TV shows based on the provided or active media type.
  Future<List<dynamic>> search({
    String? query,
    SearchMediaType? mediaType,
    bool force = false,
  }) async {
    final cleanQuery = (query ?? '').trim();
    if (cleanQuery.isEmpty) {
      clear();
      return [];
    }

    final activeType = mediaType ?? ref.read(searchMediaTypeProvider);

    // If query and media type are unchanged and we already have valid data,
    // avoid redundant network calls unless force refresh is requested.
    if (!force &&
        cleanQuery == _currentExecutingQuery &&
        activeType == _currentExecutingType &&
        state.hasValue &&
        !state.hasError) {
      return state.value ?? [];
    }

    // Deduplicate identical in-flight query requests.
    if (!force &&
        cleanQuery == _currentExecutingQuery &&
        activeType == _currentExecutingType &&
        _inFlightFuture != null) {
      return _inFlightFuture!;
    }

    final reqId = ++_requestId;
    _currentExecutingQuery = cleanQuery;
    _currentExecutingType = activeType;

    state = const AsyncValue.loading();

    final future = _executeSearch(cleanQuery, activeType, reqId);
    _inFlightFuture = future;
    return future;
  }

  Future<List<dynamic>> _executeSearch(
    String cleanQuery,
    SearchMediaType? activeType,
    int reqId,
  ) async {
    try {
      final tmdbService = ref.read(tmdbServiceProvider);
      List<dynamic> searchResults;
      if (activeType == SearchMediaType.tvShows) {
        searchResults = await tmdbService.searchTvShows(cleanQuery);
      } else {
        searchResults = await tmdbService.searchMovies(cleanQuery);
      }

      // Safe request coordination: only the latest query may update visible results
      if (reqId == _requestId) {
        _inFlightFuture = null;
        state = AsyncValue.data(searchResults);
        return searchResults;
      }
      return [];
    } catch (e, st) {
      // Safe error handling: only report error if this request is still active
      if (reqId == _requestId) {
        _inFlightFuture = null;
        state = AsyncValue.error(e, st);
      }
      return [];
    }
  }

  /// Backward-compatible alias for existing movie-search invocations.
  Future<List<dynamic>> fetchSearchedMovies(dynamic query) async {
    return search(query: query?.toString());
  }
}

final searchResultsNotifier =
    AsyncNotifierProvider<SearchResultsProvider, List<dynamic>>(
      () => SearchResultsProvider(),
    );
