import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class CategoryResultsProvider extends AsyncNotifier<List> {
  @override
  List build() {
    return [];
  }

  final TmdbService _tmdbService = TmdbService();

  Future<List> fetchMoviesByGenre(genreId) async {
    //debugPrintt("searching");
    state = AsyncValue.loading();
    final searchResults = await _tmdbService.fetchMovies(
      "discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&with_genres=$genreId",
    );
    state = AsyncValue.data(searchResults);
    return searchResults;
  }
}

final categoryResultsNotifier =
    AsyncNotifierProvider<CategoryResultsProvider, List>(
      () => CategoryResultsProvider(),
    );
