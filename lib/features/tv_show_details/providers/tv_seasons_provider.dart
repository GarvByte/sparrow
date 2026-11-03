import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';

/// Notifier tracking the selected season number mapped by TV series ID.
class SelectedSeasonNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void selectSeason(String seriesId, int seasonNumber) {
    state = {...state, seriesId: seasonNumber};
  }
}

final selectedSeasonMapProvider =
    NotifierProvider<SelectedSeasonNotifier, Map<String, int>>(
  SelectedSeasonNotifier.new,
);

/// Provider exposing the currently selected season number for a given series ID (defaults to 1).
final selectedSeasonProvider = Provider.family<int, String>((ref, seriesId) {
  final map = ref.watch(selectedSeasonMapProvider);
  return map[seriesId] ?? 1;
});

/// Query parameter descriptor for fetching specific season details.
class TvSeasonQuery {
  final String seriesId;
  final int seasonNumber;

  const TvSeasonQuery({
    required this.seriesId,
    required this.seasonNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvSeasonQuery &&
          other.seriesId == seriesId &&
          other.seasonNumber == seasonNumber;

  @override
  int get hashCode => Object.hash(seriesId, seasonNumber);
}

/// FutureProvider that fetches and caches full season episode data for a given series and season.
/// Re-selecting previously loaded seasons is instantaneous from cache.
final tvSeasonDetailProvider =
    FutureProvider.family<TvSeasonDetail?, TvSeasonQuery>((ref, query) async {
  final service = ref.watch(tmdbServiceProvider);
  final cleanId = query.seriesId.trim();

  if (cleanId.isEmpty) return null;

  return service.fetchAndParseTvSeasonDetail(cleanId, query.seasonNumber);
});
