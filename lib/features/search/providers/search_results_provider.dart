import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class SearchResultsProvider extends AsyncNotifier<List<dynamic>> {
  @override
  List<dynamic> build() {
    return [];
  }

  final TmdbService _tmdbService = TmdbService();
  String? _currentExecutingQuery;
  SearchMediaType? _currentExecutingType;

  /// Search movies or TV shows based on the provided or active media type.
  Future<List<dynamic>> search({
    String? query,
    SearchMediaType? mediaType,
  }) async {
    final cleanQuery = (query ?? '').trim();
    if (cleanQuery.isEmpty) {
      _currentExecutingQuery = null;
      state = const AsyncValue.data([]);
      return [];
    }

    final activeType = mediaType ?? ref.read(searchMediaTypeProvider);
    _currentExecutingQuery = cleanQuery;
    _currentExecutingType = activeType;

    // Keep previously loaded items during transient search refetches if same query
    state = const AsyncValue.loading();

    try {
      List<dynamic> searchResults;
      if (activeType == SearchMediaType.tvShows) {
        searchResults = await _tmdbService.searchTvShows(cleanQuery);
      } else {
        searchResults = await _tmdbService.searchMovies(cleanQuery);
      }

      // Check that this response matches the most recent executing query
      if (_currentExecutingQuery == cleanQuery &&
          _currentExecutingType == activeType) {
        state = AsyncValue.data(searchResults);
      }
      return searchResults;
    } catch (e, st) {
      if (_currentExecutingQuery == cleanQuery &&
          _currentExecutingType == activeType) {
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
