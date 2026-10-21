import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

final animeTmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

/// Maps a raw TMDB TV show JSON payload to a clean [MediaItem] with mediaType='tv'.
MediaItem mapTvJsonToMediaItem(dynamic raw) {
  if (raw is MediaItem) return raw;
  final tv = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  final poster = tv['poster_path'] as String?;
  final backdrop = tv['backdrop_path'] as String?;

  return MediaItem(
    id: (tv['id'] ?? '').toString(),
    title: (tv['name'] ?? tv['title'] ?? 'Untitled Series').toString(),
    imageUrl: poster != null && poster.isNotEmpty
        ? '$imageBaseUrl$poster'
        : (backdrop != null && backdrop.isNotEmpty
            ? '$imageBaseUrl$backdrop'
            : ''),
    backdropUrl: backdrop != null && backdrop.isNotEmpty
        ? '$imageBaseUrl2$backdrop'
        : null,
    genres: tv['genre'] is List ? (tv['genre'] as List) : const [],
    rating: (tv['vote_average'] as num?)?.toDouble(),
    ratingCount: tv['vote_count']?.toString(),
    overview: tv['overview'] as String?,
    releaseDate: (tv['first_air_date'] ?? tv['release_date']) as String?,
    isAdult: tv['adult'] as bool? ?? false,
    mediaType: 'tv',
  );
}

/// Provider for Trending TV Shows today.
final trendingTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(animeTmdbServiceProvider);
  final rawList = await service.fetchMovies('trending/tv/day?language=en-US');
  return rawList.map(mapTvJsonToMediaItem).toList();
});

/// Provider for Anime & Animated TV Series (genre 16 = Animation).
final topAnimeSeriesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(animeTmdbServiceProvider);
  final rawList = await service.fetchMovies(
    'discover/tv?with_genres=16&sort_by=popularity.desc&language=en-US&page=1',
  );
  return rawList.map(mapTvJsonToMediaItem).toList();
});

/// Provider for Popular TV Series.
final popularTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(animeTmdbServiceProvider);
  final rawList = await service.fetchMovies('tv/popular?language=en-US&page=1');
  return rawList.map(mapTvJsonToMediaItem).toList();
});

/// Provider for Top Rated TV Shows.
final topRatedTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(animeTmdbServiceProvider);
  final rawList = await service.fetchMovies('tv/top_rated?language=en-US&page=1');
  return rawList.map(mapTvJsonToMediaItem).toList();
});

/// Provider for TV Shows Currently Airing / On The Air.
final onTheAirTvShowsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final service = ref.watch(animeTmdbServiceProvider);
  final rawList = await service.fetchMovies('tv/on_the_air?language=en-US&page=1');
  return rawList.map(mapTvJsonToMediaItem).toList();
});
