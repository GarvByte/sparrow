import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/data/movie_detail_info.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());

/// FutureProvider that fetches comprehensive movie details, merging network data
/// with the initially passed [MediaItem] for instant rendering and resilient fallback.
final movieDetailsProvider = FutureProvider.family<MovieDetailInfo, MediaItem>((
  ref,
  initialItem,
) async {
  final service = ref.watch(tmdbServiceProvider);
  final cleanId = initialItem.id.trim();

  if (cleanId.isEmpty) {
    return MovieDetailInfo.fromMediaItem(initialItem);
  }

  // Concurrently initiate primary movie details and secondary credits
  final detailsFuture = service.fetchMovieDetails(cleanId);
  final creditsFuture = service.fetchMovieCredits(cleanId).catchError((_) => null);

  final detailsJson = await detailsFuture;
  final creditsJson = await creditsFuture;

  if (detailsJson != null) {
    return MovieDetailInfo.fromTmdbJson(
      json: detailsJson,
      creditsJson: creditsJson,
      fallbackItem: initialItem,
    );
  }

  return MovieDetailInfo.fromMediaItem(initialItem);
});
