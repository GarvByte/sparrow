import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// Centralized navigation helper to open the Movie Details ("About Movie") page.
///
/// Accepts [MediaItem] or a raw TMDB [Map<String, dynamic>] safely.
/// Uses GoRouter's [push] method so the details screen is pushed above the current
/// stack without resetting the previous page's scroll or navigation state.
void openMovieDetails(BuildContext context, dynamic movieData) {
  FocusScope.of(context).unfocus();
  FocusManager.instance.primaryFocus?.unfocus();

  if (movieData == null) {
    //debugPrintt('Cannot navigate to Movie Details: movieData is null');
    return;
  }

  // Intercept TV shows and route cleanly to TV Show Details
  if (movieData is MediaItem && movieData.isTvShow) {
    openTvShowDetails(context, movieData);
    return;
  }
  if (movieData is Map<String, dynamic> &&
      (movieData['media_type'] == 'tv' || movieData['is_tv'] == true)) {
    openTvShowDetails(context, movieData);
    return;
  }

  MediaItem? resolvedItem;

  if (movieData is MediaItem) {
    resolvedItem = movieData;
  } else if (movieData is Map<String, dynamic>) {
    final rawId = movieData['id']?.toString() ?? '';
    if (rawId.isEmpty) {
      //debugPrintt('Cannot navigate to Movie Details: movie ID is missing');
      return;
    }

    final posterPath = movieData['poster_path'] as String?;
    final backdropPath = movieData['backdrop_path'] as String?;

    resolvedItem = MediaItem(
      id: rawId,
      title: (movieData['title'] ?? movieData['name'] ?? 'Untitled').toString(),
      imageUrl: posterPath != null && posterPath.isNotEmpty
          ? '$imageBaseUrl$posterPath'
          : (backdropPath != null && backdropPath.isNotEmpty
                ? '$imageBaseUrl$backdropPath'
                : ''),
      genres: movieData['genre'] is List ? (movieData['genre'] as List) : [],
      rating: (movieData['vote_average'] as num?)?.toDouble(),
      ratingCount: movieData['vote_count']?.toString(),
      overview: movieData['overview'] as String?,
      releaseDate: movieData['release_date'] as String?,
      isAdult: movieData['adult'] as bool? ?? false,
      backdropUrl: backdropPath != null && backdropPath.isNotEmpty
          ? '$imageBaseUrl2$backdropPath'
          : null,
    );
  } else if (movieData is String && movieData.isNotEmpty) {
    resolvedItem = MediaItem(
      id: movieData,
      title: 'Loading...',
      imageUrl: '',
      genres: const [],
    );
  }

  if (resolvedItem == null || resolvedItem.id.trim().isEmpty) {
    //debugPrintt('Cannot navigate to Movie Details: invalid movie identifier');
    return;
  }

  context.push('/movie-details', extra: resolvedItem);
}
