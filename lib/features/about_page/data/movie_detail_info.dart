import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// Comprehensive detailed movie model combining TMDB movie details and credits.
class MovieDetailInfo {
  final String id;
  final String title;
  final String? overview;
  final String? backdropUrl;
  final String? posterUrl;
  final String? releaseDate;
  final String releaseYear;
  final String releaseDateFormatted;
  final int? runtime;
  final String runtimeFormatted;
  final double? rating;
  final String? ratingCount;
  final List<String> genres;
  final String director;
  final String writers;
  final String studios;
  final String originalLanguage;
  final int? budget;
  final String budgetFormatted;
  final int? revenue;
  final String revenueFormatted;
  final String? tagline;
  final bool isAdult;
  final String imdbId;

  const MovieDetailInfo({
    required this.id,
    required this.title,
    this.imdbId = '',
    this.overview,
    this.backdropUrl,
    this.posterUrl,
    this.releaseDate,
    required this.releaseYear,
    required this.releaseDateFormatted,
    this.runtime,
    required this.runtimeFormatted,
    this.rating,
    this.ratingCount,
    required this.genres,
    required this.director,
    required this.writers,
    required this.studios,
    required this.originalLanguage,
    this.budget,
    required this.budgetFormatted,
    this.revenue,
    required this.revenueFormatted,
    this.tagline,
    required this.isAdult,
  });

  /// Construct an initial baseline [MovieDetailInfo] from an existing [MediaItem]
  /// before additional network details finish loading.
  factory MovieDetailInfo.fromMediaItem(MediaItem item) {
    String year = '';
    if (item.releaseDate != null && item.releaseDate!.length >= 4) {
      year = item.releaseDate!.substring(0, 4);
    }

    final genreList = item.genres.map((g) => g.toString()).toList();
    //debugPrintt("isAdult2 = ${item.isAdult}");
    return MovieDetailInfo(
      id: item.id,
      title: item.title,
      overview: item.overview,
      backdropUrl:
          item.backdropUrl ?? (item.imageUrl.isNotEmpty ? item.imageUrl : null),
      posterUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
      releaseDate: item.releaseDate,
      releaseYear: year.isNotEmpty ? year : '2024',
      releaseDateFormatted: item.releaseDate ?? '',
      runtime: null,
      runtimeFormatted: '',
      rating: item.rating,
      ratingCount: item.ratingCount,
      genres: genreList,
      director: '',
      writers: '',
      studios: '',
      originalLanguage: '',
      budget: null,
      budgetFormatted: '',
      revenue: null,
      revenueFormatted: '',
      tagline: null,
      isAdult: item.isAdult,
      imdbId: '',
    );
  }

