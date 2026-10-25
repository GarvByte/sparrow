import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class CategoryResultsProvider extends AsyncNotifier<List<dynamic>> {
  @override
  List<dynamic> build() {
    return [];
  }

  final TmdbService _tmdbService = TmdbService();
  int? _currentExecutingGenreId;

  Future<List<dynamic>> fetchMoviesByGenre(int? genreId) async {
    if (genreId == null) {
      state = const AsyncValue.data([]);
      return [];
    }

    _currentExecutingGenreId = genreId;
    state = const AsyncValue.loading();
    try {
      final searchResults = await _tmdbService.fetchMovies(
        "discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&with_genres=$genreId",
      );
      if (_currentExecutingGenreId == genreId) {
        state = AsyncValue.data(searchResults);
      }
      return searchResults;
    } catch (e, st) {
      if (_currentExecutingGenreId == genreId) {
        state = AsyncValue.error(e, st);
      }
      return [];
    }
  }
}

final categoryResultsNotifier =
    AsyncNotifierProvider<CategoryResultsProvider, List<dynamic>>(
      () => CategoryResultsProvider(),
    );
