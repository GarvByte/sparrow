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

  Map<String, dynamic>? creditsJson;
  try {
    creditsJson = await service.fetchMovieCredits(cleanId);
  } catch (_) {
    // Non-fatal if credits fail; details are the primary payload
  }

  final detailsJson = await service.fetchMovieDetails(cleanId);
  if (detailsJson != null) {
    return MovieDetailInfo.fromTmdbJson(
      json: detailsJson,
      creditsJson: creditsJson,
      fallbackItem: initialItem,
    );
  }

  return MovieDetailInfo.fromMediaItem(initialItem);
});
