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

  Future<List<dynamic>> getTrendingNow2() {
    return _tmdbService.fetchMovies('trending/movie/day?language=en-US&page=2');
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

Future<List<dynamic>> discoverHindiMovies() {
    return _tmdbService.fetchMovies('discover/movie?with_original_language=hi');
  }

  Future<List<dynamic>> discoverIndianMovies() {
    return _tmdbService.fetchMovies('discover/movie?with_origin_country=IN');
  }

  
}

final movieProviderNotifier =
    AsyncNotifierProvider<Movieprovider, List<dynamic>>(() => Movieprovider());

final trendingNowProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).getTrendingNow();
});

final trendingNow2Provider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).getTrendingNow2();
});


final discoverHindiMoviesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).discoverHindiMovies();
});

final discoverIndianMoviesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(movieProviderNotifier.notifier).discoverIndianMovies();
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
