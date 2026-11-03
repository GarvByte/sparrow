class ViewAllArgs {
  final String mediaType; // 'movie' or 'tv'
  final String categoryType; // 'genre', 'trending', 'popular', 'top_rated', 'on_the_air'
  final String title;
  final int? genreId;

  const ViewAllArgs({
    required this.mediaType,
    required this.categoryType,
    required this.title,
    this.genreId,
  });

  bool get isTv => mediaType == 'tv';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewAllArgs &&
          runtimeType == other.runtimeType &&
          mediaType == other.mediaType &&
          categoryType == other.categoryType &&
          genreId == other.genreId;

  @override
  int get hashCode => Object.hash(mediaType, categoryType, genreId);
}
