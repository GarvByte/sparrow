import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/playback_context.dart';
import '../models/resolved_source.dart';
import '../models/server_item.dart';
import 'key_config_manager.dart';
import 'key_config_models.dart';
import 'nxsha_cipher.dart';

/// Service responsible for communicating with `nxsha.space` APIs:
/// fetching the server list and resolving streaming sources for providers.
class NxshaApiService {
  final http.Client _client;
  final KeyConfigManager _keyConfigManager;

  NxshaApiService({
    http.Client? client,
    KeyConfigManager? keyConfigManager,
  })  : _client = client ?? http.Client(),
        _keyConfigManager = keyConfigManager ?? KeyConfigManager.instance;

  static const String _baseUrl = 'https://nxsha.space/api';
  static const String _referer = 'https://nxsha.space/';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Map<String, String> get _headers => {
        'Referer': _referer,
        'User-Agent': _userAgent,
        'Accept': 'application/json, text/plain, */*',
      };

  /// Fetches the server list for a given [PlaybackContext].
  /// On cryptographic decoding failure, automatically attempts a single key refresh & retry.
  Future<List<ServerItem>> fetchServers(
    PlaybackContext context, {
    Duration timeout = const Duration(seconds: 12),
    bool isRetry = false,
  }) async {
    final KeyConfig configSnapshot;
    try {
      configSnapshot = _keyConfigManager.acquireConfig();
    } catch (_) {
      rethrow;
    }

    try {
      return await _executeFetchServers(
        context,
        configSnapshot,
        timeout: timeout,
      );
    } on CryptoDecodingException {
      if (!isRetry) {
        debugPrint(
          'NxshaApiService: Crypto decoding failed on fetchServers. Attempting key recovery...',
        );
        final refreshResult = await _keyConfigManager.forceRefresh();
        if (refreshResult == KeyRefreshResult.updated) {
          debugPrint(
            'NxshaApiService: Key rotated after failure. Retrying fetchServers once...',
          );
          return await fetchServers(context, timeout: timeout, isRetry: true);
        }
      }
      throw const CryptoDecodingException('Decoding algorithm failed');
    } finally {
      _keyConfigManager.releaseConfig(configSnapshot);
    }
  }

