import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../player/models/playback_context.dart';
import '../data/continue_watching_item.dart';
import '../data/continue_watching_repository.dart';

/// Provider for the singleton [ContinueWatchingRepository].
final continueWatchingRepositoryProvider =
    Provider<ContinueWatchingRepository>((ref) {
  return ContinueWatchingRepository();
});

/// Riverpod [Notifier] exposing reactive state of user's Continue Watching history.
class ContinueWatchingNotifier extends Notifier<List<ContinueWatchingItem>> {
  @override
  List<ContinueWatchingItem> build() {
    final repository = ref.watch(continueWatchingRepositoryProvider);
    return repository.getAllItems();
  }

  /// Saves or updates playback progress and refreshes state reactively.
  Future<bool> saveProgress({
    required String mediaType,
    required String tmdbId,
    required String title,
    required String imageUrl,
    String? backdropUrl,
    required int positionMs,
    required int durationMs,
    int season = 0,
    int episode = 0,
    String? episodeTitle,
    List<String> genres = const [],
    double? rating,
    String? overview,
    bool isAdult = false,
  }) async {
    final repository = ref.read(continueWatchingRepositoryProvider);
    final saved = await repository.saveProgress(
      mediaType: mediaType,
      tmdbId: tmdbId,
      title: title,
      imageUrl: imageUrl,
      backdropUrl: backdropUrl,
      positionMs: positionMs,
      durationMs: durationMs,
      season: season,
      episode: episode,
      episodeTitle: episodeTitle,
      genres: genres,
      rating: rating,
      overview: overview,
      isAdult: isAdult,
    );
    state = repository.getAllItems();
    return saved;
  }

  /// Removes an item by its key and refreshes reactive state immediately.
  Future<void> remove(String key) async {
    final repository = ref.read(continueWatchingRepositoryProvider);
    await repository.removeItem(key);
    state = repository.getAllItems();
  }

  /// Forces a sync with the persistent layer.
  void refresh() {
    final repository = ref.read(continueWatchingRepositoryProvider);
    state = repository.getAllItems();
  }
}

/// Primary reactive Continue Watching provider for the application.
final continueWatchingProvider =
    NotifierProvider<ContinueWatchingNotifier, List<ContinueWatchingItem>>(
  ContinueWatchingNotifier.new,
);

/// Provider filtered strictly to TV show episodes for the TV Shows page.
final tvContinueWatchingProvider = Provider<List<ContinueWatchingItem>>((ref) {
  final all = ref.watch(continueWatchingProvider);
  return all.where((item) => item.isTvShow).toList();
});

/// Parameterized family provider checking if a title/episode has saved progress.
/// Re-evaluates instantly when [continueWatchingProvider] mutates.
final hasPlaybackProgressProvider =
    Provider.family<bool, String>((ref, key) {
  final items = ref.watch(continueWatchingProvider);
  return items.any((item) => item.key == key && item.positionMs > 0);
});

/// Family provider checking if a [PlaybackContext] has saved progress.
final contextPlaybackProgressProvider =
    Provider.family<bool, PlaybackContext>((ref, context) {
  final key = ContinueWatchingItem.compositeKey(
    context.type,
    context.tmdbId,
    season: context.season,
    episode: context.episode,
  );
  final items = ref.watch(continueWatchingProvider);
  return items.any((item) => item.key == key && item.positionMs > 0);
});
