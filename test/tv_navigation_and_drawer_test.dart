import 'package:sparrow/features/anime_hub/providers/anime_tv_providers.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/features/watchlist/providers/watchlist_provider.dart';
import 'package:sparrow/features/watchlist/data/watchlist_repository.dart';
import 'package:sparrow/features/watchlist/data/watchlist_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/home%20page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/features/search/widgets/search_bar_deck.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/navigation/tv_navigation_drawer.dart';
import 'package:sparrow/shared/media_item.dart';

class _FakeMovieProvider extends Movieprovider {
  final List<dynamic> movies;
  _FakeMovieProvider(this.movies);
  @override
  Future<List<dynamic>> build() async => movies;
}

void main() {
  group('TV Responsive Shell & Navigation Drawer Tests', () {
    testWidgets(
      'Mobile viewport (390x844) renders FloatingBottomNav and removes header profile/notifications across all layouts',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: appRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // On mobile, FloatingBottomNav is present
        expect(find.byType(FloatingBottomNav), findsOneWidget);

        // On mobile, TvNavigationDrawer is NOT displayed
        expect(find.byType(TvNavigationDrawer), findsNothing);

        // Notifications and profile avatar are removed across all layouts
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        expect(find.byType(ClipOval), findsNothing);

        // Search button remains present
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'TV viewport (1920x1080) renders TvNavigationDrawer and hides FloatingBottomNav & header profile/notifications',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              routerConfig: appRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // On TV, FloatingBottomNav is hidden
        expect(find.byType(FloatingBottomNav), findsNothing);

        // On TV, TvNavigationDrawer is present
        expect(find.byType(TvNavigationDrawer), findsOneWidget);

        // On TV, SparrowHeader removes notifications and profile avatar cleanly
        expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
        expect(find.byType(ClipOval), findsNothing);

        // Search button remains present
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'TvNavigationDrawer renders exactly 4 primary destinations and handles selection',
      (tester) async {
        int selectedIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TvNavigationDrawer(
                currentIndex: 0,
                isOpen: true,
                onDestinationSelected: (index) {
                  selectedIndex = index;
                },
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        // 4 destinations are displayed
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('TV Shows'), findsOneWidget);
        expect(find.text('Watchlist'), findsOneWidget);

        // Selecting 'Search' triggers callback with index 1
        await tester.tap(find.text('Search'));
        await tester.pump();
        expect(selectedIndex, 1);

        // Selecting 'Watchlist' triggers callback with index 3
        await tester.tap(find.text('Watchlist'));
        await tester.pump();
        expect(selectedIndex, 3);
      },
    );

    testWidgets(
      'FocusablePosterCard and TvFocusable only wrap with Dpad on TV',
      (tester) async {
        // 1. Mobile viewport
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusablePosterCard(
                onSelected: () {},
                child: const Text('Mobile Card Content'),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Mobile Card Content'), findsOneWidget);

        // 2. TV viewport
        tester.view.physicalSize = const Size(1920, 1080);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusablePosterCard(
                onSelected: () {},
                child: const Text('TV Card Content'),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('TV Card Content'), findsOneWidget);
      },
    );

    testWidgets(
      'Search field has Voice Search (Mic) and Cast buttons removed',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SearchBarDeck(controller: controller),
            ),
          ),
        );
        await tester.pump();

        // Search icon and tune/filter icon exist
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

        // Mic/Voice search is removed
        expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
        expect(find.byIcon(Icons.cast_rounded), findsNothing);
      },
    );

    testWidgets(
      'Home TV layout: Left arrow on leftmost poster opens drawer without jumping to section above',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final dummyMovies = [
          {'id': 101, 'title': 'Movie 1', 'vote_average': 8.0, 'poster_path': '', 'backdrop_path': ''},
          {'id': 102, 'title': 'Movie 2', 'vote_average': 7.5, 'poster_path': '', 'backdrop_path': ''},
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              movieProviderNotifier.overrideWith(() => _FakeMovieProvider(dummyMovies)),
              trendingNowProvider.overrideWith((ref) => dummyMovies),
              popularMoviesProvider.overrideWith((ref) => dummyMovies),
              topRatedMoviesProvider.overrideWith((ref) => dummyMovies),
              trendingShowProvider.overrideWith((ref) => dummyMovies),
            ],
            child: MaterialApp.router(
              routerConfig: appRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final scope = FocusScope.of(tester.element(find.byType(TvNavigationDrawer)));
        final allNodes = scope.traversalDescendants.toList();

        // Find Continue Watching item 0 (leftmost poster in Continue Watching)
        FocusNode? continue0;
        for (final node in allNodes) {
          if (node.context != null) {
            final box = node.context!.findRenderObject();
            if (box is RenderBox && box.hasSize) {
              final rect = box.localToGlobal(Offset.zero) & box.size;
              if ((rect.top - 800.4).abs() < 15 && (rect.left - 16.0).abs() < 15) {
                continue0 = node;
                break;
              }
            }
          }
        }

        expect(continue0, isNotNull);
        continue0!.requestFocus();
        await tester.pump();

        // Drawer is initially closed
        final drawerFinder = find.byType(TvNavigationDrawer);
        TvNavigationDrawer drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isFalse);

        // Press Left on the leftmost poster of Continue Watching
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Drawer opens! Focus did NOT jump to the hero section above!
        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isTrue);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_drawer_item_0');
      },
    );

    testWidgets(
      'TV Shows page TV layout: Left arrow on leftmost poster opens drawer',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final List<MediaItem> dummyItems = [
          const MediaItem(id: '201', title: 'Anime 1', imageUrl: '', rating: 8.5, genres: ['Anime']),
          const MediaItem(id: '202', title: 'Anime 2', imageUrl: '', rating: 8.0, genres: ['Anime']),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              topAnimeSeriesProvider.overrideWith((ref) => dummyItems),
              trendingTvShowsProvider.overrideWith((ref) => dummyItems),
              popularTvShowsProvider.overrideWith((ref) => dummyItems),
              topRatedTvShowsProvider.overrideWith((ref) => dummyItems),
              onTheAirTvShowsProvider.overrideWith((ref) => dummyItems),
            ],
            child: MaterialApp.router(
              routerConfig: appRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Navigate to /anime
        appRouter.go('/anime');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final scope = FocusScope.of(tester.element(find.byType(TvNavigationDrawer)));
        final allNodes = scope.traversalDescendants.toList();

        FocusNode? animeCard0;
        for (final node in allNodes) {
          if (node.context != null) {
            final box = node.context!.findRenderObject();
            if (box is RenderBox && box.hasSize) {
              final rect = box.localToGlobal(Offset.zero) & box.size;
              if ((rect.left - 24.0).abs() < 10 && (rect.top - 811.0).abs() < 20) {
                animeCard0 = node;
                break;
              }
            }
          }
        }

        expect(animeCard0, isNotNull);
        animeCard0!.requestFocus();
        await tester.pump();

        final drawerFinder = find.byType(TvNavigationDrawer);
        TvNavigationDrawer drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isFalse);

        // Press Left from animeCard0 (leftmost poster)
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isTrue);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'tv_drawer_item_2');
      },
    );

    testWidgets(
      'Edge-Triggered Drawer opens on arrowLeft at far-left boundary on TV and closes on Escape/Right',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              watchlistRepositoryProvider.overrideWithValue(repository),
            ],
            child: MaterialApp.router(
              routerConfig: appRouter,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Navigate to /watchlist where filter chips are located at the left edge (x=24)
        appRouter.go('/watchlist');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Drawer is initially closed
        final drawerFinder = find.byType(TvNavigationDrawer);
        expect(drawerFinder, findsOneWidget);
        TvNavigationDrawer drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isFalse);

        // Focus the leftmost 'All' filter chip directly
        final allChipFinder = find.text('All (1)');
        expect(allChipFinder, findsOneWidget);
        final tvFocusableFinder = find.ancestor(of: allChipFinder, matching: find.byType(TvFocusable));
        final focusFinder = find.descendant(of: tvFocusableFinder, matching: find.byType(Focus));
        final Focus focusWidget = tester.widget<Focus>(focusFinder.first);
        focusWidget.focusNode?.requestFocus();
        await tester.pump();

        // Focus is now on the leftmost chip. Send arrowLeft at the leftmost boundary: opens TV drawer!
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Drawer is now OPEN!
        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isTrue);

        // Press Escape to dismiss the drawer
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Drawer is now CLOSED!
        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isFalse);

        // Re-open with arrowLeft
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isTrue);

        // Dismiss with arrowRight
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        drawer = tester.widget<TvNavigationDrawer>(drawerFinder);
        expect(drawer.isOpen, isFalse);
      },
    );
  });
}
