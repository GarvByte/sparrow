import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparrow/features/home%20page/screen/home_page.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/models/server_item.dart';
import 'package:sparrow/features/player/providers/stream_resolution_provider.dart';
import 'package:sparrow/features/player/repositories/stream_repository.dart';
import 'package:sparrow/features/player/services/key_config_manager.dart';
import 'package:sparrow/features/player/services/key_config_models.dart';
import 'package:sparrow/features/player/services/key_config_storage.dart';
import 'package:sparrow/features/player/services/nxsha_api_service.dart';
import 'package:sparrow/features/player/services/nxsha_cipher.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const keyV1 = '1111111111111111222222222222222233333333333333334444444444444444';
  const keyV2 = '5555555555555555666666666666666677777777777777778888888888888888';

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sparrow_key_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Initialize Hive box for isolated test execution
    if (!Hive.isBoxOpen(KeyConfigStorage.boxName)) {
      await Hive.openBox(KeyConfigStorage.boxName);
    }
    await KeyConfigStorage.clear();
    KeyConfigManager.instance.resetForTesting();
  });

  tearDown(() async {
    await KeyConfigStorage.clear();
  });

  group('NxshaCipher Key Dynamic Rotation & Cryptographic Isolation Tests', () {
    test('Encrypt and decrypt roundtrip dynamically uses KeyConfigManager active key', () {
      KeyConfigManager.instance.setActiveConfigForTesting(
        const KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: 1000,
        ),
      );

      final payload = {'tmdbId': '123', 'type': 'movie', 'season': 0, 'episode': 0};
      final ciphertext = NxshaCipher.encodeRequest(payload);
      expect(ciphertext, isNotEmpty);

      final decrypted = jsonDecode(NxshaCipher.decryptCryptoJs(ciphertext));
      expect(decrypted['tmdbId'], equals('123'));
    });

    test('Ciphertext encrypted with keyV1 cannot be decrypted with keyV2 (CryptoDecodingException)', () {
      final payload = {'tmdbId': '999', 'type': 'movie', 'season': 0, 'episode': 0};
      final ciphertextV1 = NxshaCipher.encodeRequest(payload, key: keyV1);

      expect(
        () => NxshaCipher.decryptCryptoJs(ciphertextV1, key: keyV2),
        throwsA(isA<CryptoDecodingException>()),
      );
    });

    test('buildPayload and decryptCryptoJs use identical transactional key snapshot', () {
      KeyConfigManager.instance.setActiveConfigForTesting(
        const KeyConfig(version: 2, key: keyV2, lastCheckedTimestamp: 2000),
      );

      final snapshot = KeyConfigManager.instance.acquireConfig();
      try {
        final encoded = NxshaCipher.buildPayload(
          tmdbId: '888',
          imdbId: 'tt888',
          type: 'movie',
          season: 0,
          episode: 0,
          key: snapshot.key,
        );

        final decoded = jsonDecode(NxshaCipher.decryptCryptoJs(encoded, key: snapshot.key));
        expect(decoded['tmdbId'], equals('888'));
        expect(decoded['imdb_id'], equals('tt888'));
      } finally {
        KeyConfigManager.instance.releaseConfig(snapshot);
      }
    });
  });

  group('KeyConfigStorage Persistence Tests', () {
    test('Persists and loads configuration across simulated restarts', () async {
      final config = const KeyConfig(
        version: 3,
        key: keyV1,
        lastCheckedTimestamp: 50000,
      );

      final saved = await KeyConfigStorage.saveConfig(config);
      expect(saved, isTrue);

      final loaded = await KeyConfigStorage.loadConfig();
      expect(loaded, isNotNull);
      expect(loaded!.version, equals(3));
      expect(loaded.key, equals(keyV1));
      expect(loaded.lastCheckedTimestamp, equals(50000));
    });

    test('Refuses to overwrite working configuration with invalid or empty payload', () async {
      final valid = const KeyConfig(
        version: 1,
        key: keyV1,
        lastCheckedTimestamp: 1000,
      );
      await KeyConfigStorage.saveConfig(valid);

      final invalid = const KeyConfig(
        version: 0,
        key: '',
        lastCheckedTimestamp: 2000,
      );
      final saved = await KeyConfigStorage.saveConfig(invalid);
      expect(saved, isFalse);

      final loaded = await KeyConfigStorage.loadConfig();
      expect(loaded!.version, equals(1));
      expect(loaded.key, equals(keyV1));
    });
  });

  group('Startup & 12-Hour Version Check Lifecycle Tests', () {
    test('Case A: Key already in Hive is loaded immediately without waiting for network', () async {
      await KeyConfigStorage.saveConfig(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      bool networkCalled = false;
      final mockClient = MockClient((request) async {
        networkCalled = true;
        return http.Response('{"version": 2, "key": "$keyV2"}', 200);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);
      await KeyConfigManager.instance.init(registerLifecycleObserver: false);

      expect(KeyConfigManager.instance.hasKeyConfig, isTrue);
      expect(KeyConfigManager.instance.activeConfig!.version, equals(1));
      expect(KeyConfigManager.instance.activeConfig!.key, equals(keyV1));
      // Under 12 hours: network request should NOT be made on launch
      expect(networkCalled, isFalse);
    });

    test('Case A: Key already in Hive triggers background version check if >= 12 hours ago', () async {
      final twelveHoursOneMinuteAgo =
          DateTime.now().subtract(const Duration(hours: 12, minutes: 1)).millisecondsSinceEpoch;

      await KeyConfigStorage.saveConfig(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: twelveHoursOneMinuteAgo,
        ),
      );

      bool networkCalled = false;
      final mockClient = MockClient((request) async {
        networkCalled = true;
        return http.Response(jsonEncode({'version': 2, 'key': keyV2}), 200);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);
      await KeyConfigManager.instance.init(registerLifecycleObserver: false);

      // Background check should execute and update key to v2
      await KeyConfigManager.instance.checkVersionIfDue();

      expect(networkCalled, isTrue);
      expect(KeyConfigManager.instance.activeConfig!.version, equals(2));
      expect(KeyConfigManager.instance.activeConfig!.key, equals(keyV2));
    });

    test('Case B: Fresh install fetches and stores key configuration immediately', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(jsonEncode({'version': 1, 'key': keyV1}), 200);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);
      await KeyConfigManager.instance.init(registerLifecycleObserver: false);

      expect(requestCount, equals(1));
      expect(KeyConfigManager.instance.hasKeyConfig, isTrue);
      expect(KeyConfigManager.instance.activeConfig!.version, equals(1));
      expect(KeyConfigManager.instance.activeConfig!.key, equals(keyV1));

      final stored = await KeyConfigStorage.loadConfig();
      expect(stored, isNotNull);
      expect(stored!.version, equals(1));
    });

    test('Backend reports same version: timestamp updated, no key replacement', () async {
      final oldTime = DateTime.now().subtract(const Duration(hours: 13)).millisecondsSinceEpoch;
      final initialConfig = KeyConfig(
        version: 1,
        key: keyV1,
        lastCheckedTimestamp: oldTime,
      );
      KeyConfigManager.instance.setActiveConfigForTesting(initialConfig);
      await KeyConfigStorage.saveConfig(initialConfig);

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'version': 1, 'key': keyV1}), 200);
      });
      KeyConfigManager.instance.setClientForTesting(mockClient);

      await KeyConfigManager.instance.checkVersionIfDue();

      expect(KeyConfigManager.instance.activeConfig!.version, equals(1));
      expect(KeyConfigManager.instance.activeConfig!.lastCheckedTimestamp, greaterThan(oldTime));
    });

    test('Backend unavailable: continues with cached key and retains timestamp for retry', () async {
      final oldTime = DateTime.now().subtract(const Duration(hours: 14)).millisecondsSinceEpoch;
      final initialConfig = KeyConfig(
        version: 1,
        key: keyV1,
        lastCheckedTimestamp: oldTime,
      );
      KeyConfigManager.instance.setActiveConfigForTesting(initialConfig);
      await KeyConfigStorage.saveConfig(initialConfig);

      final mockClient = MockClient((request) async {
        throw http.ClientException('Server unavailable');
      });
      KeyConfigManager.instance.setClientForTesting(mockClient);

      await KeyConfigManager.instance.checkVersionIfDue();

      // Still has working key v1
      expect(KeyConfigManager.instance.activeConfig!.version, equals(1));
      // Timestamp NOT overwritten to future, so retry is eligible on subsequent check
      expect(KeyConfigManager.instance.isCheckDue, isTrue);
    });

    test('Invalid remote configuration: retains previous working key', () async {
      final initialConfig = KeyConfig(
        version: 1,
        key: keyV1,
        lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      KeyConfigManager.instance.setActiveConfigForTesting(initialConfig);
      await KeyConfigStorage.saveConfig(initialConfig);

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'version': -1, 'key': ''}), 200);
      });
      KeyConfigManager.instance.setClientForTesting(mockClient);

      final result = await KeyConfigManager.instance.forceRefresh();
      expect(result, equals(KeyRefreshResult.failed));
      expect(KeyConfigManager.instance.activeConfig!.version, equals(1));
    });
  });

  group('Active Decoding Operations & Key Rotation Safety Tests', () {
    test('Active operation retains old key snapshot while background refresh rotates to new key', () async {
      KeyConfigManager.instance.setActiveConfigForTesting(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Operation A acquires snapshot v1
      final snapshotA = KeyConfigManager.instance.acquireConfig();
      expect(snapshotA.version, equals(1));
      expect(snapshotA.key, equals(keyV1));
      expect(KeyConfigManager.instance.activeLeasesForVersion(1), equals(1));

      // Background rotation occurs to v2
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'version': 2, 'key': keyV2}), 200);
      });
      KeyConfigManager.instance.setClientForTesting(mockClient);

      final refreshResult = await KeyConfigManager.instance.forceRefresh();
      expect(refreshResult, equals(KeyRefreshResult.updated));

      // New operations now see v2
      final snapshotB = KeyConfigManager.instance.acquireConfig();
      expect(snapshotB.version, equals(2));
      expect(snapshotB.key, equals(keyV2));

      // Operation A still holds immutable v1 and can finish decoding v1 ciphertext
      final payloadA = {'operation': 'A'};
      final cipherA = NxshaCipher.encodeRequest(payloadA, key: snapshotA.key);
      final decodedA = jsonDecode(NxshaCipher.decryptCryptoJs(cipherA, key: snapshotA.key));
      expect(decodedA['operation'], equals('A'));

      // Release Operation A
      KeyConfigManager.instance.releaseConfig(snapshotA);
      expect(KeyConfigManager.instance.activeLeasesForVersion(1), equals(0));

      KeyConfigManager.instance.releaseConfig(snapshotB);
      expect(KeyConfigManager.instance.activeLeasesForVersion(2), equals(0));
    });
  });

  group('Decoding Failure Automatic Recovery Tests', () {
    test('First decoding failure triggers controlled force refresh and retries with new key', () async {
      KeyConfigManager.instance.setActiveConfigForTesting(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      int refreshCalls = 0;
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/key')) {
          refreshCalls++;
          return http.Response(jsonEncode({'version': 2, 'key': keyV2}), 200);
        }

        if (path.contains('/servers')) {
          // Response was encrypted using keyV2 on the backend
          final responseHash = NxshaCipher.encodeRequest({
            'servers': [
              {'name': 'Test Server', 'scraper': 'test_scraper', 'web_support': true}
            ]
          }, key: keyV2);
          return http.Response(jsonEncode({'_hash': responseHash}), 200);
        }

        return http.Response('Not found', 404);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);

      final apiService = NxshaApiService(
        client: mockClient,
        keyConfigManager: KeyConfigManager.instance,
      );

      const context = PlaybackContext(
        item: MediaItem(id: '1', title: 'Test Movie', imageUrl: '', genres: []),
        tmdbId: '1',
        isTvShow: false,
      );

      // fetchServers will initially fail with keyV1, trigger refresh to keyV2, and succeed on retry
      final servers = await apiService.fetchServers(context);
      expect(servers, isNotEmpty);
      expect(servers.first.name, equals('Test Server'));
      expect(refreshCalls, equals(1));
      expect(KeyConfigManager.instance.activeConfig!.version, equals(2));
    });

    test('Retry decoding failure throws CryptoDecodingException("Decoding algorithm failed")', () async {
      KeyConfigManager.instance.setActiveConfigForTesting(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/key')) {
          return http.Response(jsonEncode({'version': 2, 'key': keyV2}), 200);
        }

        if (path.contains('/servers')) {
          // Server returns a garbage hash that neither v1 nor v2 can decode
          return http.Response(jsonEncode({'_hash': 'Salted__invalid_corrupt_hash_data_padding'}), 200);
        }

        return http.Response('Not found', 404);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);
      final apiService = NxshaApiService(
        client: mockClient,
        keyConfigManager: KeyConfigManager.instance,
      );

      const context = PlaybackContext(
        item: MediaItem(id: '1', title: 'Test', imageUrl: '', genres: []),
        tmdbId: '1',
        isTvShow: false,
      );

      expect(
        () => apiService.fetchServers(context),
        throwsA(
          isA<CryptoDecodingException>().having(
            (e) => e.message,
            'message',
            contains('Decoding algorithm failed'),
          ),
        ),
      );
    });

    test('Simultaneous decoding failures share a single force refresh request', () async {
      KeyConfigManager.instance.setActiveConfigForTesting(
        KeyConfig(
          version: 1,
          key: keyV1,
          lastCheckedTimestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      int keyEndpointCalls = 0;
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/key')) {
          keyEndpointCalls++;
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(jsonEncode({'version': 2, 'key': keyV2}), 200);
        }
        return http.Response('{"_hash": "Salted__invalid"}', 200);
      });

      KeyConfigManager.instance.setClientForTesting(mockClient);

      // Launch 3 simultaneous force refreshes
      final f1 = KeyConfigManager.instance.forceRefresh();
      final f2 = KeyConfigManager.instance.forceRefresh();
      final f3 = KeyConfigManager.instance.forceRefresh();

      final results = await Future.wait([f1, f2, f3]);
      expect(results.every((r) => r == KeyRefreshResult.updated), isTrue);
      // All 3 shared 1 backend HTTP request
      expect(keyEndpointCalls, equals(1));
    });
  });

  group('StreamResolutionNotifier Error Classification Tests', () {
    test('Sets "Decoding algorithm failed" when repository fails with CryptoDecodingException', () async {
      final container = ProviderContainer(
        overrides: [
          streamRepositoryProvider.overrideWithValue(_MockFailingCryptoRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(streamResolutionControllerProvider.notifier);
      const context = PlaybackContext(
        item: MediaItem(id: '1', title: 'Test', imageUrl: '', genres: []),
        tmdbId: '1',
        isTvShow: false,
      );

      await notifier.startPlaybackResolution(
        context: context,
        onSourceReady: (source, startAt) {},
      );

      final state = container.read(streamResolutionControllerProvider);
      expect(state.errorMessage, equals('Decoding algorithm failed'));
    });

    test('Preserves "No valid links were found for this title." when servers list is empty', () async {
      final container = ProviderContainer(
        overrides: [
          streamRepositoryProvider.overrideWithValue(_MockEmptyServersRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(streamResolutionControllerProvider.notifier);
      const context = PlaybackContext(
        item: MediaItem(id: '1', title: 'Test', imageUrl: '', genres: []),
        tmdbId: '1',
        isTvShow: false,
      );

      await notifier.startPlaybackResolution(
        context: context,
        onSourceReady: (source, startAt) {},
      );

      final state = container.read(streamResolutionControllerProvider);
      expect(state.errorMessage, equals('No valid links were found for this title.'));
    });

    test('Preserves "Check your connection" when network error occurs', () async {
      final container = ProviderContainer(
        overrides: [
          streamRepositoryProvider.overrideWithValue(_MockNetworkErrorRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(streamResolutionControllerProvider.notifier);
      const context = PlaybackContext(
        item: MediaItem(id: '1', title: 'Test', imageUrl: '', genres: []),
        tmdbId: '1',
        isTvShow: false,
      );

      await notifier.startPlaybackResolution(
        context: context,
        onSourceReady: (source, startAt) {},
      );

      final state = container.read(streamResolutionControllerProvider);
      expect(state.errorMessage, equals('Check your connection'));
    });

    testWidgets('Homepage contains force-refresh button after sections wrapped in TvFocusable', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pump();

      // Find the refresh button icon at the bottom of the homepage
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });
}

class _MockFailingCryptoRepository extends StreamRepository {
  @override
  Future<List<ServerItem>> getServers(
    PlaybackContext context, {
    bool forceRefresh = false,
  }) async {
    throw const CryptoDecodingException('Decoding algorithm failed');
  }
}

class _MockEmptyServersRepository extends StreamRepository {
  @override
  Future<List<ServerItem>> getServers(
    PlaybackContext context, {
    bool forceRefresh = false,
  }) async {
    return [];
  }
}

class _MockNetworkErrorRepository extends StreamRepository {
  @override
  Future<List<ServerItem>> getServers(
    PlaybackContext context, {
    bool forceRefresh = false,
  }) async {
    throw http.ClientException('Connection reset by peer');
  }
}
