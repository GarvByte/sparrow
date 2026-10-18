/// Model representing a cast member in TV show credits.
class TvCastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  const TvCastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  String get profileUrl => profilePath != null && profilePath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : '';

  factory TvCastMember.fromJson(Map<String, dynamic> json) {
    return TvCastMember(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? 'Unknown Actor').toString(),
      character: (json['character'] ?? '').toString(),
      profilePath: json['profile_path'] as String?,
    );
  }
}
