import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class MasterMovieCover extends AsyncNotifier<Map> {
  @override
  Future<Map> build() async {
    return coverFetcher();
  }

  final TmdbService _tmdbService = TmdbService();

  Future<Map> coverFetcher() async {
    final movieData = await _tmdbService.fetchMovies(
      'trending/movie/day?language=en-US',
    );
    if (movieData.isEmpty) return {};

    // Filter or take a high-rated movie with a valid backdrop
    final chosen = movieData[0];
    return chosen;
  }
}

final masterCoverProvider = AsyncNotifierProvider<MasterMovieCover, Map>(
  () => MasterMovieCover(),
);
