import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/models/resolved_source.dart';
import 'package:sparrow/features/player/models/server_item.dart';
import 'package:sparrow/features/player/providers/stream_resolution_provider.dart';
import 'package:sparrow/features/player/services/nxsha_cipher.dart';
import 'package:sparrow/features/player/services/stream_cache_service.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NxshaCipher Tests', () {
    test('Encrypt and decrypt roundtrip matches original JSON payload', () {
      final sampleData = {
        'tmdbId': '84092',
        'imdb_id': 'tt0259534',
        'type': 'movie',
        'season': 0,
        'episode': 0,
        'ex_lang': false,
        'provider': 'nitro',
      };

      final encodedQ = NxshaCipher.encodeRequest(sampleData);
      expect(encodedQ, isNotEmpty);
      expect(encodedQ.contains('+'), isFalse);
      expect(encodedQ.contains('/'), isFalse);
      expect(encodedQ.contains('='), isFalse);

      final decryptedStr = NxshaCipher.decryptCryptoJs(encodedQ);
      expect(decryptedStr, isNotEmpty);

      final decodedMap = jsonDecode(decryptedStr) as Map<String, dynamic>;
      expect(decodedMap['tmdbId'], equals('84092'));
      expect(decodedMap['imdb_id'], equals('tt0259534'));
      expect(decodedMap['type'], equals('movie'));
      expect(decodedMap['season'], equals(0));
      expect(decodedMap['episode'], equals(0));
      expect(decodedMap['ex_lang'], equals(false));
      expect(decodedMap['provider'], equals('nitro'));
      expect(decodedMap.containsKey('_req_ts'), isTrue);
      expect(decodedMap.containsKey('_req_salt'), isTrue);
    });

    test('buildPayload produces valid URL-safe ciphertext for movie and TV', () {
      final moviePayload = NxshaCipher.buildPayload(
        tmdbId: '123',
        imdbId: 'tt123',
        type: 'movie',
        season: 0,
        episode: 0,
      );
      expect(moviePayload, isNotEmpty);

      final decryptedMovie = jsonDecode(NxshaCipher.decryptCryptoJs(moviePayload));
      expect(decryptedMovie['season'], equals(0));
      expect(decryptedMovie['episode'], equals(0));
      expect(decryptedMovie['type'], equals('movie'));

      final tvPayload = NxshaCipher.buildPayload(
        tmdbId: '456',
        imdbId: '',
        type: 'tv',
        season: 2,
        episode: 5,
        provider: 'awsind',
      );
      expect(tvPayload, isNotEmpty);

      final decryptedTv = jsonDecode(NxshaCipher.decryptCryptoJs(tvPayload));
      expect(decryptedTv['season'], equals(2));
      expect(decryptedTv['episode'], equals(5));
      expect(decryptedTv['type'], equals('tv'));
      expect(decryptedTv['provider'], equals('awsind'));
    });

    test('decryptCryptoJs handles empty or corrupted ciphertext safely', () {
      expect(
        () => NxshaCipher.decryptCryptoJs(''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => NxshaCipher.decryptCryptoJs('corrupted_string_not_salted'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PlaybackContext & Model Tests', () {
    const movieItem = MediaItem(
      id: '550',
      title: 'Fight Club',
      imageUrl: '',
      genres: ['Drama'],
      mediaType: 'movie',
    );

    const tvItem = MediaItem(
      id: '1399',
      title: 'Game of Thrones',
      imageUrl: '',
      genres: ['Sci-Fi & Fantasy'],
      mediaType: 'tv',
    );

    test('PlaybackContext.movie sets season and episode to 0', () {
      final ctx = PlaybackContext.movie(item: movieItem, imdbId: 'tt0137523');
      expect(ctx.isTvShow, isFalse);
      expect(ctx.season, equals(0));
      expect(ctx.episode, equals(0));
      expect(ctx.type, equals('movie'));
      expect(ctx.displayTitle, equals('Fight Club'));
    });

    test('PlaybackContext.tv preserves actual season and episode numbers', () {
      final ctx = PlaybackContext.tv(
        item: tvItem,
        season: 3,
        episode: 9,
        episodeTitle: 'The Rains of Castamere',
      );
      expect(ctx.isTvShow, isTrue);
      expect(ctx.season, equals(3));
      expect(ctx.episode, equals(9));
      expect(ctx.type, equals('tv'));
      expect(
        ctx.displayTitle,
        equals('Game of Thrones - S3 E9: The Rains of Castamere'),
      );
    });

    test('ServerItem skips server only when web_support is explicitly false', () {
      final s1 = ServerItem.fromJson({
        'name': 'Server 1',
        'scraper': 's1',
        'web_support': true,
      });
      expect(s1.webSupport, isTrue);
      expect(s1.isPlayable, isTrue);

      // Missing web_support defaults to true
      final s2 = ServerItem.fromJson({
        'name': 'Server 2',
        'scraper': 's2',
      });
      expect(s2.webSupport, isTrue);
      expect(s2.isPlayable, isTrue);

      // Explicit false
      final s3 = ServerItem.fromJson({
        'name': 'Server 3',
        'scraper': 's3',
        'web_support': false,
      });
      expect(s3.webSupport, isFalse);
      expect(s3.isPlayable, isFalse);
    });

    test('ResolvedSource validates HLS URL and parses headers', () {
      final src = ResolvedSource.fromJson({
        'id': 'nitro-0',
        'provider': 'nitro',
        'url': 'https://wts.itsnitrox.tech/nitro/master.m3u8',
        'quality': '1080p',
        'label': 'Hindi FHD',
        'headers': {'Custom': 'HeaderVal'},
      });

      expect(src.isValidUrl, isTrue);
      expect(src.displayName, equals('Hindi FHD'));
      expect(src.headers['Referer'], equals('https://nxsha.space/'));
      expect(src.headers['Custom'], equals('HeaderVal'));
      expect(src.language, equals(SourceLanguage.hindi));
      expect(src.isSupportedLanguage, isTrue);
      expect(src.isHindiPreferred, isTrue);
    });

    test('SourceLanguage detection accurately categorizes Hindi, English, and unsupported languages', () {
      expect(
        ResolvedSource.detectLanguage('hin', '1080p'),
        equals(SourceLanguage.hindi),
      );
      expect(
        ResolvedSource.detectLanguage(null, '[Hindi] - 1080P'),
        equals(SourceLanguage.hindi),
      );
      expect(
        ResolvedSource.detectLanguage('eng', '720p'),
        equals(SourceLanguage.english),
      );
      expect(
        ResolvedSource.detectLanguage(null, 'English [Original]'),
        equals(SourceLanguage.english),
      );
      expect(
        ResolvedSource.detectLanguage('tam', 'Tamil 1080p'),
        equals(SourceLanguage.unsupported),
      );
      expect(
        ResolvedSource.detectLanguage('tel', 'Telugu 720p'),
        equals(SourceLanguage.unsupported),
      );
      expect(
        ResolvedSource.detectLanguage('vie', 'Vietsub Full'),
        equals(SourceLanguage.unsupported),
      );
      expect(
        ResolvedSource.detectLanguage('multi', 'Multi Audio (Hindi + Eng)'),
        equals(SourceLanguage.multi),
      );
    });
  });

  group('StreamCacheService Tests', () {
    test('Cache key generation is deterministic and differentiates TV episodes', () {
      const tvItem = MediaItem(id: '100', title: 'Show', imageUrl: '', genres: []);
      final ep1 = PlaybackContext.tv(item: tvItem, season: 1, episode: 1);
      final ep2 = PlaybackContext.tv(item: tvItem, season: 1, episode: 2);

      final key1 = StreamCacheService.buildServerKey(ep1);
      final key2 = StreamCacheService.buildServerKey(ep2);

      expect(key1, isNot(equals(key2)));
      expect(key1, contains('s1_e1'));
      expect(key2, contains('s1_e2'));

      final srcKey1 = StreamCacheService.buildSourceKey(ep1, 'nitro');
      final srcKey2 = StreamCacheService.buildSourceKey(ep2, 'nitro');
      expect(srcKey1, isNot(equals(srcKey2)));
      expect(srcKey1, contains('nitro'));
    });

    test('Cache keys strictly isolate different movies (e.g. Street Fighter vs Iron Man 3)', () {
      const streetFighter = MediaItem(
        id: '84092',
        title: 'Street Fighter: Assassin\'s Fist',
        imageUrl: '',
        genres: ['Action'],
        mediaType: 'movie',
      );
      const ironMan3 = MediaItem(
        id: '68721',
        title: 'Iron Man 3',
        imageUrl: '',
        genres: ['Action'],
        mediaType: 'movie',
      );

      final sfContext = PlaybackContext.movie(item: streetFighter, imdbId: 'tt3069212');
      final im3Context = PlaybackContext.movie(item: ironMan3, imdbId: 'tt1300854');

      // Server keys must be distinct
      final sfServerKey = StreamCacheService.buildServerKey(sfContext);
      final im3ServerKey = StreamCacheService.buildServerKey(im3Context);
      expect(sfServerKey, isNot(equals(im3ServerKey)));
      expect(sfServerKey, equals('servers_movie_tmdb_84092_s0_e0'));
      expect(im3ServerKey, equals('servers_movie_tmdb_68721_s0_e0'));

      // Source keys for the exact same provider (e.g. awsply) must be distinct
      final sfSourceKey = StreamCacheService.buildSourceKey(sfContext, 'awsply');
      final im3SourceKey = StreamCacheService.buildSourceKey(im3Context, 'awsply');
      expect(sfSourceKey, isNot(equals(im3SourceKey)));
      expect(sfSourceKey, equals('sources_movie_tmdb_84092_s0_e0_awsply'));
      expect(im3SourceKey, equals('sources_movie_tmdb_68721_s0_e0_awsply'));

      // TV vs Movie with identical TMDB ID must produce distinct keys
      final movieWith100 = PlaybackContext.movie(item: const MediaItem(id: '100', title: 'M', imageUrl: '', genres: []));
      final tvWith100 = PlaybackContext.tv(item: const MediaItem(id: '100', title: 'T', imageUrl: '', genres: []), season: 1, episode: 1);
      expect(StreamCacheService.buildServerKey(movieWith100), isNot(equals(StreamCacheService.buildServerKey(tvWith100))));
    });

    test('Source cache key normalizes whitespace and casing for scraper', () {
      const movie = MediaItem(id: '12345', title: 'Movie', imageUrl: '', genres: []);
      final ctx = PlaybackContext.movie(item: movie);

      final keyLower = StreamCacheService.buildSourceKey(ctx, 'awsply');
      final keyUpper = StreamCacheService.buildSourceKey(ctx, ' AwsPly ');
      expect(keyLower, equals(keyUpper));
      expect(keyUpper, endsWith('_awsply'));
    });

    test('StreamCacheService handles uninitialized Hive safely without exceptions', () async {
      const item = MediaItem(id: '999', title: 'Test', imageUrl: '', genres: []);
      final ctx = PlaybackContext.movie(item: item);

      // Should return null and not crash when Hive box is not opened
      final servers = await StreamCacheService.getCachedServers(ctx);
      expect(servers, isNull);

      final sources = await StreamCacheService.getCachedSources(ctx, 'nitro');
      expect(sources, isNull);

      // Should not throw on write attempts
      await expectLater(StreamCacheService.saveCachedServers(ctx, []), completes);
      await expectLater(StreamCacheService.saveCachedSources(ctx, 'nitro', []), completes);
    });
  });

  group('StreamResolutionNotifier Session & Isolation Tests', () {
    test('cancelSession terminates prior session and starting resolution resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(streamResolutionControllerProvider.notifier);

      // Pre-populate with dummy state resembling Movie A
      notifier.state = StreamResolutionState(
        context: PlaybackContext.movie(
          item: const MediaItem(id: '84092', title: 'Street Fighter', imageUrl: '', genres: []),
        ),
        servers: [
          const ServerItem(id: 1, name: 'AwsPly', scraper: 'awsply', webSupport: true),
        ],
        selectedServerIndex: 0,
        selectedSourceIndex: 0,
        currentSource: const ResolvedSource(
          id: 'sf-1',
          provider: 'awsply',
          url: 'https://example.com/streetfighter.m3u8',
        ),
      );

      expect(notifier.state.context?.tmdbId, equals('84092'));
      expect(notifier.state.selectedServer?.name, equals('AwsPly'));

      // Cancel session when exiting player
      notifier.cancelSession();

      // Start resolution for Movie B (Iron Man 3)
      final ironManCtx = PlaybackContext.movie(
        item: const MediaItem(id: '68721', title: 'Iron Man 3', imageUrl: '', genres: []),
      );

      notifier.startPlaybackResolution(
        context: ironManCtx,
        onSourceReady: (_, _) {},
      );

      // State MUST be immediately reset and isolated from Movie A
      expect(notifier.state.context?.tmdbId, equals('68721'));
      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.selectedServerIndex, isNull);
      expect(notifier.state.selectedSourceIndex, isNull);
      expect(notifier.state.currentSource, isNull);
      expect(notifier.state.isLoadingServers, isTrue);
      expect(notifier.state.isResolvingFirstSource, isTrue);
    });

    test('selectSource resets isFailed when manually re-selected and discards obsolete callbacks', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(streamResolutionControllerProvider.notifier);

      final link1 = const ResolvedSource(
        id: 'l1',
        provider: 'server1',
        url: 'https://example.com/link1.m3u8',
        label: 'Link 1 (Hindi)',
        language: SourceLanguage.hindi,
        isFailed: true,
      );
      final link2 = const ResolvedSource(
        id: 'l2',
        provider: 'server1',
        url: 'https://example.com/link2.m3u8',
        label: 'Link 2 (English)',
        language: SourceLanguage.english,
        isFailed: false,
      );

      notifier.state = StreamResolutionState(
        context: PlaybackContext.movie(
          item: const MediaItem(id: '1234', title: 'Test', imageUrl: '', genres: []),
        ),
        servers: [
          ServerItem(
            id: 1,
            name: 'Server 1',
            scraper: 'server1',
            webSupport: true,
            sources: [link1, link2],
            resolutionStatus: ServerResolutionStatus.ready,
          ),
        ],
        selectedServerIndex: 0,
        selectedSourceIndex: 1,
        currentSource: link2,
      );

      // 1. Calling handleSourceFailure with obsolete source link1 while playing link2
      // Link 1 was from a previous or interrupted attempt; it must be discarded and NOT fail Link 2
      await notifier.handleSourceFailure(
        failedSource: link1,
        currentPosition: Duration.zero,
        onSourceReady: (_, _) {},
      );

      // Active playback of link 2 remains unaffected
      expect(notifier.state.selectedSourceIndex, equals(1));
      expect(notifier.state.currentSource?.id, equals('l2'));
      expect(notifier.state.currentServerSources[1].isFailed, isFalse);

      // 2. User manually selects link 1: it should clear isFailed so user can retry
      notifier.selectSource(
        0,
        currentPosition: Duration.zero,
        onSourceReady: (source, _) {
          expect(source.isFailed, isFalse);
        },
      );

      expect(notifier.state.selectedSourceIndex, equals(0));
      expect(notifier.state.currentSource?.id, equals('l1'));
      expect(notifier.state.currentSource?.isFailed, isFalse);
      expect(notifier.state.currentServerSources[0].isFailed, isFalse);
    });
  });
}
