import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../../shared/api.dart';
import 'key_config_models.dart';
import 'key_config_storage.dart';

/// Centralized manager for remote encryption key configuration, persistent Hive caching,
/// 12-hour periodic version checking, lifecycle management, and rotation safety.
class KeyConfigManager with WidgetsBindingObserver {
  KeyConfigManager._();

  static final KeyConfigManager instance = KeyConfigManager._();

  static const Duration versionCheckInterval = Duration(hours: 12);
  static const Duration requestTimeout = Duration(seconds: 12);

  http.Client _client = http.Client();
  KeyConfig? _activeConfig;
  bool _initialized = false;
  bool _observerRegistered = false;

  // Active operation reference counts per version (for rotation safety)
  final Map<int, int> _activeVersionLeases = {};

  // Deduplication futures
  Future<KeyRefreshResult>? _inFlightRefresh;
  Future<void>? _inFlightVersionCheck;

  /// Visible for testing to inject custom mock HTTP client.
  @visibleForTesting
  void setClientForTesting(http.Client client) {
    _client = client;
  }

  /// Visible for testing to set the active config directly.
  @visibleForTesting
  void setActiveConfigForTesting(KeyConfig? config) {
    _activeConfig = config;
    _initialized = true;
  }

  /// Visible for testing to reset manager state completely between test cases.
  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _activeConfig = null;
    _inFlightRefresh = null;
    _inFlightVersionCheck = null;
    _activeVersionLeases.clear();
  }

  /// Whether a valid key configuration is currently active in memory.
  bool get hasKeyConfig => _activeConfig != null && _activeConfig!.isValid;

  /// Returns the current active configuration snapshot, or null if unconfigured.
  KeyConfig? get activeConfig => _activeConfig;

  /// Convenient getter for the active key string, falling back to [ApiConfig.defaultKey]
  /// if not yet initialized (e.g. in test suites).
  String get activeKeyOrFallback {
    if (_activeConfig != null && _activeConfig!.isValid) {
      return _activeConfig!.key;
    }
    return ApiConfig.defaultKey;
  }

  /// Initializes local Hive storage and sets up startup configuration according to Part 4:
  /// - Case A: If key exists in Hive, read it immediately, make it active without waiting,
  ///   and initiate background version check only if 12+ hours have elapsed.
  /// - Case B: If key does not exist in Hive, fetch it from backend immediately before allowing
  ///   key-dependent operations.
  Future<void> init({bool registerLifecycleObserver = true}) async {
    if (_initialized) return;

    await KeyConfigStorage.init();
    final cached = await KeyConfigStorage.loadConfig();

    if (cached != null && cached.isValid) {
      // Case A: Key already exists in Hive
      _activeConfig = cached;
      _initialized = true;
      debugPrint(
        'KeyConfigManager: Loaded cached key config v${cached.version} from Hive',
      );

      // Check if 12 hours have elapsed since last successful check
      if (isCheckDue) {
        unawaited(checkVersionIfDue());
      }
    } else {
      // Case B: Key does not exist in Hive
      debugPrint('KeyConfigManager: No cached key found. Performing initial remote fetch...');
      final result = await _fetchRemoteConfig();
      if (result != null && result.isValid) {
        await KeyConfigStorage.saveConfig(result);
        _activeConfig = result;
        _initialized = true;
        debugPrint(
          'KeyConfigManager: Initial remote key config v${result.version} fetched and persisted',
        );
      } else {
        // Handle failure to fetch on fresh install
        _initialized = true;
        debugPrint('KeyConfigManager: Failed to fetch initial remote key config. Unconfigured.');
      }
    }

    if (registerLifecycleObserver && !_observerRegistered) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observerRegistered = true;
      } catch (e) {
        debugPrint('KeyConfigManager: Lifecycle observer registration skipped: $e');
      }
    }
  }

  /// Acquires an immutable configuration snapshot for a resolution transaction.
  /// Increments the active operation lease counter for the snapshot's version
  /// so previous versions remain alive until all concurrent decoders finish.
  KeyConfig acquireConfig() {
    if (_activeConfig == null || !_activeConfig!.isValid) {
      throw const KeyConfigException(
        'Resolver configuration error: Unable to load encryption key.',
      );
    }

    final snapshot = _activeConfig!;
    _activeVersionLeases[snapshot.version] =
        (_activeVersionLeases[snapshot.version] ?? 0) + 1;
    return snapshot;
  }

  /// Releases an operation lease when a resolution transaction concludes.
  void releaseConfig(KeyConfig snapshot) {
    final currentCount = _activeVersionLeases[snapshot.version] ?? 0;
    if (currentCount <= 1) {
      _activeVersionLeases.remove(snapshot.version);
    } else {
      _activeVersionLeases[snapshot.version] = currentCount - 1;
    }
  }

  /// Reports the count of active operations currently referencing a specific version.
  int activeLeasesForVersion(int version) => _activeVersionLeases[version] ?? 0;

  /// Whether a 12-hour background version check is due.
  bool get isCheckDue {
    if (_activeConfig == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _activeConfig!.lastCheckedTimestamp;
    return elapsed >= versionCheckInterval.inMilliseconds;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isCheckDue) {
        debugPrint(
          'KeyConfigManager: App resumed and 12-hour interval elapsed. Triggering check...',
        );
        unawaited(checkVersionIfDue());
      }
    }
  }

  /// Triggers a lightweight background version check if at least 12 hours have elapsed.
  /// Deduplicates concurrent background requests.
  Future<void> checkVersionIfDue() async {
    if (!isCheckDue) return;

    if (_inFlightVersionCheck != null) {
      return _inFlightVersionCheck!;
    }

    final future = _executeVersionCheck();
    _inFlightVersionCheck = future;

    try {
      await future;
    } finally {
      _inFlightVersionCheck = null;
    }
  }

  Future<void> _executeVersionCheck() async {
    try {
      final remoteConfig = await _fetchRemoteConfig();
      if (remoteConfig == null || !remoteConfig.isValid) {
        // Failed request: retain previous config and do NOT update timestamp
        // so retries remain eligible on subsequent checks.
        debugPrint('KeyConfigManager: Version check request failed or returned invalid data.');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      if (_activeConfig != null &&
          _activeConfig!.version == remoteConfig.version &&
          _activeConfig!.key == remoteConfig.key) {
        // Version unchanged: update timestamp only, do not reload
        debugPrint(
          'KeyConfigManager: Remote key version ${remoteConfig.version} unchanged. Updating check timestamp.',
        );
        await KeyConfigStorage.updateLastChecked(now);
        _activeConfig = _activeConfig!.copyWith(lastCheckedTimestamp: now);
      } else {
        // Version or key changed: validate and activate new snapshot
        debugPrint(
          'KeyConfigManager: New key version detected (${remoteConfig.version}). Activating...',
        );
        final staged = remoteConfig.copyWith(lastCheckedTimestamp: now);
        final saved = await KeyConfigStorage.saveConfig(staged);
        if (saved) {
          _activeConfig = staged;
          debugPrint(
            'KeyConfigManager: Key rotated successfully to v${staged.version}',
          );
        }
      }
    } catch (e) {
      debugPrint('KeyConfigManager._executeVersionCheck error: $e');
    }
  }

  /// Forces an immediate backend key fetch regardless of the 12-hour interval.
  /// Deduplicates simultaneous requests so concurrent failures or user taps share 1 HTTP call.
  Future<KeyRefreshResult> forceRefresh() async {
    if (_inFlightRefresh != null) {
      debugPrint('KeyConfigManager: Reusing existing in-flight force refresh request');
      return _inFlightRefresh!;
    }

    final future = _executeForceRefresh();
    _inFlightRefresh = future;

    try {
      return await future;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<KeyRefreshResult> _executeForceRefresh() async {
    try {
      final remoteConfig = await _fetchRemoteConfig();
      if (remoteConfig == null || !remoteConfig.isValid) {
        debugPrint('KeyConfigManager: Force refresh failed (invalid or unreachable remote response)');
        return KeyRefreshResult.failed;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      if (_activeConfig != null &&
          _activeConfig!.version == remoteConfig.version &&
          _activeConfig!.key == remoteConfig.key) {
        await KeyConfigStorage.updateLastChecked(now);
        _activeConfig = _activeConfig!.copyWith(lastCheckedTimestamp: now);
        debugPrint('KeyConfigManager: Force refresh: Key is already up to date (v${remoteConfig.version})');
        return KeyRefreshResult.noChange;
      }

      final staged = remoteConfig.copyWith(lastCheckedTimestamp: now);
      final saved = await KeyConfigStorage.saveConfig(staged);
      if (saved) {
        _activeConfig = staged;
        debugPrint('KeyConfigManager: Force refresh: Rotated to new key v${staged.version}');
        return KeyRefreshResult.updated;
      }

      return KeyRefreshResult.failed;
    } catch (e) {
      debugPrint('KeyConfigManager._executeForceRefresh error: $e');
      return KeyRefreshResult.failed;
    }
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json, text/plain, */*',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

  /// Fetches raw key configuration from the backend endpoint with bounded retry.
  Future<KeyConfig?> _fetchRemoteConfig() async {
    final uri = Uri.parse(
      '${ApiConfig.backendBaseUrl}${ApiConfig.keyConfigEndpointPath}',
    );

    int attempt = 0;
    const maxAttempts = 3;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(requestTimeout);

        if (response.statusCode == 200) {
          final dynamic bodyJson = jsonDecode(response.body);
          if (bodyJson is Map) {
            final parsed = KeyConfig.fromMap(bodyJson);
            if (parsed.isValid && parsed.key.length >= 16) {
              return parsed;
            }
          }
          debugPrint('KeyConfigManager: Malformed remote response format');
          return null;
        }

        if (response.statusCode >= 500 && attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }

        return null;
      } catch (e) {
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        return null;
      }
    }

    return null;
  }

  /// Cleans up observers and resources.
  void dispose() {
    if (_observerRegistered) {
      try {
        WidgetsBinding.instance.removeObserver(this);
        _observerRegistered = false;
      } catch (_) {}
    }
  }
}
