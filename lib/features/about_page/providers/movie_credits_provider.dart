import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/data/cast_member.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';

/// FutureProvider that fetches the cast and crew members for a movie by ID.
final movieCreditsProvider = FutureProvider.family<List<CastMember>, String>((
  ref,
  movieId,
) async {
  final cleanId = movieId.trim();
  if (cleanId.isEmpty) return [];

  final service = ref.watch(tmdbServiceProvider);
  final creditsJson = await service.fetchMovieCredits(cleanId);

  if (creditsJson == null || creditsJson['cast'] is! List) {
    return [];
  }

  final castList = creditsJson['cast'] as List;
  return castList
      .take(15) // Limit to top 15 prominent cast members
      .map((item) => CastMember.fromJson(item as Map<String, dynamic>))
      .toList();
});
