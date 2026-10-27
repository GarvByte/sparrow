import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playback_context.dart';

/// Hive-backed persistent cache for decoded server lists and resolved sources
/// with a 1-hour expiration policy and strict request-identity validation.
class StreamCacheService {
  static const String boxName = 'sparrow_stream_cache_box';
  static const Duration cacheTtl = Duration(hours: 1);
  static bool _initialized = false;

  /// Initializes the cache box safely.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      _initialized = true;
    } catch (e, stack) {
      debugPrint('StreamCacheService.init error: $e\n$stack');
    }
  }

  static Future<Box?> _openBox() async {
    if (!_initialized) return null;
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      return await Hive.openBox(boxName);
    } catch (e) {
      // Handles uninitialized Hive gracefully (e.g. in widget test environments)
      return null;
    }
  }

  /// Builds a deterministic, collision-safe cache key for the server list.
  static String buildServerKey(PlaybackContext context) {
    return 'servers_${context.type}_tmdb_${context.tmdbId}_s${context.season}_e${context.episode}';
  }

  /// Builds a deterministic, collision-safe cache key for resolved sources of a provider.
  static String buildSourceKey(PlaybackContext context, String scraper) {
    return 'sources_${context.type}_tmdb_${context.tmdbId}_s${context.season}_e${context.episode}_${scraper.toLowerCase().trim()}';
  }

  /// Retrieves cached servers if present, not expired, and exactly matching context identity.
  static Future<List<Map<String, dynamic>>?> getCachedServers(
    PlaybackContext context,
  ) async {
    try {
      final box = await _openBox();
      if (box == null) return null;

      final key = buildServerKey(context);
      final raw = box.get(key);
      if (raw == null || raw is! Map) return null;

      final int? timestamp = raw['timestamp'] as int?;
      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > cacheTtl.inMilliseconds) {
        // Expired
        await box.delete(key);
        return null;
      }

      // Step 3: Validate stored request identity against current context
      final storedTmdbId = raw['tmdbId']?.toString();
      final storedType = raw['type']?.toString();
      final storedSeason = raw['season'] as int?;
      final storedEpisode = raw['episode'] as int?;

      if (storedTmdbId != context.tmdbId ||
          storedType != context.type ||
          storedSeason != context.season ||
          storedEpisode != context.episode) {
        debugPrint(
          'StreamCacheService: Server cache identity mismatch! Expected TMDB=${context.tmdbId}, Found TMDB=$storedTmdbId. Purging.',
        );
        await box.delete(key);
        return null;
      }

      final data = raw['data'];
      if (data is List && data.isNotEmpty) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('StreamCacheService.getCachedServers error: $e');
      return null;
    }
  }

  /// Persists a decoded server list with metadata for identity validation.
  static Future<void> saveCachedServers(
    PlaybackContext context,
    List<Map<String, dynamic>> servers,
  ) async {
    if (servers.isEmpty) return;
    try {
      final box = await _openBox();
      if (box == null) return;

      final key = buildServerKey(context);
      await box.put(key, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'tmdbId': context.tmdbId,
        'imdbId': context.imdbId,
        'type': context.type,
        'season': context.season,
        'episode': context.episode,
        'data': servers,
      });
    } catch (e) {
      debugPrint('StreamCacheService.saveCachedServers error: $e');
    }
  }

  /// Retrieves cached sources for a given provider if not expired and identity matches.
  static Future<List<Map<String, dynamic>>?> getCachedSources(
    PlaybackContext context,
    String scraper,
  ) async {
    try {
      final box = await _openBox();
      if (box == null) return null;

      final cleanScraper = scraper.toLowerCase().trim();
      final key = buildSourceKey(context, cleanScraper);
      final raw = box.get(key);
      if (raw == null || raw is! Map) return null;

      final int? timestamp = raw['timestamp'] as int?;
      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > cacheTtl.inMilliseconds) {
        await box.delete(key);
        return null;
      }

      // Step 3: Validate stored request identity against current context & provider
      final storedTmdbId = raw['tmdbId']?.toString();
      final storedType = raw['type']?.toString();
      final storedSeason = raw['season'] as int?;
      final storedEpisode = raw['episode'] as int?;
      final storedProvider = raw['provider']?.toString().toLowerCase().trim();

      if (storedTmdbId != context.tmdbId ||
          storedType != context.type ||
          storedSeason != context.season ||
          storedEpisode != context.episode ||
          storedProvider != cleanScraper) {
        debugPrint(
          'StreamCacheService: Source cache identity mismatch! Expected TMDB=${context.tmdbId}, provider=$cleanScraper. Found TMDB=$storedTmdbId, provider=$storedProvider. Purging.',
        );
        await box.delete(key);
        return null;
      }

      final data = raw['data'];
      if (data is List && data.isNotEmpty) {
        final parsed = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) => (m['url'] ?? m['file'])?.toString().isNotEmpty ?? false)
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
      return null;
    } catch (e) {
      debugPrint('StreamCacheService.getCachedSources error: $e');
      return null;
    }
  }

  /// Persists decoded sources with request identity metadata.
  static Future<void> saveCachedSources(
    PlaybackContext context,
    String scraper,
    List<Map<String, dynamic>> sources,
  ) async {
    if (sources.isEmpty) return;
    try {
      final box = await _openBox();
      if (box == null) return;

      final cleanScraper = scraper.toLowerCase().trim();
      final key = buildSourceKey(context, cleanScraper);
      await box.put(key, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'tmdbId': context.tmdbId,
        'imdbId': context.imdbId,
        'type': context.type,
        'season': context.season,
        'episode': context.episode,
        'provider': cleanScraper,
        'data': sources,
      });
    } catch (e) {
      debugPrint('StreamCacheService.saveCachedSources error: $e');
    }
  }
}
