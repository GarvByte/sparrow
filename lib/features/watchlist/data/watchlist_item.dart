import 'package:hive/hive.dart';
import 'package:sparrow/shared/media_item.dart';

/// Persisted Watchlist model stored in local Hive storage.
///
/// Supports both Movies and TV Shows cleanly identified by a composite key
/// `[mediaType]_[id]` to avoid numeric ID collisions across media types.
class WatchlistItem {
  final String id;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String imageUrl;
  final String? backdropUrl;
  final double? rating;
  final String? ratingCount;
  final List<String> genres;
  final String? releaseDate;
  final String? overview;
  final bool isAdult;
  final DateTime? addedAt;

  const WatchlistItem({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.imageUrl,
    this.backdropUrl,
    this.rating,
    this.ratingCount,
    this.genres = const [],
    this.releaseDate,
    this.overview,
    this.isAdult = false,
    this.addedAt,
  });

  /// Generates a collision-resistant composite storage key.
  static String compositeKey(String mediaType, String id) =>
      '${mediaType.toLowerCase().trim()}_${id.trim()}';

  String get key => compositeKey(mediaType, id);

  bool get isTvShow => mediaType == 'tv';

  /// Reconstructs the shared [MediaItem] baseline for zero-latency offline display.
  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      imageUrl: imageUrl,
      genres: genres,
      rating: rating,
      ratingCount: ratingCount,
      overview: overview,
      releaseDate: releaseDate,
      backdropUrl: backdropUrl,
      isAdult: isAdult,
      mediaType: mediaType,
      bottomBadge: mediaType == 'tv' ? 'TV SHOW' : 'MOVIE',
    );
  }

  factory WatchlistItem.fromMediaItem(MediaItem item) {
    return WatchlistItem(
      id: item.id,
      mediaType: item.mediaType,
      title: item.title,
      imageUrl: item.imageUrl,
      backdropUrl: item.backdropUrl,
      rating: item.rating,
      ratingCount: item.ratingCount,
      genres: item.genres.map((e) => e.toString()).toList(),
      releaseDate: item.releaseDate,
      overview: item.overview,
      isAdult: item.isAdult,
      addedAt: DateTime.now(),
    );
  }

  WatchlistItem copyWith({
    String? id,
    String? mediaType,
    String? title,
    String? imageUrl,
    String? backdropUrl,
    double? rating,
    String? ratingCount,
    List<String>? genres,
    String? releaseDate,
    String? overview,
    bool? isAdult,
    DateTime? addedAt,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      overview: overview ?? this.overview,
      isAdult: isAdult ?? this.isAdult,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

/// Hive TypeAdapter for [WatchlistItem].
///
/// Handcrafted adapter for fast, zero-dependency serialization without build_runner.
class WatchlistItemAdapter extends TypeAdapter<WatchlistItem> {
  @override
  final int typeId = 0;

  @override
  WatchlistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final rawGenres = fields[7];
    final List<String> parsedGenres;
    if (rawGenres is List) {
      parsedGenres = rawGenres.map((e) => e.toString()).toList();
    } else {
      parsedGenres = const [];
    }

    final rawAddedAt = fields[11];
    final DateTime? parsedAddedAt = rawAddedAt is int
        ? DateTime.fromMillisecondsSinceEpoch(rawAddedAt)
        : (rawAddedAt is String ? DateTime.tryParse(rawAddedAt) : null);

    return WatchlistItem(
      id: (fields[0] ?? '').toString(),
      mediaType: (fields[1] ?? 'movie').toString(),
      title: (fields[2] ?? '').toString(),
      imageUrl: (fields[3] ?? '').toString(),
      backdropUrl: fields[4] as String?,
      rating: (fields[5] as num?)?.toDouble(),
      ratingCount: fields[6]?.toString(),
      genres: parsedGenres,
      releaseDate: fields[8] as String?,
      overview: fields[9] as String?,
      isAdult: fields[10] as bool? ?? false,
      addedAt: parsedAddedAt,
    );
  }

  @override
  void write(BinaryWriter writer, WatchlistItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mediaType)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.backdropUrl)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.ratingCount)
      ..writeByte(7)
      ..write(obj.genres)
      ..writeByte(8)
      ..write(obj.releaseDate)
      ..writeByte(9)
      ..write(obj.overview)
      ..writeByte(10)
      ..write(obj.isAdult)
      ..writeByte(11)
      ..write(obj.addedAt?.millisecondsSinceEpoch);
  }
}