  Future<List<ServerItem>> _executeFetchServers(
    PlaybackContext context,
    KeyConfig configSnapshot, {
    required Duration timeout,
  }) async {
    final qValue = NxshaCipher.buildPayload(
      tmdbId: context.tmdbId,
      imdbId: context.imdbId,
      type: context.type,
      season: context.season,
      episode: context.episode,
      exLang: false,
      key: configSnapshot.key,
    );

    if (qValue.isEmpty) {
      throw const FormatException('Failed to generate encoded query payload.');
    }

    final uri = Uri.parse('$_baseUrl/servers?q=$qValue');

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('Connection timed out while fetching server list.');
    } catch (e) {
      throw Exception('Network error while requesting server list: $e');
    }

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Server list API returned HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}',
        uri,
      );
    }

    final dynamic bodyJson;
    try {
      bodyJson = jsonDecode(response.body);
    } catch (e) {
      throw const FormatException('Malformed JSON response from server API.');
    }

    if (bodyJson is! Map) {
      throw const FormatException('Invalid JSON format: expected Map.');
    }

    final String? responseHash = bodyJson['_hash'] ?? bodyJson['hash'];
    if (responseHash == null || responseHash.isEmpty) {
      throw const FormatException("Missing '_hash' field in server response.");
    }

    final String decryptedJsonStr;
    try {
      decryptedJsonStr = NxshaCipher.decryptCryptoJs(
        responseHash,
        key: configSnapshot.key,
      );
    } catch (e) {
      if (e is CryptoDecodingException) {
        rethrow;
      }
      throw CryptoDecodingException(
        'Failed to decrypt server list hash (hashLen=${responseHash.length}): $e',
      );
    }

    final dynamic parsedData;
    try {
      parsedData = jsonDecode(decryptedJsonStr);
    } catch (e) {
      throw FormatException(
        'Decrypted data (len=${decryptedJsonStr.length}) is not valid JSON: $e',
      );
    }

    if (parsedData is! Map) {
      throw const FormatException('Decrypted JSON is not a Map.');
    }

    final rawList = parsedData['servers'] ?? parsedData['data'];
    if (rawList is! List) {
      return [];
    }

    final List<ServerItem> servers = [];
    for (final item in rawList) {
      if (item is Map) {
        final serverMap = Map<String, dynamic>.from(item);
        final server = ServerItem.fromJson(serverMap);
        // Per Part 1.C: Skip when web_support is explicitly false.
        if (server.webSupport) {
          servers.add(server);
        }
      }
    }

    return servers;
  }

  /// Fetches and resolves stream source URLs for a specific provider/scraper.
  /// On cryptographic decoding failure, automatically attempts a single key refresh & retry.
  Future<List<ResolvedSource>> fetchSources(
    PlaybackContext context,
    String provider, {
    Duration timeout = const Duration(seconds: 12),
    bool isRetry = false,
  }) async {
    final cleanProvider = provider.trim();
    if (cleanProvider.isEmpty) {
      throw ArgumentError('Provider scraper cannot be empty.');
    }

    final KeyConfig configSnapshot;
    try {
      configSnapshot = _keyConfigManager.acquireConfig();
    } catch (_) {
      rethrow;
    }

    try {
      return await _executeFetchSources(
        context,
        cleanProvider,
        configSnapshot,
        timeout: timeout,
      );
    } on CryptoDecodingException {
      if (!isRetry) {
        debugPrint(
          'NxshaApiService: Crypto decoding failed on fetchSources for $cleanProvider. Attempting key recovery...',
        );
        final refreshResult = await _keyConfigManager.forceRefresh();
        if (refreshResult == KeyRefreshResult.updated) {
          debugPrint(
            'NxshaApiService: Key rotated after failure. Retrying fetchSources once...',
          );
          return await fetchSources(
            context,
            cleanProvider,
            timeout: timeout,
            isRetry: true,
          );
        }
      }
      throw const CryptoDecodingException('Decoding algorithm failed');
    } finally {
      _keyConfigManager.releaseConfig(configSnapshot);
    }
  }

  Future<List<ResolvedSource>> _executeFetchSources(
    PlaybackContext context,
    String cleanProvider,
    KeyConfig configSnapshot, {
    required Duration timeout,
  }) async {
    final qValue = NxshaCipher.buildPayload(
      tmdbId: context.tmdbId,
      imdbId: context.imdbId,
      type: context.type,
      season: context.season,
      episode: context.episode,
      exLang: false,
      provider: cleanProvider,
      key: configSnapshot.key,
    );

    if (qValue.isEmpty) {
      throw const FormatException('Failed to generate encoded source payload.');
    }

    final uri = Uri.parse('$_baseUrl/sources?q=$qValue');

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('Source resolution timed out for $cleanProvider.');
    } catch (e) {
      throw Exception('Network error resolving sources for $cleanProvider: $e');
    }

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Sources API for $cleanProvider returned HTTP ${response.statusCode}',
        uri,
      );
    }

    final dynamic bodyJson;
    try {
      bodyJson = jsonDecode(response.body);
    } catch (e) {
      throw const FormatException('Malformed JSON response from sources API.');
    }

    if (bodyJson is! Map) {
      throw const FormatException('Invalid JSON format: expected Map.');
    }

    final String? responseHash = bodyJson['_hash'] ?? bodyJson['hash'];
    if (responseHash == null || responseHash.isEmpty) {
      throw FormatException(
        "Missing '_hash' field in source response for $cleanProvider.",
      );
    }

    final String decryptedJsonStr;
    try {
      decryptedJsonStr = NxshaCipher.decryptCryptoJs(
        responseHash,
        key: configSnapshot.key,
      );
    } catch (e) {
      if (e is CryptoDecodingException) {
        rethrow;
      }
      throw CryptoDecodingException(
        'Failed to decrypt sources hash for $cleanProvider (hashLen=${responseHash.length}): $e',
      );
    }

    final dynamic parsedData;
    try {
      parsedData = jsonDecode(decryptedJsonStr);
    } catch (e) {
      throw FormatException(
        'Decrypted sources for $cleanProvider (len=${decryptedJsonStr.length}) is not valid JSON: $e',
      );
    }

    if (parsedData is! Map) {
      return [];
    }

    final rawSources = parsedData['sources'] ?? parsedData['data'];
    if (rawSources is! List) {
      return [];
    }

    final List<ResolvedSource> sources = [];
    for (final item in rawSources) {
      if (item is Map) {
        final src = ResolvedSource.fromJson(
          Map<String, dynamic>.from(item),
          defaultProvider: cleanProvider,
        );
        // Enforce language policy: only include Hindi & English sources
        if (src.isValidUrl && src.isSupportedLanguage) {
          sources.add(src);
        }
      }
    }

    return sources;
  }
}
