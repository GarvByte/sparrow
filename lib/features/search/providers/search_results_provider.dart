import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class SearchResultsProvider extends AsyncNotifier<List<dynamic>> {
  @override
  List<dynamic> build() {
    return [];
  }

  final TmdbService _tmdbService = TmdbService();

  /// Search movies or TV shows based on the provided or active media type.
  Future<List<dynamic>> search({
    String? query,
    SearchMediaType? mediaType,
  }) async {
    final cleanQuery = (query ?? '').trim();
    if (cleanQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return [];
    }

    final activeType = mediaType ?? ref.read(searchMediaTypeProvider);
    state = const AsyncValue.loading();

    try {
      List<dynamic> searchResults;
      if (activeType == SearchMediaType.tvShows) {
        //debugPrintt('Searching TMDB TV shows for "$cleanQuery"');
        searchResults = await _tmdbService.searchTvShows(cleanQuery);
      } else {
        //debugPrintt('Searching TMDB movies for "$cleanQuery"');
        searchResults = await _tmdbService.searchMovies(cleanQuery);
      }
      state = AsyncValue.data(searchResults);
      return searchResults;
    } catch (e, st) {
      //debugPrintt('TMDB search error in SearchResultsProvider: $e');
      state = AsyncValue.error(e, st);
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
