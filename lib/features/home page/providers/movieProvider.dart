import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

class Movieprovider extends AsyncNotifier<List<dynamic>> {
  final TmdbService _tmdbService = TmdbService();

  @override
  Future<List<dynamic>> build() async {
    return getNowShowing();
  }

  Future<List<dynamic>> getNowShowing() {
    return _tmdbService.fetchMovies('movie/now_playing?language=en-US&page=1');
  }

  Future<List<dynamic>> getTrendingNow() {
    return _tmdbService.fetchMovies('trending/movie/day?language=en-US');
  }

  Future<List<dynamic>> getPopular() {
    return _tmdbService.fetchMovies('movie/popular?language=en-US&page=1');
  }

  Future<List<dynamic>> topRated() {
    return _tmdbService.fetchMovies('movie/top_rated?language=en-US&page=1');
  }

  Future<List<dynamic>> trendingShows() {
    return _tmdbService.fetchMovies('trending/movie/day?language=en-US');
  }
}

final movieProviderNotifier =
    AsyncNotifierProvider<Movieprovider, List<dynamic>>(() => Movieprovider());

final trendingNowProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).getTrendingNow();
});

final trendingShowProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).trendingShows();
});

final popularMoviesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).getPopular();
});

final topRatedMoviesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).topRated();
});
