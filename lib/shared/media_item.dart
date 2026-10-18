class MediaItem {
  final String id;
  final String title;
  final String imageUrl;
  final List genres;
  final double? rating;
  final String? ratingCount;
  final int? rank;
  final String? topBadge;
  final bool topBadgeIsPrimary;
  final String? bottomBadge;
  final String? durationLeft;
  final double? progress; // 0.0 to 1.0
  final double aspectRatio;
  final bool isOriginal;
  final String? overview;
  final String? releaseDate;
  final String? backdropUrl;
  final bool isAdult;
  final String mediaType;

  const MediaItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.genres,
    this.rating,
    this.ratingCount,
    this.rank,
    this.topBadge,
    this.topBadgeIsPrimary = false,
    this.bottomBadge,
    this.durationLeft,
    this.progress,
    this.aspectRatio = 2 / 3,
    this.isOriginal = false,
    this.overview,
    this.releaseDate,
    this.backdropUrl,
    this.isAdult = false,
    this.mediaType = 'movie',
  });

  bool get isTvShow => mediaType == 'tv';
}
