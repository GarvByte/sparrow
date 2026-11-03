import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/home%20page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/features/watchlist/data/watchlist_item.dart';
import 'package:sparrow/features/watchlist/data/watchlist_repository.dart';
import 'package:sparrow/features/watchlist/providers/watchlist_provider.dart';
import 'package:sparrow/features/watchlist/screen/watchlist_page.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  group('WatchlistItem Model & Identity Tests', () {
    test('Composite key prevents collision between movie and TV show with identical IDs', () {
      final movieKey = WatchlistItem.compositeKey('movie', '12345');
      final tvKey = WatchlistItem.compositeKey('tv', '12345');

      expect(movieKey, 'movie_12345');
      expect(tvKey, 'tv_12345');
      expect(movieKey, isNot(equals(tvKey)));
    });

    test('WatchlistItem converts accurately to MediaItem with correct badges', () {
      const movieItem = WatchlistItem(
        id: '550',
        mediaType: 'movie',
        title: 'Fight Club',
        imageUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
        rating: 8.4,
        genres: ['Drama'],
        releaseDate: '1999-10-15',
        overview: 'An insomniac office worker...',
      );

      final mediaItem = movieItem.toMediaItem();
      expect(mediaItem.id, '550');
      expect(mediaItem.title, 'Fight Club');
      expect(mediaItem.isTvShow, false);
      expect(mediaItem.mediaType, 'movie');
      expect(mediaItem.bottomBadge, 'MOVIE');

      const tvItem = WatchlistItem(
        id: '1396',
        mediaType: 'tv',
        title: 'Breaking Bad',
        imageUrl: 'https://image.tmdb.org/t/p/w500/bb.jpg',
        rating: 9.5,
        genres: ['Drama', 'Crime'],
        releaseDate: '2008-01-20',
      );

      final tvMediaItem = tvItem.toMediaItem();
      expect(tvMediaItem.id, '1396');
      expect(tvMediaItem.title, 'Breaking Bad');
      expect(tvMediaItem.isTvShow, true);
      expect(tvMediaItem.mediaType, 'tv');
      expect(tvMediaItem.bottomBadge, 'TV SHOW');
    });

    test('WatchlistItem.fromMediaItem correctly constructs item', () {
      const original = MediaItem(
        id: '999',
        title: 'Interstellar',
        imageUrl: 'https://image.tmdb.org/interstellar.jpg',
        genres: ['Sci-Fi', 'Adventure'],
        rating: 8.6,
        releaseDate: '2014-11-07',
        overview: 'A team of explorers travel through a wormhole...',
      );

      final watchlistItem = WatchlistItem.fromMediaItem(original);
      expect(watchlistItem.id, '999');
      expect(watchlistItem.title, 'Interstellar');
      expect(watchlistItem.mediaType, 'movie');
      expect(watchlistItem.genres, ['Sci-Fi', 'Adventure']);
      expect(watchlistItem.addedAt, isNotNull);
    });
  });

  group('WatchlistRepository & Persistence Operations', () {
    late WatchlistRepository repository;

    setUp(() {
      repository = WatchlistRepository();
    });

    test('Starts empty and persists movie and TV show distinctly', () async {
      expect(repository.getAllItems(), isEmpty);

      const movie = WatchlistItem(
        id: '100',
        mediaType: 'movie',
        title: 'Inception',
        imageUrl: '',
      );

      const tv = WatchlistItem(
        id: '100',
        mediaType: 'tv',
        title: 'Severance',
        imageUrl: '',
      );

      await repository.addItem(movie);
      expect(repository.isWatchlisted('movie', '100'), true);
      expect(repository.isWatchlisted('tv', '100'), false);

      await repository.addItem(tv);
      expect(repository.isWatchlisted('movie', '100'), true);
      expect(repository.isWatchlisted('tv', '100'), true);

      final all = repository.getAllItems();
      expect(all.length, 2);
      expect(all.any((i) => i.title == 'Inception' && !i.isTvShow), true);
      expect(all.any((i) => i.title == 'Severance' && i.isTvShow), true);

      await repository.removeItem('movie', '100');
      expect(repository.isWatchlisted('movie', '100'), false);
      expect(repository.isWatchlisted('tv', '100'), true);
      expect(repository.getAllItems().length, 1);
    });

    test('toggleItem adds when absent and removes when present', () async {
      const item = WatchlistItem(
        id: '777',
        mediaType: 'movie',
        title: 'The Dark Knight',
        imageUrl: '',
      );

      final added = await repository.toggleItem(item);
      expect(added, true);
      expect(repository.isWatchlisted('movie', '777'), true);

      final removed = await repository.toggleItem(item);
      expect(removed, false);
      expect(repository.isWatchlisted('movie', '777'), false);
    });
  });

  group('Riverpod Reactive Synchronization Tests', () {
    test('WatchlistNotifier and isWatchlistedProvider react immediately to mutations', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(watchlistProvider), isEmpty);
      expect(
        container.read(
          isWatchlistedProvider((mediaType: 'movie', id: '200')),
        ),
        false,
      );

      const movie = WatchlistItem(
        id: '200',
        mediaType: 'movie',
        title: 'Oppenheimer',
        imageUrl: '',
      );

      // Add item
      await container.read(watchlistProvider.notifier).add(movie);

      expect(container.read(watchlistProvider).length, 1);
      expect(
        container.read(
          isWatchlistedProvider((mediaType: 'movie', id: '200')),
        ),
        true,
      );
      // TV show with same numeric ID is not affected
      expect(
        container.read(
          isWatchlistedProvider((mediaType: 'tv', id: '200')),
        ),
        false,
      );

      // Toggle off
      await container.read(watchlistProvider.notifier).toggle(movie);
      expect(container.read(watchlistProvider), isEmpty);
      expect(
        container.read(
          isWatchlistedProvider((mediaType: 'movie', id: '200')),
        ),
        false,
      );
    });
  });

  group('FloatingBottomNav & Route Tests', () {
    testWidgets('Fourth tab is named Watchlist and uses bookmarks icon', (
      tester,
    ) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                FloatingBottomNav(
                  currentIndex: selectedTab,
                  onTabSelected: (index) => selectedTab = index,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Tv Shows'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);

      expect(find.byIcon(Icons.bookmarks_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNothing);

      await tester.tap(find.text('Watchlist'));
      expect(selectedTab, 3);
    });
  });

  group('DiscoverPosterCard Search Overlay Removal', () {
    testWidgets('DiscoverPosterCard defaults to hiding bookmark overlay', (
      tester,
    ) async {
      const item = MediaItem(
        id: '1',
        title: 'Dune Part Two',
        imageUrl: '',
        genres: ['Sci-Fi'],
        rating: 8.8,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscoverPosterCard(
              item: item,
              width: 140,
            ),
          ),
        ),
      );

      // Confirm title and details are present
      expect(find.text('Dune Part Two'), findsOneWidget);
      // Confirm bookmark icon overlay is not present
      expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    });
  });

  group('WatchlistPage Widget Tests', () {
    testWidgets('Renders empty state with CTA when no items in watchlist', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WatchlistPage(),
          ),
        ),
      );

      expect(find.text('WATCHLIST'), findsOneWidget);
      expect(find.text('Your Watchlist is Empty'), findsOneWidget);
      expect(find.text('Explore Titles'), findsOneWidget);
      expect(find.byIcon(Icons.bookmarks_outlined), findsOneWidget);
    });

    testWidgets('Renders items, filter chips, and updates on filter selection', (
      tester,
    ) async {
      final repository = WatchlistRepository();
      await repository.addItem(
        const WatchlistItem(
          id: '1',
          mediaType: 'movie',
          title: 'The Matrix',
          imageUrl: '',
          rating: 8.7,
        ),
      );
      await repository.addItem(
        const WatchlistItem(
          id: '2',
          mediaType: 'tv',
          title: 'Succession',
          imageUrl: '',
          rating: 8.9,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: WatchlistPage(),
          ),
        ),
      );

      // Verify header and filter chips
      expect(find.text('WATCHLIST'), findsOneWidget);
      expect(find.text('Saved Titles'), findsOneWidget);
      expect(find.text('2 titles'), findsOneWidget);
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Movies (1)'), findsOneWidget);
      expect(find.text('TV Shows (1)'), findsOneWidget);

      // Both items visible initially
      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Succession'), findsOneWidget);

      // Filter by Movies
      await tester.tap(find.text('Movies (1)'));
      await tester.pumpAndSettle();

      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Succession'), findsNothing);

      // Filter by TV Shows
      await tester.tap(find.text('TV Shows (1)'));
      await tester.pumpAndSettle();

      expect(find.text('The Matrix'), findsNothing);
      expect(find.text('Succession'), findsOneWidget);

      // Filter back to All
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();

      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Succession'), findsOneWidget);
    });
  });

  group('Details Screens Watchlist & Download Button Tests', () {
    testWidgets('MovieDetailsScreen toggles My List to In My List and lacks Download button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = MediaItem(
        id: '600',
        title: 'Gladiator',
        imageUrl: '',
        genres: ['Action', 'Drama'],
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MovieDetailsScreen(movieData: item),
          ),
        ),
      );

      // Initial state: not saved, displays "My List"
      expect(find.text('My List'), findsOneWidget);
      expect(find.text('In My List'), findsNothing);

      // Confirm Download button is completely removed
      expect(find.byIcon(Icons.download_rounded), findsNothing);

      // Tap "My List"
      await tester.tap(find.text('My List'));
      await tester.pumpAndSettle();

      // State immediately updates to "In My List"
      expect(find.text('In My List'), findsOneWidget);
      expect(find.text('My List'), findsNothing);

      // Tap again to remove
      await tester.tap(find.text('In My List'));
      await tester.pumpAndSettle();

      expect(find.text('My List'), findsOneWidget);
      expect(find.text('In My List'), findsNothing);
    });

    testWidgets('TvShowDetailsScreen toggles My List to In My List and lacks Download button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const item = MediaItem(
        id: '700',
        title: 'Dark',
        imageUrl: '',
        genres: ['Sci-Fi', 'Mystery'],
        mediaType: 'tv',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvShowDetailsScreen(tvData: item),
          ),
        ),
      );

      expect(find.text('My List'), findsOneWidget);
      expect(find.text('In My List'), findsNothing);
      expect(find.byIcon(Icons.download_rounded), findsNothing);

      // Tap "My List"
      await tester.tap(find.text('My List'));
      await tester.pumpAndSettle();

      expect(find.text('In My List'), findsOneWidget);
      expect(find.text('My List'), findsNothing);

      // Tap again to remove
      await tester.tap(find.text('In My List'));
      await tester.pumpAndSettle();

      expect(find.text('My List'), findsOneWidget);
      expect(find.text('In My List'), findsNothing);
    });
  });

  group('ShellRoute & Tab Navigation Tests', () {
    testWidgets('GoRouter shell navigates to /watchlist and mounts WatchlistPage', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);

      // Tap Watchlist bottom nav tab
      await tester.tap(find.text('Watchlist'));
      await tester.pumpAndSettle();

      expect(find.byType(WatchlistPage), findsOneWidget);
      expect(find.text('WATCHLIST'), findsOneWidget);
    });
  });
}
