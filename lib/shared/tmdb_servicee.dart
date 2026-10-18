import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sparrow/shared/api.dart';
import 'package:sparrow/shared/genre_ids.dart';

class TmdbService {
  Future<List<dynamic>> fetchMovies(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/$endpoint'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        return getGenre(json['results'] ?? []);
      } else {
        //debugPrintt('TMDB error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      //debugPrintt('TMDB error: $e');
      return [];
    }
  }

  List<dynamic> getGenre(List<dynamic> movies) {
    return movies.map((movie) {
      final genreNames = (movie['genre_ids'] as List<dynamic>? ?? [])
          .map((id) => genres[id])
          .where((name) => name != null)
          .toList();

      return {...movie, 'genre': genreNames};
    }).toList();
  }

  /// Search movies on TMDB with proper query encoding and error handling.
  Future<List<dynamic>> searchMovies(String query, {int page = 1}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    try {
      final endpoint =
          'search/movie?query=${Uri.encodeComponent(clean)}&include_adult=false&language=en-US&page=$page';
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/$endpoint'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return getGenre(json['results'] ?? []);
      } else {
        //debugPrintt('TMDB search error: ${response.statusCode}');
        throw Exception(
          'Search request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      //debugPrintt('TMDB search error: $e');
      rethrow;
    }
  }

  /// Search TV shows on TMDB with proper query encoding and error handling.
  Future<List<dynamic>> searchTvShows(String query, {int page = 1}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    try {
      final endpoint =
          'search/tv?query=${Uri.encodeComponent(clean)}&include_adult=false&language=en-US&page=$page';
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/$endpoint'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return getGenre(json['results'] ?? []);
      } else {
        //debugPrintt('TMDB TV search error: ${response.statusCode}');
        throw Exception(
          'TV Search request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      //debugPrintt('TMDB TV search error: $e');
      rethrow;
    }
  }

  /// Discover movies by genre ID from TMDB.
  Future<List<dynamic>> fetchByGenre(int genreId, {int page = 1}) async {
    try {
      final endpoint =
          'discover/movie?with_genres=$genreId&sort_by=popularity.desc&include_adult=false&language=en-US&page=$page';
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/$endpoint'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return getGenre(json['results'] ?? []);
      } else {
        //debugPrintt('TMDB genre error: ${response.statusCode}');
        throw Exception(
          'Genre request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      //debugPrintt('TMDB genre error: $e');
      rethrow;
    }
  }

  /// Fetch full movie details by TMDB movie ID.
  Future<Map<String, dynamic>?> fetchMovieDetails(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/$cleanId?language=en-US'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        // //debugPrintt("movie detaisl = ${response.body}");
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        //debugPrintt('TMDB details error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      //debugPrintt('TMDB details error: $e');
      return null;
    }
  }

  /// Fetch movie credits (cast and crew) by TMDB movie ID.
  Future<Map<String, dynamic>?> fetchMovieCredits(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/movie/$cleanId/credits?language=en-US',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        //debugPrintt('TMDB credits error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      //debugPrintt('TMDB credits error: $e');
      return null;
    }
  }

  /// Fetch similar movies or recommendations by TMDB movie ID.
  Future<List<dynamic>> fetchSimilarMovies(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return [];
    try {
      // Recommendations usually provide higher quality curated similar titles
      final recResponse = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/movie/$cleanId/recommendations?language=en-US&page=1',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (recResponse.statusCode == 200) {
        final json = jsonDecode(recResponse.body);
        final list = (json['results'] as List<dynamic>? ?? []);
        if (list.isNotEmpty) {
          return getGenre(list);
        }
      }

      // Fallback to similar endpoint
      final simResponse = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/movie/$cleanId/similar?language=en-US&page=1',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (simResponse.statusCode == 200) {
        final json = jsonDecode(simResponse.body);
        return getGenre(json['results'] as List<dynamic>? ?? []);
      }
      return [];
    } catch (e) {
      //debugPrintt('TMDB similar movies error: $e');
      return [];
    }
  }

  /// Fetch full TV show details by TMDB series ID.
  Future<Map<String, dynamic>?> fetchTvShowDetails(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/$cleanId?language=en-US'),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        //debugPrintt('TMDB TV details error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      //debugPrintt('TMDB TV details error: $e');
      return null;
    }
  }

  /// Fetch TV show credits (cast and crew) by TMDB series ID.
  Future<Map<String, dynamic>?> fetchTvShowCredits(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/$cleanId/credits?language=en-US',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        //debugPrintt('TMDB TV credits error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      //debugPrintt('TMDB TV credits error: $e');
      return null;
    }
  }

  /// Fetch TV season details including all episodes by series ID and season number.
  Future<Map<String, dynamic>?> fetchTvSeasonDetails(
    String seriesId,
    int seasonNumber,
  ) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/$cleanId/season/$seasonNumber?language=en-US',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        //debugPrintt('TMDB TV season error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      //debugPrintt('TMDB TV season error: $e');
      return null;
    }
  }

  /// Fetch similar TV shows or recommendations by TMDB series ID.
  Future<List<dynamic>> fetchSimilarTvShows(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return [];
    try {
      final recResponse = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/$cleanId/recommendations?language=en-US&page=1',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (recResponse.statusCode == 200) {
        final json = jsonDecode(recResponse.body);
        final list = (json['results'] as List<dynamic>? ?? []);
        if (list.isNotEmpty) {
          return getGenre(list);
        }
      }

      final simResponse = await http.get(
        Uri.parse(
          'https://api.themoviedb.org/3/tv/$cleanId/similar?language=en-US&page=1',
        ),
        headers: {'Authorization': tokenAuth},
      );

      if (simResponse.statusCode == 200) {
        final json = jsonDecode(simResponse.body);
        return getGenre(json['results'] as List<dynamic>? ?? []);
      }
      return [];
    } catch (e) {
      //debugPrintt('TMDB similar TV shows error: $e');
      return [];
    }
  }
}
