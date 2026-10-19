import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/media_item.dart';

class GenreHeroBannerItem {
  final int genreId;
  final String genreName;
  final MediaItem movie;

  const GenreHeroBannerItem({
    required this.genreId,
    required this.genreName,
    required this.movie,
  });
}

/// Encapsulates the single randomly selected genre and all valid movies from Page 1.
class SearchRandomGenreSection {
  final int genreId;
  final String genreName;
  final List<MediaItem> movies;

  const SearchRandomGenreSection({
    required this.genreId,
    required this.genreName,
    required this.movies,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchRandomGenreSection &&
          runtimeType == other.runtimeType &&
          genreId == other.genreId &&
          genreName == other.genreName &&
          movies.length == other.movies.length;

  @override
  int get hashCode =>
      genreId.hashCode ^ genreName.hashCode ^ movies.length.hashCode;
}

class SearchGenreBannersNotifier
    extends AsyncNotifier<SearchRandomGenreSection> {
  @override
  Future<SearchRandomGenreSection> build() async {
    return _generateRandomGenreSection();
  }

  Future<SearchRandomGenreSection> _generateRandomGenreSection() async {
    final service = ref.watch(tmdbServiceProvider);

    // 1. Fetch available TMDB movie genres
    var genres = await service.fetchMovieGenres();
    List<TmdbGenre> genreList = [];
    if (genres.isNotEmpty) {
      genreList = genres.map(TmdbGenre.fromJson).toList();
    } else {
      genreList = List.of(fallbackMovieGenres);
    }

    // Exclude TV Movie (10770) or empty genre names
    genreList = genreList
        .where((g) => g.id != 10770 && g.name.trim().isNotEmpty)
        .toList();

    if (genreList.isEmpty) {
      genreList = List.of(fallbackMovieGenres);
    }

    // 2. Randomly shuffle and select EXACTLY ONE genre
    final random = Random();
    genreList.shuffle(random);

    for (final selectedGenre in genreList) {
      try {
        // Fetch ONLY Page 1 of movies for this selected genre
        final rawResults = await service.fetchByGenre(selectedGenre.id, page: 1);
        final mappedMovies = rawResults.map(mapMovieJsonToMediaItem).toList();

        // Collect all valid, non-duplicate movies returned by Page 1
        final validMovies = <MediaItem>[];
        final seenIds = <String>{};

        for (final m in mappedMovies) {
          if (m.id.isNotEmpty &&
              m.title.isNotEmpty &&
              !seenIds.contains(m.id) &&
              (m.imageUrl.isNotEmpty ||
                  (m.backdropUrl != null && m.backdropUrl!.isNotEmpty))) {
            seenIds.add(m.id);
            validMovies.add(m);
          }
        }

        if (validMovies.isNotEmpty) {
          return SearchRandomGenreSection(
            genreId: selectedGenre.id,
            genreName: selectedGenre.name,
            movies: validMovies,
          );
        }
      } catch (_) {
        // Retry next genre in shuffled list if error
        continue;
      }
    }

    // Fallback if network completely unavailable
    return const SearchRandomGenreSection(
      genreId: 28,
      genreName: 'Action',
      movies: [],
    );
  }

  Future<void> refreshSection() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _generateRandomGenreSection());
  }
}

/// Provider managing session-stable single random genre section with full Page 1 movies.
final searchGenreBannersProvider =
    AsyncNotifierProvider<SearchGenreBannersNotifier, SearchRandomGenreSection>(
  () => SearchGenreBannersNotifier(),
);
