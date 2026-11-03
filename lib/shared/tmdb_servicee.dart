import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/shared/api.dart';
import 'package:sparrow/shared/genre_ids.dart';

class TmdbService {
  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? _defaultClient;

  static final http.Client _defaultClient = http.Client();
  static final Map<String, Future<http.Response>> _inFlightGetRequests = {};

  /// Determines whether an error or HTTP status code is a temporary/transient failure
  /// that warrants a bounded retry.
  bool _isTransientError(Object e, [int? statusCode]) {
    if (statusCode != null &&
        (statusCode == 429 ||
            statusCode == 502 ||
            statusCode == 503 ||
            statusCode == 504)) {
      return true;
    }
    if (e is TimeoutException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection reset') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('network is unreachable') ||
        msg.contains('timed out');
  }

  /// Sends an HTTP GET request with a bounded retry mechanism for transient network
  /// failures (e.g., Connection reset by peer, rate limits, timeouts).
  /// Deduplicates simultaneous in-flight requests for the exact same URI.
  Future<http.Response> _getWithRetry(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
    int maxAttempts = 3,
  }) {
    final key = uri.toString();
    final existing = _inFlightGetRequests[key];
    if (existing != null) {
      return existing;
    }

    final future =
        _executeGetWithRetry(
          uri,
          headers: headers,
          timeout: timeout,
          maxAttempts: maxAttempts,
        ).whenComplete(() {
          _inFlightGetRequests.remove(key);
        });

    _inFlightGetRequests[key] = future;
    return future;
  }

  Future<http.Response> _executeGetWithRetry(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 12),
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await _client
            .get(uri, headers: headers)
            .timeout(timeout);
        if (_isTransientError(response, response.statusCode) &&
            attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        return response;
      } catch (e) {
        if (_isTransientError(e) && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }

  /// Fetches movies or shows from a TMDB endpoint with automatic transient retry.
  Future<List<dynamic>> fetchMovies(String endpoint) async {
    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
      ),
    
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return getGenre(json['results'] ?? []);
    } else {
      throw http.ClientException(
        'TMDB fetch failed with status ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
        ),
      );
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

