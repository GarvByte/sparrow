import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/features/search/widgets/explore_categories_grid.dart';
import 'package:sparrow/features/search/widgets/search_bar_deck.dart';
import 'package:sparrow/features/search/widgets/search_header.dart';
import 'package:sparrow/features/search/widgets/search_results_view.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/main.dart';
import 'package:sparrow/navigation/app_router.dart';

void main() {
  group('Search & Discover Unit Tests', () {
    test(
      'Default categories contain all 6 Stitch design categories with mappings',
      () {
        final categories = CategoryItem.defaultCategories;
        expect(categories.length, equals(6));

        expect(categories[0].title, equals('Cyberpunk & Sci-Fi'));
        expect(categories[0].tmdbGenreId, equals(878));

        expect(categories[1].title, equals('Action & Adrenaline'));
        expect(categories[1].tmdbGenreId, equals(28));

        expect(categories[2].title, equals('Psychological Thriller'));
        expect(categories[2].tmdbGenreId, equals(53));

        expect(categories[3].title, equals('Animation & Disney'));
        expect(categories[3].tmdbGenreId, equals(16));

        expect(categories[4].title, equals('Mystery Odysseys'));
        expect(categories[4].tmdbGenreId, equals(9648));

        expect(categories[5].title, equals('Family'));
        expect(categories[5].tmdbGenreId, equals(10751));
      },
    );

    test(
      'MediaItem supports optional overview, releaseDate, and backdropUrl',
      () {
        const item = MediaItem(
          id: '101',
          title: 'Cyberpunk Runner',
          imageUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w500/backdrop.jpg',
          genres: ['Sci-Fi', 'Action'],
          rating: 8.9,
          overview: 'An epic dystopian adventure in neon Tokyo.',
          releaseDate: '2024-11-20',
        );

        expect(item.id, equals('101'));
        expect(item.title, equals('Cyberpunk Runner'));
        expect(item.backdropUrl, isNotNull);
        expect(item.overview, isNotNull);
        expect(item.releaseDate, equals('2024-11-20'));
      },
    );
  });

  group('Search & Discover Widget Tests', () {
    testWidgets('SearchHeader displays SPARROW branding and action icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SearchHeader())),
      );

      expect(find.text('SPARROW'), findsOneWidget);
      expect(find.byIcon(Icons.cast_rounded), findsNothing);
    });

    testWidgets('SearchBarDeck synchronizes text controller and clear button', (
      tester,
    ) async {
      final controller = TextEditingController();
      String submittedQuery = '';
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarDeck(
              controller: controller,
              onSubmitted: (val) => submittedQuery = val,
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      // Initially placeholder is visible, clear button is hidden
      expect(find.text('Search movies, actors, genres...'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Interstellar');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);

      expect(controller.text, equals('Interstellar'));
      expect(submittedQuery, equals('Interstellar'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(cleared, isTrue);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets(
      'ExploreCategoriesGrid displays all 6 categories and handles tap',
      (tester) async {
        CategoryItem? tappedCategory;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ExploreCategoriesGrid(
                    onCategoryTap: (cat) => tappedCategory = cat,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Explore Categories'), findsOneWidget);
        expect(find.text('Cyberpunk & Sci-Fi'), findsOneWidget);
        expect(find.text('Action & Adrenaline'), findsOneWidget);
        expect(find.text('Psychological Thriller'), findsOneWidget);
        expect(find.text('Animation & Disney'), findsOneWidget);
        expect(find.text('Mystery Odysseys'), findsOneWidget);
        expect(find.text('Family'), findsOneWidget);

        // Tap Cyberpunk & Sci-Fi
        await tester.tap(find.text('Cyberpunk & Sci-Fi'));
        await tester.pump();

        expect(tappedCategory, isNotNull);
        expect(tappedCategory!.title, equals('Cyberpunk & Sci-Fi'));
      },
    );

    testWidgets(
      'DiscoverPosterCard displays poster details, rank, and badges',
      (tester) async {
        const item = MediaItem(
          id: '1',
          title: 'Neon Horizon 2099',
          imageUrl: '',
          genres: ['Sci-Fi'],
          rating: 9.1,
          bottomBadge: '4K HDR',
          releaseDate: '2024-01-01',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DiscoverPosterCard(
                item: item,
                width: 140,
                showRank: true,
                rank: 1,
              ),
            ),
          ),
        );

        expect(find.text('Neon Horizon 2099'), findsOneWidget);
        expect(find.text('#1'), findsOneWidget);
        expect(find.text('4K HDR'), findsNothing);
        expect(find.text('9.1'), findsOneWidget);
        expect(find.text('Sci-Fi • 2024'), findsOneWidget);
      },
    );

    testWidgets(
      'SearchResultsView displays empty state with back button when no results',
      (tester) async {
        bool clearTriggered = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              searchQueryProvider.overrideWith(_TestQueryNotifier.new),
              searchResultsNotifier.overrideWith(_TestResultsNotifier.new),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SearchResultsView(onClear: () => clearTriggered = true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No movies found for "UnknownXYZ"'), findsOneWidget);
        expect(find.text('Back to Discover'), findsOneWidget);

        await tester.tap(find.text('Back to Discover'));
        expect(clearTriggered, isTrue);
      },
    );

    testWidgets(
      'GoRouter indexedStack preserves search query and state across tab switches',
      (tester) async {
        appRouter.go('/');
        await tester.pumpWidget(const SparrowApp());
        await tester.pumpAndSettle();

        // Initially on Home (header has 'HOME')
        expect(find.text('HOME'), findsOneWidget);

        // Tap bottom nav Search tab
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        // Now on Search page
        expect(find.text('Search movies, actors, genres...'), findsOneWidget);
        expect(find.text('Explore Categories'), findsOneWidget);

        // Enter search query
        await tester.enterText(find.byType(TextField), 'Cyberpunk');
        await tester.pumpAndSettle();
        expect(find.text('Cyberpunk'), findsOneWidget);

        // Switch back to Home tab
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('HOME'), findsOneWidget);

        // Switch back to Search tab
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        // Query 'Cyberpunk' is preserved in the indexed stack!
        expect(find.text('Cyberpunk'), findsOneWidget);
      },
    );

    testWidgets(
      'Homepage header search button navigates to Search branch and preserves state',
      (tester) async {
        appRouter.go('/');
        await tester.pumpWidget(const SparrowApp());
        await tester.pumpAndSettle();

        // Initially on Home (header has 'HOME')
        expect(find.text('HOME'), findsOneWidget);

        // Tap search icon in the homepage header
        final headerSearchBtn = find.byIcon(Icons.search_rounded);
        expect(headerSearchBtn, findsOneWidget);
        await tester.tap(headerSearchBtn);
        await tester.pumpAndSettle();

        // Should now be on Search page
        expect(find.text('Search movies, actors, genres...'), findsOneWidget);
        expect(find.text('Explore Categories'), findsOneWidget);
      },
    );

    testWidgets(
      'Search results Back action clears query and restores normal Discover page without popping tab',
      (tester) async {
        appRouter.go('/search');
        await tester.pumpWidget(const SparrowApp());
        await tester.pumpAndSettle();

        // Initially Discover content is visible
        expect(find.text('Explore Categories'), findsOneWidget);

        // Enter search query and wait for 1-second debounce
        await tester.enterText(find.byType(TextField), 'Batman');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();

        // Search Results view is now showing
        expect(find.byType(SearchResultsView), findsOneWidget);

        // Simulate Back action via Escape key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pumpAndSettle();

        // Query is cleared and normal Discover content reappears
        expect(find.byType(SearchResultsView), findsNothing);
        expect(find.text('Explore Categories'), findsOneWidget);
        expect(find.text('Search movies, actors, genres...'), findsOneWidget);
      },
    );
  });
}

class _TestQueryNotifier extends SearchQueryNotifier {
  @override
  String build() => 'UnknownXYZ';
}

class _TestResultsNotifier extends SearchResultsProvider {
  @override
  List<dynamic> build() => [];
}
