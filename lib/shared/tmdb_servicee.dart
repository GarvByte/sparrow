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
        debugPrint('TMDB error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('TMDB error: $e');
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
        debugPrint('TMDB search error: ${response.statusCode}');
        throw Exception(
          'Search request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('TMDB search error: $e');
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
        debugPrint('TMDB genre error: ${response.statusCode}');
        throw Exception(
          'Genre request failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('TMDB genre error: $e');
      rethrow;
    }
  }
}
