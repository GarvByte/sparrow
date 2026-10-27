import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/playback_context.dart';
import '../models/resolved_source.dart';
import '../models/server_item.dart';
import '../services/nxsha_api_service.dart';
import '../services/stream_cache_service.dart';

/// Repository coordinating server and source resolution, in-flight deduplication,
/// and 1-hour persistent caching.
class StreamRepository {
  final NxshaApiService _apiService;

  StreamRepository({NxshaApiService? apiService})
      : _apiService = apiService ?? NxshaApiService();

  // Deduplication maps for concurrent in-flight requests
  final Map<String, Future<List<ServerItem>>> _inFlightServerRequests = {};
  final Map<String, Future<List<ResolvedSource>>> _inFlightSourceRequests = {};

  /// Resolves the list of supported servers for [context].
  ///
  /// Checks the 1-hour Hive cache first.
  /// If an in-flight request is already running for this context, reuses it.
  Future<List<ServerItem>> getServers(
    PlaybackContext context, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = StreamCacheService.buildServerKey(context);

    // 1. Check Cache if not forcing refresh
    if (!forceRefresh) {
      final cached = await StreamCacheService.getCachedServers(context);
      if (cached != null && cached.isNotEmpty) {
        final servers = cached
            .map((e) => ServerItem.fromJson(e))
            .where((s) => s.webSupport)
            .toList();
        if (servers.isNotEmpty) {
          debugPrint('StreamRepository: Serving ${servers.length} servers from cache for key: $cacheKey');
          return servers;
        }
      }
    }

    // 2. Check in-flight requests
    final inFlight = _inFlightServerRequests[cacheKey];
    if (inFlight != null) {
      debugPrint('StreamRepository: Reusing in-flight server request for $cacheKey');
      return inFlight;
    }

    // 3. Initiate network request with deduplication
    final future = _fetchAndCacheServers(context, cacheKey);
    _inFlightServerRequests[cacheKey] = future;

    try {
      return await future;
    } finally {
      _inFlightServerRequests.remove(cacheKey);
    }
  }

  Future<List<ServerItem>> _fetchAndCacheServers(
    PlaybackContext context,
    String cacheKey,
  ) async {
    try {
      final servers = await _apiService.fetchServers(context);
      if (servers.isNotEmpty) {
        final jsonList = servers.map((s) => s.toJson()).toList();
        await StreamCacheService.saveCachedServers(context, jsonList);
      }
      return servers;
    } catch (e) {
      debugPrint('StreamRepository: Error fetching servers: $e');
      rethrow;
    }
  }

  /// Resolves streaming sources for a specific server [scraper].
  ///
  /// Checks 1-hour cache first and deduplicates in-flight requests.
  Future<List<ResolvedSource>> getSources(
    PlaybackContext context,
    String scraper, {
    bool forceRefresh = false,
  }) async {
    final cleanScraper = scraper.trim();
    final cacheKey = StreamCacheService.buildSourceKey(context, cleanScraper);

    // 1. Check Cache
    if (!forceRefresh) {
      final cached = await StreamCacheService.getCachedSources(
        context,
        cleanScraper,
      );
      if (cached != null && cached.isNotEmpty) {
        final sources = cached
            .map((e) => ResolvedSource.fromJson(e, defaultProvider: cleanScraper))
            .where((s) => s.isValidUrl && s.isSupportedLanguage)
            .toList();
        if (sources.isNotEmpty) {
          debugPrint('StreamRepository: Serving ${sources.length} sources from cache for $cacheKey');
          return sources;
        }
      }
    }

    // 2. Check in-flight requests
    final inFlight = _inFlightSourceRequests[cacheKey];
    if (inFlight != null) {
      debugPrint('StreamRepository: Reusing in-flight source request for $cacheKey');
      return inFlight;
    }

    // 3. Initiate network request
    final future = _fetchAndCacheSources(context, cleanScraper);
    _inFlightSourceRequests[cacheKey] = future;

    try {
      return await future;
    } finally {
      _inFlightSourceRequests.remove(cacheKey);
    }
  }

  Future<List<ResolvedSource>> _fetchAndCacheSources(
    PlaybackContext context,
    String scraper,
  ) async {
    try {
      final sources = await _apiService.fetchSources(context, scraper);
      if (sources.isNotEmpty) {
        final jsonList = sources.map((s) => s.toJson()).toList();
        await StreamCacheService.saveCachedSources(context, scraper, jsonList);
      }
      return sources;
    } catch (e) {
      debugPrint('StreamRepository: Error fetching sources for $scraper: $e');
      rethrow;
    }
  }
}
