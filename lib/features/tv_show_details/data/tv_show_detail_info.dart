import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// Comprehensive detailed TV show model combining TMDB series details,
/// seasons, credits, and production telemetry.
class TvShowDetailInfo {
  final String id;
  final String name;
  final String? originalName;
  final String? overview;
  final String? backdropUrl;
  final String? posterUrl;
  final String? firstAirDate;
  final String firstAirYear;
  final String firstAirDateFormatted;
  final String? lastAirDate;
  final String lastAirYear;
  final String lastAirDateFormatted;
  final String airYearsFormatted;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final int? episodeRunTime;
  final String runtimeFormatted;
  final double? rating;
  final String? ratingCount;
  final List<String> genres;
  final String creators;
  final String studios;
  final String originalLanguage;
  final String status;
  final String? tagline;
  final bool isAdult;
  final String? contentCertification;
  final List<TvSeasonSummary> seasons;
  final String imdbId;

  const TvShowDetailInfo({
    required this.id,
    required this.name,
    this.imdbId = '',
    this.originalName,
    this.overview,
    this.backdropUrl,
    this.posterUrl,
    this.firstAirDate,
    required this.firstAirYear,
    required this.firstAirDateFormatted,
    this.lastAirDate,
    required this.lastAirYear,
    required this.lastAirDateFormatted,
    required this.airYearsFormatted,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    this.episodeRunTime,
    required this.runtimeFormatted,
    this.rating,
    this.ratingCount,
    required this.genres,
    required this.creators,
    required this.studios,
    required this.originalLanguage,
    required this.status,
    this.tagline,
    required this.isAdult,
    this.contentCertification,
    required this.seasons,
  });

  /// Title accessor for uniform UI compatibility.
  String get title => name;

  /// Seasons formatted string (e.g., "5 Seasons" or "1 Season").
  String get seasonsFormatted {
    if (numberOfSeasons <= 0) return '1 Season';
    return numberOfSeasons == 1 ? '1 Season' : '$numberOfSeasons Seasons';
  }

  /// Episodes formatted string (e.g., "62 Episodes").
  String get episodesFormatted {
    if (numberOfEpisodes <= 0) return '';
    return numberOfEpisodes == 1 ? '1 Episode' : '$numberOfEpisodes Episodes';
  }

  /// Construct an initial baseline [TvShowDetailInfo] from an existing [MediaItem]
  /// for zero-latency screen entry before full network details load.
  factory TvShowDetailInfo.fromMediaItem(MediaItem item) {
    String year = '';
    if (item.releaseDate != null && item.releaseDate!.length >= 4) {
      year = item.releaseDate!.substring(0, 4);
    }

    final genreList = item.genres.map((g) => g.toString()).toList();

    return TvShowDetailInfo(
      id: item.id,
      name: item.title,
      originalName: item.title,
      overview: item.overview,
      backdropUrl:
          item.backdropUrl ?? (item.imageUrl.isNotEmpty ? item.imageUrl : null),
      posterUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
      firstAirDate: item.releaseDate,
      firstAirYear: year.isNotEmpty ? year : '2024',
      firstAirDateFormatted: item.releaseDate ?? '',
      lastAirDate: null,
      lastAirYear: '',
      lastAirDateFormatted: '',
      airYearsFormatted: year.isNotEmpty ? year : '2024',
      numberOfSeasons: 1,
      numberOfEpisodes: 0,
      episodeRunTime: null,
      runtimeFormatted: '',
      rating: item.rating,
      ratingCount: item.ratingCount,
      genres: genreList,
      creators: '',
      studios: '',
      originalLanguage: 'ENGLISH',
      status: 'Ongoing',
      tagline: null,
      isAdult: item.isAdult,
      contentCertification: null,
      seasons: const [],
      imdbId: '',
    );
  }

