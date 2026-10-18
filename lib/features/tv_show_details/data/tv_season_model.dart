import 'package:sparrow/shared/tmdb_base_url.dart';

/// Season summary embedded in TMDB TV Show details.
class TvSeasonSummary {
  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? airDate;
  final String? posterPath;

  const TvSeasonSummary({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.airDate,
    this.posterPath,
  });

  String get posterUrl => posterPath != null && posterPath!.isNotEmpty
      ? '$imageBaseUrl$posterPath'
      : '';

  String get airYear {
    if (airDate != null && airDate!.length >= 4) {
      return airDate!.substring(0, 4);
    }
    return '';
  }

  factory TvSeasonSummary.fromJson(Map<String, dynamic> json) {
    return TvSeasonSummary(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: (json['name'] ?? 'Season ${json['season_number'] ?? 1}').toString(),
      episodeCount: json['episode_count'] as int? ?? 0,
      airDate: json['air_date'] as String?,
      posterPath: json['poster_path'] as String?,
    );
  }
}

/// Detailed episode data returned by TMDB `/tv/{series_id}/season/{season_number}`.
class TvEpisodeInfo {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String overview;
  final String? stillPath;
  final int? runtime;
  final double? voteAverage;
  final String? airDate;

  const TvEpisodeInfo({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    this.stillPath,
    this.runtime,
    this.voteAverage,
    this.airDate,
  });

  String get stillUrl => stillPath != null && stillPath!.isNotEmpty
      ? '$imageBaseUrl$stillPath'
      : '';

  String get runtimeFormatted {
    if (runtime == null || runtime! <= 0) return '';
    return '$runtime min';
  }

  String get episodeLabel => 'S$seasonNumber E$episodeNumber · $name';

  factory TvEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return TvEpisodeInfo(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 1,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: (json['name'] ?? 'Episode ${json['episode_number'] ?? 1}').toString(),
      overview: (json['overview'] ?? '').toString(),
      stillPath: json['still_path'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      airDate: json['air_date'] as String?,
    );
  }
}

/// Full season payload containing all episodes.
class TvSeasonDetail {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? airDate;
  final List<TvEpisodeInfo> episodes;

  const TvSeasonDetail({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.airDate,
    required this.episodes,
  });

  factory TvSeasonDetail.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'] as List<dynamic>? ?? [];
    final parsedEpisodes = rawEpisodes
        .map((e) => TvEpisodeInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    return TvSeasonDetail(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: (json['name'] ?? 'Season').toString(),
      overview: json['overview'] as String?,
      airDate: json['air_date'] as String?,
      episodes: parsedEpisodes,
    );
  }
}
