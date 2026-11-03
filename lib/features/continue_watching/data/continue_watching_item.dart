import 'package:hive/hive.dart';
import 'package:sparrow/shared/media_item.dart';

/// Persisted Continue Watching model stored in local Hive storage.
///
/// Cleanly identifies Movies and TV episodes using collision-resistant composite keys:
/// - Movies: `movie_[tmdbId]`
/// - TV episodes: `tv_[tmdbId]_s[season]_e[episode]`
class ContinueWatchingItem {
  final String key;
  final String mediaType; // 'movie' or 'tv'
  final String tmdbId;
  final String title;
  final String imageUrl;
  final String? backdropUrl;
  final int positionMs;
  final int durationMs;
  final DateTime lastUpdatedAt;
  final int season;
  final int episode;
  final String? episodeTitle;
  final List<String> genres;
  final double? rating;
  final String? overview;
  final bool isAdult;

  const ContinueWatchingItem({
    required this.key,
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    required this.imageUrl,
    this.backdropUrl,
    required this.positionMs,
    required this.durationMs,
    required this.lastUpdatedAt,
    this.season = 0,
    this.episode = 0,
    this.episodeTitle,
    this.genres = const [],
    this.rating,
    this.overview,
    this.isAdult = false,
  });

  /// Builds a deterministic, collision-resistant composite storage key.
  static String compositeKey(
    String mediaType,
    String id, {
    int season = 0,
    int episode = 0,
  }) {
    final type = mediaType.toLowerCase().trim();
    final cleanId = id.trim();
    if (type == 'tv') {
      return 'tv_${cleanId}_s${season}_e$episode';
    }
    return 'movie_$cleanId';
  }

  bool get isTvShow => mediaType == 'tv';

  /// Fraction of media played, clamped between 0.0 and 1.0.
  double get progress {
    if (durationMs <= 0) return 0.0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  /// Formatted remaining duration, e.g. "42m left".
  String? get durationLeft {
    if (durationMs <= 0 || positionMs <= 0) return null;
    final remainingMs = durationMs - positionMs;
    if (remainingMs <= 0) return '0m left';
    final remainingMinutes = (remainingMs / 60000).ceil();
    if (remainingMinutes >= 60) {
      final hours = remainingMinutes ~/ 60;
      final mins = remainingMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m left' : '${hours}h left';
    }
    return '${remainingMinutes}m left';
  }

  /// Converts this record to a [MediaItem] suitable for zero-network carousel display.
  MediaItem toMediaItem() {
    final displayImage = (backdropUrl != null && backdropUrl!.isNotEmpty)
        ? backdropUrl!
        : imageUrl;

    final badge = isTvShow ? 'S$season E$episode' : 'MOVIE';

    return MediaItem(
      id: tmdbId,
      title: title,
      imageUrl: displayImage,
      genres: genres,
      rating: rating,
      overview: overview,
      backdropUrl: backdropUrl,
      isAdult: isAdult,
      mediaType: mediaType,
      durationLeft: durationLeft,
      progress: progress,
      aspectRatio: 16 / 9,
      bottomBadge: badge,
    );
  }

  ContinueWatchingItem copyWith({
    String? key,
    String? mediaType,
    String? tmdbId,
    String? title,
    String? imageUrl,
    String? backdropUrl,
    int? positionMs,
    int? durationMs,
    DateTime? lastUpdatedAt,
    int? season,
    int? episode,
    String? episodeTitle,
    List<String>? genres,
    double? rating,
    String? overview,
    bool? isAdult,
  }) {
    return ContinueWatchingItem(
      key: key ?? this.key,
      mediaType: mediaType ?? this.mediaType,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      genres: genres ?? this.genres,
      rating: rating ?? this.rating,
      overview: overview ?? this.overview,
      isAdult: isAdult ?? this.isAdult,
    );
  }
}

/// Handcrafted Hive TypeAdapter for [ContinueWatchingItem].
///
/// Fast, zero-dependency serialization without build_runner, using unique typeId 1.
class ContinueWatchingItemAdapter extends TypeAdapter<ContinueWatchingItem> {
  @override
  final int typeId = 1;

  @override
  ContinueWatchingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawGenres = fields[12];
    final List<String> parsedGenres;
    if (rawGenres is List) {
      parsedGenres = rawGenres.map((e) => e.toString()).toList();
    } else {
      parsedGenres = const [];
    }

    final rawUpdated = fields[8];
    final DateTime parsedUpdated;
    if (rawUpdated is int) {
      parsedUpdated = DateTime.fromMillisecondsSinceEpoch(rawUpdated);
    } else if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated) ?? DateTime.now();
    } else {
      parsedUpdated = DateTime.now();
    }

    return ContinueWatchingItem(
      key: (fields[0] ?? '').toString(),
      mediaType: (fields[1] ?? 'movie').toString(),
      tmdbId: (fields[2] ?? '').toString(),
      title: (fields[3] ?? '').toString(),
      imageUrl: (fields[4] ?? '').toString(),
      backdropUrl: fields[5] as String?,
      positionMs: (fields[6] as num?)?.toInt() ?? 0,
      durationMs: (fields[7] as num?)?.toInt() ?? 0,
      lastUpdatedAt: parsedUpdated,
      season: (fields[9] as num?)?.toInt() ?? 0,
      episode: (fields[10] as num?)?.toInt() ?? 0,
      episodeTitle: fields[11] as String?,
      genres: parsedGenres,
      rating: (fields[13] as num?)?.toDouble(),
      overview: fields[14] as String?,
      isAdult: fields[15] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ContinueWatchingItem obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.mediaType)
      ..writeByte(2)
      ..write(obj.tmdbId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.backdropUrl)
      ..writeByte(6)
      ..write(obj.positionMs)
      ..writeByte(7)
      ..write(obj.durationMs)
      ..writeByte(8)
      ..write(obj.lastUpdatedAt.millisecondsSinceEpoch)
      ..writeByte(9)
      ..write(obj.season)
      ..writeByte(10)
      ..write(obj.episode)
      ..writeByte(11)
      ..write(obj.episodeTitle)
      ..writeByte(12)
      ..write(obj.genres)
      ..writeByte(13)
      ..write(obj.rating)
      ..writeByte(14)
      ..write(obj.overview)
      ..writeByte(15)
      ..write(obj.isAdult);
  }
}
