import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/anime%20hub/providers/anime_tv_providers.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

class TmdbGenre {
  final int id;
  final String name;

  const TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TmdbGenre && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<TmdbGenre> fallbackMovieGenres = [
  TmdbGenre(id: 28, name: 'Action'),
  TmdbGenre(id: 35, name: 'Comedy'),
  TmdbGenre(id: 53, name: 'Thriller'),
  TmdbGenre(id: 878, name: 'Science Fiction'),
  TmdbGenre(id: 27, name: 'Horror'),
  TmdbGenre(id: 12, name: 'Adventure'),
  TmdbGenre(id: 18, name: 'Drama'),
  TmdbGenre(id: 14, name: 'Fantasy'),
  TmdbGenre(id: 16, name: 'Animation'),
  TmdbGenre(id: 80, name: 'Crime'),
  TmdbGenre(id: 9648, name: 'Mystery'),
  TmdbGenre(id: 10749, name: 'Romance'),
];

const List<TmdbGenre> fallbackTvGenres = [
  TmdbGenre(id: 10759, name: 'Action & Adventure'),
  TmdbGenre(id: 18, name: 'Drama'),
  TmdbGenre(id: 35, name: 'Comedy'),
  TmdbGenre(id: 80, name: 'Crime'),
  TmdbGenre(id: 9648, name: 'Mystery'),
  TmdbGenre(id: 10765, name: 'Sci-Fi & Fantasy'),
  TmdbGenre(id: 16, name: 'Animation'),
  TmdbGenre(id: 10751, name: 'Family'),
];

MediaItem mapMovieJsonToMediaItem(dynamic raw) {
  if (raw is MediaItem) return raw;
  final movie =
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  final poster = movie['poster_path'] as String?;
  final backdrop = movie['backdrop_path'] as String?;

  return MediaItem(
    id: (movie['id'] ?? '').toString(),
    title: (movie['title'] ?? movie['name'] ?? 'Untitled Movie').toString(),
    imageUrl: poster != null && poster.isNotEmpty
        ? '$imageBaseUrl$poster'
        : (backdrop != null && backdrop.isNotEmpty
            ? '$imageBaseUrl$backdrop'
            : ''),
    backdropUrl: backdrop != null && backdrop.isNotEmpty
        ? '$imageBaseUrl2$backdrop'
        : null,
    genres: movie['genre'] is List ? (movie['genre'] as List) : const [],
    rating: (movie['vote_average'] as num?)?.toDouble(),
    ratingCount: movie['vote_count']?.toString(),
    overview: movie['overview'] as String?,
    releaseDate: (movie['release_date'] ?? movie['first_air_date']) as String?,
    isAdult: movie['adult'] as bool? ?? false,
    mediaType: 'movie',
  );
}

/// Provider that fetches official TMDB movie genres with fallback.
final movieGenresProvider = FutureProvider<List<TmdbGenre>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final rawList = await service.fetchMovieGenres();
  if (rawList.isEmpty) return fallbackMovieGenres;
  return rawList.map(TmdbGenre.fromJson).toList();
});

/// Provider that fetches official TMDB TV genres with fallback.
final tvGenresProvider = FutureProvider<List<TmdbGenre>>((ref) async {
  final service = ref.watch(tmdbServiceProvider);
  final rawList = await service.fetchTvGenres();
  if (rawList.isEmpty) return fallbackTvGenres;
  return rawList.map(TmdbGenre.fromJson).toList();
});

/// Movies for a specific genre on the Home page.
final movieByGenreProvider =
    FutureProvider.family<List<MediaItem>, int>((ref, genreId) async {
  final service = ref.watch(tmdbServiceProvider);
  final rawList = await service.fetchByGenre(genreId, page: 1);
  return rawList.map(mapMovieJsonToMediaItem).toList();
});

/// TV Shows for a specific genre on the TV Shows / Anime Hub page.
final tvByGenreProvider =
    FutureProvider.family<List<MediaItem>, int>((ref, genreId) async {
  final service = ref.watch(tmdbServiceProvider);
  final rawList = await service.fetchTvByGenre(genreId, page: 1);
  return rawList.map(mapTvJsonToMediaItem).toList();
});
