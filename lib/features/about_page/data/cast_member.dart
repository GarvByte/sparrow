/// Model representing a cast member in movie credits.
class CastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  String get profileUrl => profilePath != null && profilePath!.isNotEmpty
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : '';

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? 'Unknown Actor').toString(),
      character: (json['character'] ?? '').toString(),
      profilePath: json['profile_path'] as String?,
    );
  }
}
