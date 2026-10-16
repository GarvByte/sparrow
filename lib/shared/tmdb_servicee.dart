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

      return {
        ...movie,
        'genre': genreNames,
      };
    }).toList();
  }
}