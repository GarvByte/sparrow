import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';

/// Centralized navigation helper to open the TV Show Details ("About TV Show") page.
///
/// Accepts a [MediaItem] or a raw TMDB [Map<String, dynamic>] safely.
/// Uses GoRouter's [push] method so the details screen is pushed above the current
/// stack without resetting the previous page's scroll or navigation state.
Future<T?> openTvShowDetails<T>(BuildContext context, dynamic tvData) {
  FocusScope.of(context).unfocus();
  FocusManager.instance.primaryFocus?.unfocus();

  if (tvData == null) {
    //debugPrintt('Cannot navigate to TV Show Details: tvData is null');
    return Future.value(null);
  }

  MediaItem? resolvedItem;

  if (tvData is MediaItem) {
    resolvedItem = MediaItem(
      id: tvData.id,
      title: tvData.title,
      imageUrl: tvData.imageUrl,
      genres: tvData.genres,
      rating: tvData.rating,
      ratingCount: tvData.ratingCount,
      rank: tvData.rank,
      topBadge: tvData.topBadge,
      topBadgeIsPrimary: tvData.topBadgeIsPrimary,
      bottomBadge: tvData.bottomBadge,
      durationLeft: tvData.durationLeft,
      progress: tvData.progress,
      aspectRatio: tvData.aspectRatio,
      isOriginal: tvData.isOriginal,
      overview: tvData.overview,
      releaseDate: tvData.releaseDate,
      backdropUrl: tvData.backdropUrl,
      isAdult: tvData.isAdult,
      mediaType: 'tv',
    );
  } else if (tvData is Map<String, dynamic>) {
    final rawId = tvData['id']?.toString() ?? '';
    if (rawId.isEmpty) {
      //debugPrintt('Cannot navigate to TV Show Details: series ID is missing');
      return Future.value(null);
    }

    final posterPath = tvData['poster_path'] as String?;
    final backdropPath = tvData['backdrop_path'] as String?;

    resolvedItem = MediaItem(
      id: rawId,
      title: (tvData['name'] ?? tvData['title'] ?? 'Untitled').toString(),
      imageUrl: posterPath != null && posterPath.isNotEmpty
          ? '$imageBaseUrl$posterPath'
          : (backdropPath != null && backdropPath.isNotEmpty
                ? '$imageBaseUrl$backdropPath'
                : ''),
      genres: tvData['genre'] is List ? (tvData['genre'] as List) : [],
      rating: (tvData['vote_average'] as num?)?.toDouble(),
      ratingCount: tvData['vote_count']?.toString(),
      overview: tvData['overview'] as String?,
      releaseDate:
          (tvData['first_air_date'] ?? tvData['release_date']) as String?,
      isAdult: tvData['adult'] as bool? ?? false,
      backdropUrl: backdropPath != null && backdropPath.isNotEmpty
          ? '$imageBaseUrl2$backdropPath'
          : null,
      mediaType: 'tv',
    );
  } else if (tvData is String && tvData.isNotEmpty) {
    resolvedItem = MediaItem(
      id: tvData,
      title: 'Loading...',
      imageUrl: '',
      genres: const [],
      mediaType: 'tv',
    );
  }

  if (resolvedItem == null || resolvedItem.id.trim().isEmpty) {
    //debugPrintt('Cannot navigate to TV Show Details: invalid series identifier');
    return Future.value(null);
  }

  return context.push<T>('/tv-show-details', extra: resolvedItem);
}
