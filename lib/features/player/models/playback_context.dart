import 'package:sparrow/shared/media_item.dart';

/// Context representing what is being played, including TMDB ID, IMDb ID,
/// content type, and season/episode context for TV shows.
class PlaybackContext {
  final MediaItem item;
  final String tmdbId;
  final String imdbId;
  final bool isTvShow;
  final int season;
  final int episode;
  final String? episodeTitle;

  const PlaybackContext({
    required this.item,
    required this.tmdbId,
    this.imdbId = '',
    required this.isTvShow,
    this.season = 0,
    this.episode = 0,
    this.episodeTitle,
  });

  /// Factory for Movie playback. Season and episode are always 0.
  factory PlaybackContext.movie({
    required MediaItem item,
    String imdbId = '',
  }) {
    return PlaybackContext(
      item: item,
      tmdbId: item.id.trim(),
      imdbId: imdbId.trim(),
      isTvShow: false,
      season: 0,
      episode: 0,
    );
  }

  /// Factory for TV Show playback. Season and episode use actual numbers.
  factory PlaybackContext.tv({
    required MediaItem item,
    required int season,
    required int episode,
    String imdbId = '',
    String? episodeTitle,
  }) {
    return PlaybackContext(
      item: item,
      tmdbId: item.id.trim(),
      imdbId: imdbId.trim(),
      isTvShow: true,
      season: season,
      episode: episode,
      episodeTitle: episodeTitle,
    );
  }

  /// Create context dynamically from a [MediaItem].
  factory PlaybackContext.fromMediaItem(
    MediaItem item, {
    int season = 0,
    int episode = 0,
    String imdbId = '',
    String? episodeTitle,
  }) {
    if (item.isTvShow) {
      return PlaybackContext.tv(
        item: item,
        season: season > 0 ? season : 1,
        episode: episode > 0 ? episode : 1,
        imdbId: imdbId,
        episodeTitle: episodeTitle,
      );
    }
    return PlaybackContext.movie(
      item: item,
      imdbId: imdbId,
    );
  }

  String get type => isTvShow ? 'tv' : 'movie';

  /// Human-readable title for display in the player.
  String get displayTitle {
    if (isTvShow) {
      final epLabel = 'S$season E$episode';
      if (episodeTitle != null && episodeTitle!.trim().isNotEmpty) {
        return '${item.title} - $epLabel: $episodeTitle';
      }
      return '${item.title} - $epLabel';
    }
    return item.title;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackContext &&
          runtimeType == other.runtimeType &&
          tmdbId == other.tmdbId &&
          imdbId == other.imdbId &&
          isTvShow == other.isTvShow &&
          season == other.season &&
          episode == other.episode;

  @override
  int get hashCode => Object.hash(tmdbId, imdbId, isTvShow, season, episode);

  @override
  String toString() {
    return 'PlaybackContext(id: $tmdbId, type: $type, s: $season, e: $episode)';
  }
}
