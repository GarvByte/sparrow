import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// FutureProvider that fetches similar and recommended TV shows for a series by ID.
final similarTvShowsProvider =
    FutureProvider.family<List<MediaItem>, String>((
  ref,
  seriesId,
) async {
  final cleanId = seriesId.trim();
  if (cleanId.isEmpty) return [];

  final service = ref.watch(tmdbServiceProvider);
  final showsRaw = await service.fetchSimilarTvShows(cleanId);

  return showsRaw.map((show) {
    final posterPath = show['poster_path'] as String?;
    final backdropPath = show['backdrop_path'] as String?;

    return MediaItem(
      id: show['id'].toString(),
      title: (show['name'] ?? show['title'] ?? 'Untitled').toString(),
      rating: (show['vote_average'] as num?)?.toDouble(),
      ratingCount: show['vote_count']?.toString(),
      imageUrl: posterPath != null && posterPath.isNotEmpty
          ? '$imageBaseUrl$posterPath'
          : (backdropPath != null && backdropPath.isNotEmpty
                ? '$imageBaseUrl$backdropPath'
                : ''),
      genres: show['genre'] is List ? (show['genre'] as List) : [],
      isAdult: show['adult'] as bool? ?? false,
      releaseDate: show['first_air_date'] as String?,
      overview: show['overview'] as String?,
      backdropUrl: backdropPath != null && backdropPath.isNotEmpty
          ? '$imageBaseUrl2$backdropPath'
          : null,
      mediaType: 'tv',
    );
  }).toList();
});
