import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class SearchResultsProvider extends AsyncNotifier<List> {
  @override
  List build() {
    return [];
  }

  final TmdbService _tmdbService = TmdbService();

  Future<List> fetchSearchedMovies(query) async {
    debugPrint("searching");
    state = AsyncValue.loading();
    final searchResults = await _tmdbService.fetchMovies(
      "search/movie?query=$query&include_adult=True&language=en-US&page=1",
    );
    state = AsyncValue.data(searchResults);
    return searchResults;
  }
}

final searchResultsNotifier =
    AsyncNotifierProvider<SearchResultsProvider, List>(
      () => SearchResultsProvider(),
    );