  /// Factory merging raw TMDB TV show JSON and optional credits.
  factory TvShowDetailInfo.fromTmdbJson({
    required Map<String, dynamic> json,
    Map<String, dynamic>? creditsJson,
    MediaItem? fallbackItem,
  }) {
    final id = json['id']?.toString() ?? fallbackItem?.id ?? '';
    final name = (json['name'] ?? json['title'] ?? fallbackItem?.title ?? 'Untitled')
        .toString();
    final originalName = json['original_name'] as String?;
    final overview = (json['overview'] ?? fallbackItem?.overview) as String?;

    // isAdult handling: preserve project convention
    final isAdult = json['adult'] as bool? ?? fallbackItem?.isAdult ?? false;

    // Artwork
    final backdropPath = json['backdrop_path'] as String?;
    final posterPath = json['poster_path'] as String?;

    String? backdropUrl;
    if (backdropPath != null && backdropPath.isNotEmpty) {
      backdropUrl = '$imageBaseUrl2$backdropPath';
    } else if (fallbackItem?.backdropUrl != null &&
        fallbackItem!.backdropUrl!.isNotEmpty) {
      backdropUrl = fallbackItem.backdropUrl;
    } else if (fallbackItem?.imageUrl != null &&
        fallbackItem!.imageUrl.isNotEmpty) {
      backdropUrl = fallbackItem.imageUrl;
    }

    String? posterUrl;
    if (posterPath != null && posterPath.isNotEmpty) {
      posterUrl = '$imageBaseUrl$posterPath';
    } else if (fallbackItem?.imageUrl != null &&
        fallbackItem!.imageUrl.isNotEmpty) {
      posterUrl = fallbackItem.imageUrl;
    }

    // Air dates
    final firstAirDateStr = (json['first_air_date'] ?? fallbackItem?.releaseDate) as String?;
    final lastAirDateStr = json['last_air_date'] as String?;

    String firstYear = '';
    String formattedFirstDate = '';
    if (firstAirDateStr != null && firstAirDateStr.isNotEmpty) {
      final parts = firstAirDateStr.split('-');
      if (parts.isNotEmpty && parts[0].length == 4) {
        firstYear = parts[0];
      }
      formattedFirstDate = _formatDate(firstAirDateStr);
    }
    if (firstYear.isEmpty &&
        fallbackItem?.releaseDate != null &&
        fallbackItem!.releaseDate!.length >= 4) {
      firstYear = fallbackItem.releaseDate!.substring(0, 4);
    }

    String lastYear = '';
    String formattedLastDate = '';
    if (lastAirDateStr != null && lastAirDateStr.isNotEmpty) {
      final parts = lastAirDateStr.split('-');
      if (parts.isNotEmpty && parts[0].length == 4) {
        lastYear = parts[0];
      }
      formattedLastDate = _formatDate(lastAirDateStr);
    }

    // Status
    final statusStr = (json['status'] ?? 'Ongoing').toString();

    // Air years range (e.g. "2008–2013", "2022–Present", "2024")
    String airYearsFormatted = firstYear;
    if (firstYear.isNotEmpty) {
      if (lastYear.isNotEmpty && lastYear != firstYear) {
        airYearsFormatted = '$firstYear–$lastYear';
      } else if (statusStr.toLowerCase().contains('returning') ||
          statusStr.toLowerCase().contains('ongoing') ||
          statusStr.toLowerCase().contains('in production')) {
        airYearsFormatted = '$firstYear–Present';
      }
    }

    // Number of seasons & episodes
    final numberOfSeasons = json['number_of_seasons'] as int? ?? 1;
    final numberOfEpisodes = json['number_of_episodes'] as int? ?? 0;

    // Episode runtime
    int? episodeRunTime;
    if (json['episode_run_time'] is List &&
        (json['episode_run_time'] as List).isNotEmpty) {
      episodeRunTime = (json['episode_run_time'] as List).first as int?;
    }
    String runtimeFormatted = '';
    if (episodeRunTime != null && episodeRunTime > 0) {
      runtimeFormatted = '$episodeRunTime min';
    }

    // Rating
    final ratingVal =
        (json['vote_average'] as num?)?.toDouble() ?? fallbackItem?.rating;
    final voteCountVal =
        json['vote_count']?.toString() ?? fallbackItem?.ratingCount;

    // Genres
    List<String> genreNames = [];
    if (json['genres'] is List) {
      genreNames = (json['genres'] as List)
          .map((g) => g is Map ? (g['name']?.toString() ?? '') : g.toString())
          .where((name) => name.isNotEmpty)
          .toList();
    }
    if (genreNames.isEmpty && fallbackItem?.genres != null) {
      genreNames = fallbackItem!.genres.map((g) => g.toString()).toList();
    }

    // Creators
    String creators = '';
    if (json['created_by'] is List && (json['created_by'] as List).isNotEmpty) {
      creators = (json['created_by'] as List)
          .map((c) => c is Map ? (c['name']?.toString() ?? '') : '')
          .where((n) => n.isNotEmpty)
          .join(', ');
    }
    if (creators.isEmpty && creditsJson != null && creditsJson['crew'] is List) {
      final crewList = creditsJson['crew'] as List;
      for (final member in crewList) {
        if (member is Map) {
          final job = (member['job'] ?? '').toString().toLowerCase();
          final name = (member['name'] ?? '').toString();
          if (job == 'creator' || job == 'executive producer') {
            if (creators.isEmpty) {
              creators = name;
            } else if (!creators.contains(name)) {
              creators += ', $name';
            }
          }
        }
      }
    }

    // Production companies / Studios
    String studios = '';
    if (json['production_companies'] is List) {
      studios = (json['production_companies'] as List)
          .take(2)
          .map((c) => c is Map ? (c['name']?.toString() ?? '') : '')
          .where((n) => n.isNotEmpty)
          .join(', ');
    }

    // Original Language
    String originalLanguage = (json['original_language'] ?? 'en')
        .toString()
        .toUpperCase();
    if (originalLanguage == 'EN') {
      originalLanguage = 'ENGLISH';
    } else if (originalLanguage == 'HI') {
      originalLanguage = 'HINDI';
    } else if (originalLanguage == 'JA') {
      originalLanguage = 'JAPANESE';
    } else if (originalLanguage == 'ES') {
      originalLanguage = 'SPANISH';
    } else if (originalLanguage == 'KO') {
      originalLanguage = 'KOREAN';
    }

    // Seasons list (excluding "Specials" / Season 0 if standard seasons exist)
    final List<TvSeasonSummary> seasonsList = [];
    if (json['seasons'] is List) {
      final rawSeasons = json['seasons'] as List;
      for (final s in rawSeasons) {
        if (s is Map<String, dynamic>) {
          final season = TvSeasonSummary.fromJson(s);
          // Only exclude season 0 (Specials) if there are other seasons
          if (season.seasonNumber > 0 || rawSeasons.length == 1) {
            seasonsList.add(season);
          }
        }
      }
    }
    // Sort seasons by seasonNumber ascending
    seasonsList.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    // Content certification if present in content_ratings
    String? contentCertification;
    if (json['content_ratings'] != null &&
        json['content_ratings']['results'] is List) {
      final results = json['content_ratings']['results'] as List;
      for (final r in results) {
        if (r is Map && (r['iso_3166_1'] == 'US' || r['iso_3166_1'] == 'IN')) {
          final cert = r['rating']?.toString();
          if (cert != null && cert.isNotEmpty) {
            contentCertification = cert;
            break;
          }
        }
      }
    }

    final tagline = json['tagline'] as String?;

    return TvShowDetailInfo(
      id: id,
      name: name,
      originalName: originalName,
      overview: overview,
      backdropUrl: backdropUrl,
      posterUrl: posterUrl,
      firstAirDate: firstAirDateStr,
      firstAirYear: firstYear.isNotEmpty ? firstYear : '2024',
      firstAirDateFormatted: formattedFirstDate.isNotEmpty
          ? formattedFirstDate
          : (firstAirDateStr ?? ''),
      lastAirDate: lastAirDateStr,
      lastAirYear: lastYear,
      lastAirDateFormatted: formattedLastDate.isNotEmpty
          ? formattedLastDate
          : (lastAirDateStr ?? ''),
      airYearsFormatted: airYearsFormatted.isNotEmpty ? airYearsFormatted : '2024',
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      episodeRunTime: episodeRunTime,
      runtimeFormatted: runtimeFormatted,
      rating: ratingVal,
      ratingCount: voteCountVal,
      genres: genreNames,
      creators: creators,
      studios: studios,
      originalLanguage: originalLanguage,
      status: statusStr,
      tagline: tagline,
      isAdult: isAdult,
      contentCertification: contentCertification,
      seasons: seasonsList,
      imdbId: (json['imdb_id'] ?? json['external_ids']?['imdb_id'] ?? '').toString(),
    );
  }

  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.tryParse(isoDate);
      if (date == null) return isoDate;
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final monthName = months[date.month - 1];
      return '$monthName ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
