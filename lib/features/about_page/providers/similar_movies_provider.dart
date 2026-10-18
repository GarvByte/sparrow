import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// FutureProvider that fetches similar and recommended movies for a movie by ID.
final similarMoviesProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  movieId,
) async {
  final cleanId = movieId.trim();
  if (cleanId.isEmpty) return [];

  final service = ref.watch(tmdbServiceProvider);
  final moviesRaw = await service.fetchSimilarMovies(cleanId);

  return moviesRaw.map((movie) {
    final posterPath = movie['poster_path'] as String?;
    final backdropPath = movie['backdrop_path'] as String?;

    return MediaItem(
      id: movie['id'].toString(),
      title: (movie['title'] ?? movie['name'] ?? 'Untitled').toString(),
      rating: (movie['vote_average'] as num?)?.toDouble(),
      ratingCount: movie['vote_count']?.toString(),
      imageUrl: posterPath != null && posterPath.isNotEmpty
          ? '$imageBaseUrl$posterPath'
          : (backdropPath != null && backdropPath.isNotEmpty
                ? '$imageBaseUrl$backdropPath'
                : ''),
      genres: movie['genre'] is List ? (movie['genre'] as List) : [],
      isAdult: movie['adult'] as bool? ?? false,
      releaseDate: movie['release_date'] as String?,
      overview: movie['overview'] as String?,
      backdropUrl: backdropPath != null && backdropPath.isNotEmpty
          ? '$imageBaseUrl2$backdropPath'
          : null,
    );
  }).toList();
});