    final endpoint =
        'search/movie?query=${Uri.encodeComponent(clean)}&include_adult=false&language=en-US&page=$page';
    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
      ),
    
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return getGenre(json['results'] ?? []);
    } else {
      throw http.ClientException(
        'Search request failed with status ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
        ),
      );
    }
  }

  /// Search TV shows on TMDB with proper query encoding and error handling.
  Future<List<dynamic>> searchTvShows(String query, {int page = 1}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final endpoint =
        'search/tv?query=${Uri.encodeComponent(clean)}&include_adult=false&language=en-US&page=$page';
    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
      ),
    
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return getGenre(json['results'] ?? []);
    } else {
      throw http.ClientException(
        'TV Search request failed with status ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
        ),
      );
    }
  }

  /// Discover movies by genre ID from TMDB.
  Future<List<dynamic>> fetchByGenre(int genreId, {int page = 1}) async {
    final endpoint =
        'discover/movie?with_genres=$genreId&sort_by=popularity.desc&include_adult=false&language=en-US&page=$page';
    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
      ),
    
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return getGenre(json['results'] ?? []);
    } else {
      throw http.ClientException(
        'Genre request failed with status ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
        ),
      );
    }
  }

  /// Discover TV shows by genre ID from TMDB.
  Future<List<dynamic>> fetchTvByGenre(int genreId, {int page = 1}) async {
    final endpoint =
        'discover/tv?with_genres=$genreId&sort_by=popularity.desc&include_adult=false&language=en-US&page=$page';
    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
      ),
    
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return getGenre(json['results'] ?? []);
    } else {
      throw http.ClientException(
        'TV Genre request failed with status ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/$endpoint',
        ),
      );
    }
  }

  /// Fetch full list of official TMDB movie genres.
  Future<List<Map<String, dynamic>>> fetchMovieGenres() async {
    try {
      final response = await _getWithRetry(
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/genre/movie/list?language=en-US',
        ),
      
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['genres'] as List<dynamic>? ?? []);
        return list.map((g) => Map<String, dynamic>.from(g as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch full list of official TMDB TV genres.
  Future<List<Map<String, dynamic>>> fetchTvGenres() async {
    try {
      final response = await _getWithRetry(
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/genre/tv/list?language=en-US',
        ),
      
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['genres'] as List<dynamic>? ?? []);
        return list.map((g) => Map<String, dynamic>.from(g as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch full movie details by TMDB movie ID.
  Future<Map<String, dynamic>?> fetchMovieDetails(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw http.ClientException(
        'TMDB details error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId?language=en-US',
        ),
      );
    }
  }

  /// Fetch movie credits (cast and crew) by TMDB movie ID.
  Future<Map<String, dynamic>?> fetchMovieCredits(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId/credits?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw http.ClientException(
        'TMDB credits error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId/credits?language=en-US',
        ),
      );
    }
  }

  /// Fetch similar movies or recommendations by TMDB movie ID.
  Future<List<dynamic>> fetchSimilarMovies(String movieId) async {
    final cleanId = movieId.trim();
    if (cleanId.isEmpty) return [];

    // Recommendations usually provide higher quality curated similar titles
    try {
      final recResponse = await _getWithRetry(
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId/recommendations?language=en-US&page=1',
        ),
      
      );

      if (recResponse.statusCode == 200) {
        final json = jsonDecode(recResponse.body);
        final list = (json['results'] as List<dynamic>? ?? []);
        if (list.isNotEmpty) {
          return getGenre(list);
        }
      }
    } catch (_) {
      // Recommendations failed; proceed to similar endpoint fallback
    }

    // Fallback to similar endpoint
    final simResponse = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId/similar?language=en-US&page=1',
      ),
    
    );

    if (simResponse.statusCode == 200) {
      final json = jsonDecode(simResponse.body);
      return getGenre(json['results'] as List<dynamic>? ?? []);
    }

    throw http.ClientException(
      'TMDB similar movies error: ${simResponse.statusCode}',
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/movie/$cleanId/similar?language=en-US&page=1',
      ),
    );
  }

  /// Fetch full TV show details by TMDB series ID.
  Future<Map<String, dynamic>?> fetchTvShowDetails(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw http.ClientException(
        'TMDB TV details error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId?language=en-US',
        ),
      );
    }
  }

  /// Fetch TV show credits (cast and crew) by TMDB series ID.
  Future<Map<String, dynamic>?> fetchTvShowCredits(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/credits?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw http.ClientException(
        'TMDB TV credits error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/credits?language=en-US',
        ),
      );
    }
  }

  /// Fetch TV season details including all episodes by series ID and season number.
  Future<Map<String, dynamic>?> fetchTvSeasonDetails(
    String seriesId,
    int seasonNumber,
  ) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/season/$seasonNumber?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (!kIsWeb && body.length > 50000) {
        return Isolate.run(() => jsonDecode(body) as Map<String, dynamic>);
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw http.ClientException(
        'TMDB TV season error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/season/$seasonNumber?language=en-US',
        ),
      );
    }
  }

  /// Fetch and parse TV season details including all episodes, using background isolate for large payloads.
  Future<TvSeasonDetail?> fetchAndParseTvSeasonDetail(
    String seriesId,
    int seasonNumber,
  ) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return null;

    final response = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/season/$seasonNumber?language=en-US',
      ),
    
    );

    if (response.statusCode == 200) {
      final body = response.body;
      if (!kIsWeb && body.length > 50000) {
        return Isolate.run(() {
          final json = jsonDecode(body) as Map<String, dynamic>;
          return TvSeasonDetail.fromJson(json);
        });
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      return TvSeasonDetail.fromJson(json);
    } else {
      throw http.ClientException(
        'TMDB TV season error: ${response.statusCode}',
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/season/$seasonNumber?language=en-US',
        ),
      );
    }
  }

  /// Fetch similar TV shows or recommendations by TMDB series ID.
  Future<List<dynamic>> fetchSimilarTvShows(String seriesId) async {
    final cleanId = seriesId.trim();
    if (cleanId.isEmpty) return [];

    try {
      final recResponse = await _getWithRetry(
        Uri.parse(
          'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/recommendations?language=en-US&page=1',
        ),
      
      );

      if (recResponse.statusCode == 200) {
        final json = jsonDecode(recResponse.body);
        final list = (json['results'] as List<dynamic>? ?? []);
        if (list.isNotEmpty) {
          return getGenre(list);
        }
      }
    } catch (_) {
      // Recommendations failed; proceed to similar endpoint fallback
    }

    final simResponse = await _getWithRetry(
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/similar?language=en-US&page=1',
      ),
    
    );

    if (simResponse.statusCode == 200) {
      final json = jsonDecode(simResponse.body);
      return getGenre(json['results'] as List<dynamic>? ?? []);
    }

    throw http.ClientException(
      'TMDB similar TV shows error: ${simResponse.statusCode}',
      Uri.parse(
        'https://sparrow-tmdb-proxy.piratesparrow.workers.dev/3/tv/$cleanId/similar?language=en-US&page=1',
      ),
    );
  }
}
