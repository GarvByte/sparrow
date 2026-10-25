import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/tv_show_details/data/tv_show_detail_info.dart';
import 'package:sparrow/shared/media_item.dart';

/// FutureProvider that fetches comprehensive TV show details from TMDB,
/// merging network data with the initially passed [MediaItem] for instant rendering
/// and resilient offline/fallback states.
final tvShowDetailsProvider =
    FutureProvider.family<TvShowDetailInfo, MediaItem>((
  ref,
  initialItem,
) async {
  final service = ref.watch(tmdbServiceProvider);
  final cleanId = initialItem.id.trim();

  if (cleanId.isEmpty) {
    return TvShowDetailInfo.fromMediaItem(initialItem);
  }

  Map<String, dynamic>? creditsJson;
  try {
    creditsJson = await service.fetchTvShowCredits(cleanId);
  } catch (_) {
    // Non-fatal if credits fail; details are the primary payload
  }

  final detailsJson = await service.fetchTvShowDetails(cleanId);
  if (detailsJson != null) {
    return TvShowDetailInfo.fromTmdbJson(
      json: detailsJson,
      creditsJson: creditsJson,
      fallbackItem: initialItem,
    );
  }

  return TvShowDetailInfo.fromMediaItem(initialItem);
});
