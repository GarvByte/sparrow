import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/tv_show_details/data/tv_cast_member.dart';

/// FutureProvider that fetches the cast and crew members for a TV show by series ID.
final tvCreditsProvider =
    FutureProvider.family<List<TvCastMember>, String>((
  ref,
  seriesId,
) async {
  final cleanId = seriesId.trim();
  if (cleanId.isEmpty) return [];

  final service = ref.watch(tmdbServiceProvider);
  final creditsJson = await service.fetchTvShowCredits(cleanId);

  if (creditsJson == null || creditsJson['cast'] is! List) {
    return [];
  }

  final castList = creditsJson['cast'] as List;
  return castList
      .take(15)
      .map((item) => TvCastMember.fromJson(item as Map<String, dynamic>))
      .toList();
});