  /// Factory merging raw TMDB details map and credits map.
  factory MovieDetailInfo.fromTmdbJson({
    required Map<String, dynamic> json,
    Map<String, dynamic>? creditsJson,
    MediaItem? fallbackItem,
  }) {
    final id = json['id']?.toString() ?? fallbackItem?.id ?? '';
    final title = (json['title'] ?? fallbackItem?.title ?? 'Untitled')
        .toString();
    final overview = (json['overview'] ?? fallbackItem?.overview) as String?;

    final isAdult = json['adult'] as bool? ?? fallbackItem?.isAdult ?? false;

    // Images
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

    // Release date & year
    final releaseDateStr =
        (json['release_date'] ?? fallbackItem?.releaseDate) as String?;
    String year = '';
    String formattedDate = '';
    if (releaseDateStr != null && releaseDateStr.isNotEmpty) {
      final parts = releaseDateStr.split('-');
      if (parts.isNotEmpty && parts[0].length == 4) {
        year = parts[0];
      }
      formattedDate = _formatDate(releaseDateStr);
    }
    if (year.isEmpty &&
        fallbackItem?.releaseDate != null &&
        fallbackItem!.releaseDate!.length >= 4) {
      year = fallbackItem.releaseDate!.substring(0, 4);
    }

    // Runtime
    final runtimeMinutes = json['runtime'] as int?;
    String runtimeFormatted = '';
    if (runtimeMinutes != null && runtimeMinutes > 0) {
      final hours = runtimeMinutes ~/ 60;
      final mins = runtimeMinutes % 60;
      runtimeFormatted = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
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

    // Studios / Production
    String studios = '';
    if (json['production_companies'] is List) {
      studios = (json['production_companies'] as List)
          .take(2)
          .map((c) => c is Map ? (c['name']?.toString() ?? '') : '')
          .where((n) => n.isNotEmpty)
          .join(', ');
    }

    // Language
    String originalLanguage = '';
    if (json['original_language'] is List &&
        (json['original_language'] as List).isNotEmpty) {
      final first = (json['original_language'] as List).first;
      if (first is Map) {
        originalLanguage = (first['english_name'] ?? first['name'] ?? '')
            .toString();
      }
    }
    if (originalLanguage.isEmpty) {
      originalLanguage = (json['original_language'] ?? 'English')
          .toString()
          .toUpperCase();
    }

    // Budget & Revenue
    final budgetNum = json['budget'] as int?;
    final revenueNum = json['revenue'] as int?;
    final budgetFormatted = _formatCurrency(budgetNum);
    final revenueFormatted = _formatCurrency(revenueNum);

    // Crew: Directors & Writers
    String director = '';
    final List<String> writerList = [];

    if (creditsJson != null && creditsJson['crew'] is List) {
      final crewList = creditsJson['crew'] as List;
      for (final member in crewList) {
        if (member is Map) {
          final job = (member['job'] ?? '').toString().toLowerCase();
          final department = (member['department'] ?? '')
              .toString()
              .toLowerCase();
          final name = (member['name'] ?? '').toString();

          if (job == 'director') {
            if (director.isEmpty) {
              director = name;
            } else if (!director.contains(name)) {
              director += ', $name';
            }
          }

          if (job == 'screenplay' ||
              job == 'writer' ||
              department == 'writing') {
            if (name.isNotEmpty && !writerList.contains(name)) {
              writerList.add(name);
            }
          }
        }
      }
    }

    final writers = writerList.take(3).join(', ');
    final tagline = json['tagline'] as String?;
    //debugPrintt("isAdult 1 = $isAdult");

    return MovieDetailInfo(
      id: id,
      title: title,
      overview: overview,
      backdropUrl: backdropUrl,
      posterUrl: posterUrl,
      releaseDate: releaseDateStr,
      releaseYear: year.isNotEmpty ? year : '2024',
      releaseDateFormatted: formattedDate.isNotEmpty
          ? formattedDate
          : (releaseDateStr ?? ''),
      runtime: runtimeMinutes,
      runtimeFormatted: runtimeFormatted,
      rating: ratingVal,
      ratingCount: voteCountVal,
      genres: genreNames,
      director: director,
      writers: writers,
      studios: studios,
      originalLanguage: originalLanguage == "HI"
          ? "HINDI"
          : originalLanguage == "EN"
          ? "ENGLISH"
          : originalLanguage,
      budget: budgetNum,
      budgetFormatted: budgetFormatted,
      revenue: revenueNum,
      revenueFormatted: revenueFormatted,
      tagline: tagline,
      isAdult: isAdult,
      imdbId: (json['imdb_id'] ?? '').toString(),
    );
  }

  static String _formatCurrency(int? amount) {
    if (amount == null || amount <= 0) return 'Undisclosed';
    if (amount >= 1000000000) {
      final val = (amount / 1000000000)
          .toStringAsFixed(1)
          .replaceFirst(RegExp(r'\.0$'), '');
      return '\$$val Billion';
    }
    if (amount >= 1000000) {
      final val = (amount / 1000000)
          .toStringAsFixed(1)
          .replaceFirst(RegExp(r'\.0$'), '');
      return '\$$val Million';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$$amount';
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
