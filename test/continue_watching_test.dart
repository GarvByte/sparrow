import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/anime%20hub/screens/anime_hub_page.dart';
import 'package:sparrow/features/continue_watching/data/continue_watching_item.dart';
import 'package:sparrow/features/continue_watching/data/continue_watching_repository.dart';
import 'package:sparrow/features/continue_watching/providers/continue_watching_provider.dart';
import 'package:sparrow/features/home%20page/screen/home_page.dart';
import 'package:sparrow/features/home%20page/widgets/continue_watching_card.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContinueWatchingRepository repo;

  setUp(() async {
    repo = ContinueWatchingRepository();
    await repo.clearAll();
  });

  tearDown(() async {
    await repo.clearAll();
  });

  group('ContinueWatchingItem Model & Identity Tests', () {
    test('Composite key differentiates movies and TV shows with identical IDs', () {
      final movieKey = ContinueWatchingItem.compositeKey('movie', '100');
      final tvKey1 = ContinueWatchingItem.compositeKey('tv', '100', season: 1, episode: 1);
      final tvKey2 = ContinueWatchingItem.compositeKey('tv', '100', season: 1, episode: 2);
      final tvKey3 = ContinueWatchingItem.compositeKey('tv', '100', season: 2, episode: 1);

      expect(movieKey, 'movie_100');
      expect(tvKey1, 'tv_100_s1_e1');
      expect(tvKey2, 'tv_100_s1_e2');
      expect(tvKey3, 'tv_100_s2_e1');

      expect(movieKey != tvKey1, isTrue);
      expect(tvKey1 != tvKey2, isTrue);
      expect(tvKey1 != tvKey3, isTrue);
    });

    test('toMediaItem accurately maps properties and sets 16:9 aspect ratio', () {
      final item = ContinueWatchingItem(
        key: 'movie_550',
        mediaType: 'movie',
        tmdbId: '550',
        title: 'Fight Club',
        imageUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        positionMs: 600000, // 10 minutes
        durationMs: 7200000, // 120 minutes
        lastUpdatedAt: DateTime.now(),
        genres: const ['Drama'],
        rating: 8.4,
      );

      final mediaItem = item.toMediaItem();
      expect(mediaItem.id, '550');
      expect(mediaItem.title, 'Fight Club');
      expect(mediaItem.imageUrl, 'https://example.com/backdrop.jpg');
      expect(mediaItem.aspectRatio, 16 / 9);
      expect(mediaItem.progress, closeTo(600000 / 7200000, 0.001));
      expect(mediaItem.durationLeft, contains('left'));
      expect(mediaItem.bottomBadge, 'MOVIE');
    });

    test('TV episode toMediaItem sets season/episode bottom badge', () {
      final item = ContinueWatchingItem(
        key: 'tv_1399_s1_e1',
        mediaType: 'tv',
        tmdbId: '1399',
        title: 'Game of Thrones',
        imageUrl: 'https://example.com/got.jpg',
        positionMs: 300000,
        durationMs: 3600000,
        lastUpdatedAt: DateTime.now(),
        season: 1,
        episode: 1,
        episodeTitle: 'Winter Is Coming',
      );

      final mediaItem = item.toMediaItem();
      expect(mediaItem.bottomBadge, 'S1 E1');
    });
  });

  group('2-Minute Eligibility Threshold & Persistence Tests', () {
    test('Playback < 2 minutes on brand new item does NOT qualify for Continue Watching', () async {
      // 1 minute 30 seconds
      final saved = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '101',
        title: 'Short Watch Movie',
        imageUrl: 'https://example.com/movie.jpg',
        positionMs: 90000,
        durationMs: 6000000,
      );

      expect(saved, isFalse);
      expect(repo.getAllItems(), isEmpty);
      expect(repo.hasValidProgress('movie_101'), isFalse);
    });

    test('Playback >= 2 minutes qualifies and saves exact playback position', () async {
      // 8 minutes
      const eightMinutesMs = 8 * 60 * 1000;
      final saved = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '102',
        title: 'Dune: Part Two',
        imageUrl: 'https://example.com/dune.jpg',
        positionMs: eightMinutesMs,
        durationMs: 9600000,
      );

      expect(saved, isTrue);
      expect(repo.getAllItems(), hasLength(1));
      final item = repo.getItem('movie_102');
      expect(item, isNotNull);
      expect(item!.positionMs, eightMinutesMs);
    });

    test('Resuming an existing item preserves and updates progress even if session is < 2 minutes', () async {
      // Initial 8 minute session
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '103',
        title: 'Interstellar',
        imageUrl: 'https://example.com/interstellar.jpg',
        positionMs: 480000,
        durationMs: 10000000,
      );

      // Resumed session seeks or stops after 30 seconds (position: 8m 30s)
      final updated = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '103',
        title: 'Interstellar',
        imageUrl: 'https://example.com/interstellar.jpg',
        positionMs: 510000,
        durationMs: 10000000,
      );

      expect(updated, isTrue);
      final item = repo.getItem('movie_103');
      expect(item!.positionMs, 510000);
    });

    test('Completion policy: Finished media is removed from Continue Watching', () async {
      // User watches video to 96% completion
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '104',
        title: 'Inception',
        imageUrl: 'https://example.com/inception.jpg',
        positionMs: 480000,
        durationMs: 6000000,
      );
      expect(repo.hasValidProgress('movie_104'), isTrue);

      // Video finishes (>= 95% of duration)
      final completed = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '104',
        title: 'Inception',
        imageUrl: 'https://example.com/inception.jpg',
        positionMs: 5900000,
        durationMs: 6000000,
      );

      expect(completed, isFalse);
      expect(repo.getItem('movie_104'), isNull);
      expect(repo.hasValidProgress('movie_104'), isFalse);
    });

    test('Completion of one TV episode does not affect other episodes of the same show', () async {
      await repo.saveProgress(
        mediaType: 'tv',
        tmdbId: '200',
        title: 'Breaking Bad',
        imageUrl: 'https://example.com/bb.jpg',
        season: 1,
        episode: 1,
        positionMs: 5900000, // finished
        durationMs: 6000000,
      );

      await repo.saveProgress(
        mediaType: 'tv',
        tmdbId: '200',
        title: 'Breaking Bad',
        imageUrl: 'https://example.com/bb.jpg',
        season: 1,
        episode: 2,
        positionMs: 300000, // ongoing
        durationMs: 6000000,
      );

      expect(repo.getItem('tv_200_s1_e1'), isNull);
      expect(repo.getItem('tv_200_s1_e2'), isNotNull);
      expect(repo.hasValidProgress('tv_200_s1_e2'), isTrue);
    });
  });

  group('Removal & Stale Save Guard Tests', () {
    test('Removing item resets resume progress and prevents in-flight revival', () async {
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '300',
        title: 'The Matrix',
        imageUrl: 'https://example.com/matrix.jpg',
        positionMs: 600000,
        durationMs: 7200000,
      );
      expect(repo.hasValidProgress('movie_300'), isTrue);

      // Remove from Continue Watching
      await repo.removeItem('movie_300');
      expect(repo.getItem('movie_300'), isNull);
      expect(repo.hasValidProgress('movie_300'), isFalse);

      // Stale in-flight save arriving after removal is rejected
      final reviveAttempt = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '300',
        title: 'The Matrix',
        imageUrl: 'https://example.com/matrix.jpg',
        positionMs: 610000,
        durationMs: 7200000,
      );
      expect(reviveAttempt, isFalse);
      expect(repo.getItem('movie_300'), isNull);

      // Brand new session clears removed flag and allows fresh qualification after 2 mins
      repo.clearRecentlyRemoved('movie_300');
      final newSession = await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '300',
        title: 'The Matrix',
        imageUrl: 'https://example.com/matrix.jpg',
        positionMs: 150000, // > 2 mins
        durationMs: 7200000,
      );
      expect(newSession, isTrue);
      expect(repo.getItem('movie_300'), isNotNull);
    });
  });

  group('Riverpod Reactive Providers & UI Synchronization Tests', () {
    testWidgets('Home page hides Continue Watching section entirely when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Watching'), findsNothing);
    });

    testWidgets('Home page renders Continue Watching with remove button when items exist', (tester) async {
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '400',
        title: 'Blade Runner 2049',
        imageUrl: 'https://example.com/br.jpg',
        positionMs: 600000,
        durationMs: 9000000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.byType(ContinueWatchingCard), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('TV Shows page displays only TV episodes in Continue Watching and hides when empty', (tester) async {
      // Seed a movie ONLY
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '500',
        title: 'Oppenheimer',
        imageUrl: 'https://example.com/opp.jpg',
        positionMs: 600000,
        durationMs: 10000000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: AnimeHubPage(),
          ),
        ),
      );
      await tester.pump();

      // TV Shows page filters out movies: section should be hidden!
      expect(find.text('Continue Watching'), findsNothing);

      // Now add a TV episode
      await repo.saveProgress(
        mediaType: 'tv',
        tmdbId: '600',
        title: 'Attack on Titan',
        imageUrl: 'https://example.com/aot.jpg',
        season: 1,
        episode: 1,
        positionMs: 300000,
        durationMs: 1400000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: AnimeHubPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.byType(ContinueWatchingCard), findsOneWidget);
    });

    testWidgets('Removing item via cross button removes it immediately and hides section', (tester) async {
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '700',
        title: 'Avatar',
        imageUrl: 'https://example.com/avatar.jpg',
        positionMs: 600000,
        durationMs: 10000000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Watching'), findsOneWidget);

      // Tap remove cross button
      final removeButtonFinder = find.byIcon(Icons.close_rounded);
      expect(removeButtonFinder, findsOneWidget);
      await tester.tap(removeButtonFinder);
      await tester.pumpAndSettle();

      // Section disappears completely
      expect(find.text('Continue Watching'), findsNothing);
      expect(repo.getItem('movie_700'), isNull);
    });
  });

  group('Resume vs Watch Now Button Tests', () {
    testWidgets('MovieDetailsScreen shows Watch Now when no progress and Resume when progress exists', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const movie = MediaItem(
        id: '800',
        title: 'Gladiator',
        imageUrl: 'https://example.com/gladiator.jpg',
        genres: ['Action'],
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MovieDetailsScreen(movieData: movie),
          ),
        ),
      );
      await tester.pump();

      // Initially displays Watch Now
      expect(find.text('Watch Now'), findsWidgets);
      expect(find.text('Resume'), findsNothing);

      // Save progress for this movie
      await repo.saveProgress(
        mediaType: 'movie',
        tmdbId: '800',
        title: 'Gladiator',
        imageUrl: 'https://example.com/gladiator.jpg',
        positionMs: 600000,
        durationMs: 9000000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MovieDetailsScreen(movieData: movie),
          ),
        ),
      );
      await tester.pump();

      // Now displays Resume!
      expect(find.text('Resume'), findsWidgets);
    });

    testWidgets('TvShowDetailsScreen shows Resume only when exact targeted episode has progress', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const tvShow = MediaItem(
        id: '900',
        title: 'Succession',
        imageUrl: 'https://example.com/succession.jpg',
        genres: ['Drama'],
        mediaType: 'tv',
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: TvShowDetailsScreen(tvData: tvShow),
          ),
        ),
      );
      await tester.pump();

      // Initially Watch Now
      expect(find.text('Watch Now'), findsWidgets);
      expect(find.text('Resume'), findsNothing);

      // Save progress for S1E2 (NOT S1E1 which is the target of the main Watch Now button)
      await repo.saveProgress(
        mediaType: 'tv',
        tmdbId: '900',
        title: 'Succession',
        imageUrl: 'https://example.com/succession.jpg',
        season: 1,
        episode: 2,
        positionMs: 600000,
        durationMs: 3600000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: TvShowDetailsScreen(tvData: tvShow),
          ),
        ),
      );
      await tester.pump();

      // S1E1 still has no progress, so main button stays Watch Now!
      expect(find.text('Watch Now'), findsWidgets);
      expect(find.text('Resume'), findsNothing);

      // Now save progress for S1E1
      await repo.saveProgress(
        mediaType: 'tv',
        tmdbId: '900',
        title: 'Succession',
        imageUrl: 'https://example.com/succession.jpg',
        season: 1,
        episode: 1,
        positionMs: 600000,
        durationMs: 3600000,
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            continueWatchingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: TvShowDetailsScreen(tvData: tvShow),
          ),
        ),
      );
      await tester.pump();

      // Now S1E1 has progress, button shows Resume!
      expect(find.text('Resume'), findsWidgets);
    });
  });
}
