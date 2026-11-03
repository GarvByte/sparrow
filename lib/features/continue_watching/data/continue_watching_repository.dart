import 'package:hive/hive.dart';
import '../../player/models/playback_context.dart';
import 'continue_watching_item.dart';
import 'continue_watching_storage.dart';

/// Repository abstracting persistence operations for Continue Watching playback progress.
///
/// Interacts directly with the dedicated Hive box `sparrow_continue_watching_box`,
/// while maintaining an in-memory fallback for test harnesses executing without Hive.
class ContinueWatchingRepository {
  final Box<ContinueWatchingItem>? _explicitBox;
  static final Map<String, ContinueWatchingItem> _memoryFallback = {};
  static final Set<String> _recentlyRemovedKeys = {};

  /// Configurable eligibility threshold: media must be watched for at least 2 minutes
  /// of actual playback before qualifying for a new Continue Watching entry.
  static const Duration eligibilityThreshold = Duration(minutes: 2);

  /// Media within 15 seconds of duration or past 95% completion is considered finished.
  static const Duration completionRemainingThreshold = Duration(seconds: 15);
  static const double completionRatioThreshold = 0.95;

  ContinueWatchingRepository([this._explicitBox]);

  Box<ContinueWatchingItem>? get _activeBox {
    if (_explicitBox != null && _explicitBox.isOpen) return _explicitBox;
    return ContinueWatchingStorage.getBox();
  }

  /// Determines whether a given playback position qualifies as completed.
  bool isCompleted(int positionMs, int durationMs) {
    if (durationMs <= 0 || positionMs <= 0) return false;
    if (positionMs >= durationMs - completionRemainingThreshold.inMilliseconds) {
      return true;
    }
    if (positionMs / durationMs >= completionRatioThreshold) {
      return true;
    }
    return false;
  }

  /// Retrieves all persisted items, ordered by last update date descending.
  List<ContinueWatchingItem> getAllItems() {
    final box = _activeBox;
    final List<ContinueWatchingItem> list;
    if (box != null && box.isOpen) {
      list = box.values.toList();
    } else {
      list = _memoryFallback.values.toList();
    }

    list.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return list;
  }

  /// Retrieves only TV episodes, ordered by last update date descending.
  List<ContinueWatchingItem> getTvItems() {
    return getAllItems().where((item) => item.isTvShow).toList();
  }

  /// Retrieves only Movies, ordered by last update date descending.
  List<ContinueWatchingItem> getMovieItems() {
    return getAllItems().where((item) => !item.isTvShow).toList();
  }

  /// Looks up a single item by its composite key.
  ContinueWatchingItem? getItem(String key) {
    final box = _activeBox;
    if (box != null && box.isOpen) {
      return box.get(key);
    }
    return _memoryFallback[key];
  }

  /// Looks up saved progress for a specific [PlaybackContext].
  ContinueWatchingItem? getItemForContext(PlaybackContext context) {
    final key = ContinueWatchingItem.compositeKey(
      context.type,
      context.tmdbId,
      season: context.season,
      episode: context.episode,
    );
    return getItem(key);
  }

  /// Checks whether valid progress exists for a given composite key.
  bool hasValidProgress(String key) {
    final item = getItem(key);
    return item != null && item.positionMs > 0;
  }

  /// Checks whether valid progress exists for a specific [PlaybackContext].
  bool hasProgressForContext(PlaybackContext context) {
    final item = getItemForContext(context);
    return item != null && item.positionMs > 0;
  }

  /// Saves or updates playback progress.
  ///
  /// Enforces:
  /// 1. 2-minute threshold for new entries.
  /// 2. If an entry already exists, preserves and updates it even if current session < 2 mins.
  /// 3. Removal upon natural playback completion.
  /// 4. Guards against in-flight stale saves recreating recently removed entries.
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
    final key = ContinueWatchingItem.compositeKey(
      mediaType,
      tmdbId,
      season: season,
      episode: episode,
    );

    // Guard: Do not recreate an entry the user just removed
    if (_recentlyRemovedKeys.contains(key)) {
      return false;
    }

    // Playback completion policy: remove finished items
    if (isCompleted(positionMs, durationMs)) {
      await removeItem(key);
      return false;
    }

    final existing = getItem(key);

    // Eligibility check:
    // A video qualifies only after reaching 2 minutes of playback,
    // OR if it already had saved progress from a previous qualifying session.
    final hasMetThreshold = positionMs >= eligibilityThreshold.inMilliseconds;
    final isEligible = (existing != null) || hasMetThreshold;

    if (!isEligible) {
      return false;
    }

    // Do not overwrite a valid known duration with 0 or negative
    final effectiveDuration =
        durationMs > 0 ? durationMs : (existing?.durationMs ?? 0);

    final item = ContinueWatchingItem(
      key: key,
      mediaType: mediaType,
      tmdbId: tmdbId,
      title: title,
      imageUrl: imageUrl,
      backdropUrl: backdropUrl ?? existing?.backdropUrl,
      positionMs: positionMs,
      durationMs: effectiveDuration,
      lastUpdatedAt: DateTime.now(),
      season: season,
      episode: episode,
      episodeTitle: episodeTitle ?? existing?.episodeTitle,
      genres: genres.isNotEmpty ? genres : (existing?.genres ?? const []),
      rating: rating ?? existing?.rating,
      overview: overview ?? existing?.overview,
      isAdult: isAdult,
    );

    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.put(key, item);
    } else {
      _memoryFallback[key] = item;
    }
    return true;
  }

  /// Removes an item by key and marks it to prevent stale in-flight writes.
  Future<void> removeItem(String key) async {
    _recentlyRemovedKeys.add(key);
    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.delete(key);
    } else {
      _memoryFallback.remove(key);
    }
  }

  /// Clears recently removed marker when a brand new playback session starts.
  void clearRecentlyRemoved(String key) {
    _recentlyRemovedKeys.remove(key);
  }

  /// Clears all entries from storage.
  Future<void> clearAll() async {
    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.clear();
    }
    _memoryFallback.clear();
    _recentlyRemovedKeys.clear();
  }
}
