import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/anime%20hub/providers/anime_tv_providers.dart';
import 'package:sparrow/features/anime%20hub/screens/anime_hub_page.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/widgets/search_filter_sheet.dart';
import 'package:sparrow/features/search/widgets/search_results_view.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  group('Search TV Shows & Filter Interface Tests', () {
    test('SearchMediaType defaults to Movies and toggles correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default must be Movies
      expect(
        container.read(searchMediaTypeProvider),
        equals(SearchMediaType.movies),
      );

      // Switch to TV Shows
      container
          .read(searchMediaTypeProvider.notifier)
          .setType(SearchMediaType.tvShows);
      expect(
        container.read(searchMediaTypeProvider),
        equals(SearchMediaType.tvShows),
      );

      // Reset switches back to Movies
      container.read(searchMediaTypeProvider.notifier).reset();
      expect(
        container.read(searchMediaTypeProvider),
        equals(SearchMediaType.movies),
      );
    });

    test('SearchSortFilter defaults to popularity and resets properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(searchFilterProvider),
        equals(SearchSortFilter.popularity),
      );

      container
          .read(searchFilterProvider.notifier)
          .setFilter(SearchSortFilter.topRated);
      expect(
        container.read(searchFilterProvider),
        equals(SearchSortFilter.topRated),
      );

      container.read(searchFilterProvider.notifier).reset();
      expect(
        container.read(searchFilterProvider),
        equals(SearchSortFilter.popularity),
      );
    });

    testWidgets('SearchFilterSheet displays centered dialog with Media Type selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => SearchFilterSheet.show(context),
                    child: const Text('Open Filters'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap to open centered dialog
      await tester.tap(find.text('Open Filters'));
      await tester.pumpAndSettle();

      // Verify dialog header
      expect(find.text('Search Filters'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Verify MEDIA TYPE section
      expect(find.text('MEDIA TYPE'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);

      // Verify SORT BY section
      expect(find.text('SORT BY'), findsOneWidget);
      expect(find.text('Popularity'), findsOneWidget);
      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('Release Date'), findsOneWidget);

      // Verify Apply button
      expect(find.text('Apply Filters'), findsOneWidget);

      // Tap TV Shows
      await tester.tap(find.text('TV Shows'));
      await tester.pumpAndSettle();

      // Tap Apply to dismiss dialog
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Search Filters'), findsNothing);
    });

    testWidgets('SearchResultsView shows TV-specific empty state and indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchMediaTypeProvider
                .overrideWith(_TestTvMediaTypeNotifier.new),
            searchQueryProvider.overrideWith(_TestTvQueryNotifier.new),
            searchResultsNotifier.overrideWith(_EmptyResultsNotifier.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SearchResultsView(onClear: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TV badge in header
      expect(find.text('TV'), findsOneWidget);
      // TV empty state
      expect(
        find.text('No TV shows found for "Shingeki"'),
        findsOneWidget,
      );
      expect(find.text('Back to Discover'), findsOneWidget);
    });

    testWidgets('SearchResultsView maps TV fields (name, first_air_date) and handles tap', (
      tester,
    ) async {
      MediaItem? tappedItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchMediaTypeProvider
                .overrideWith(_TestTvMediaTypeNotifier.new),
            searchQueryProvider.overrideWith(_TestTvQueryNotifier.new),
            searchResultsNotifier.overrideWith(_TvResultsNotifier.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SearchResultsView(
                onClear: () {},
                onMovieTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Item title mapped from 'name'
      expect(find.text('Attack on Titan'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Attack on Titan'));
      await tester.pump();

      expect(tappedItem, isNotNull);
      expect(tappedItem!.title, equals('Attack on Titan'));
      expect(tappedItem!.isTvShow, isTrue);
      expect(tappedItem!.releaseDate, equals('2013-04-07'));
    });
  });

  group('Anime Hub & TV Show Mapping Tests', () {
    test('mapTvJsonToMediaItem maps fields correctly and assigns mediaType="tv"', () {
      final json = {
        'id': 1429,
        'name': 'Attack on Titan',
        'poster_path': '/hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg',
        'backdrop_path': '/7c9UVPPiTPltouxRVY6992RqCXE.jpg',
        'vote_average': 8.9,
        'vote_count': 6120,
        'overview': 'Centuries ago, mankind was slaughtered by giant humanoids.',
        'first_air_date': '2013-04-07',
        'genre': ['Animation', 'Action & Adventure', 'Sci-Fi & Fantasy'],
      };

      final item = mapTvJsonToMediaItem(json);

      expect(item.id, equals('1429'));
      expect(item.title, equals('Attack on Titan'));
      expect(item.isTvShow, isTrue);
      expect(item.mediaType, equals('tv'));
      expect(item.rating, equals(8.9));
      expect(item.ratingCount, equals('6120'));
      expect(item.releaseDate, equals('2013-04-07'));
      expect(item.imageUrl, contains('hTP1DtLGFamjfu8WqjnuQdP1n4i.jpg'));
      expect(item.backdropUrl, contains('7c9UVPPiTPltouxRVY6992RqCXE.jpg'));
      expect(item.genres, contains('Animation'));
    });

    testWidgets('AnimeHubPage renders header with subtitle and TV show sections', (
      tester,
    ) async {
      final mockTvItems = [
        MediaItem(
          id: '1',
          title: 'Demon Slayer',
          imageUrl: '',
          genres: const ['Animation', 'Action'],
          rating: 8.7,
          releaseDate: '2019-04-06',
          mediaType: 'tv',
        ),
        MediaItem(
          id: '2',
          title: 'Jujutsu Kaisen',
          imageUrl: '',
          genres: const ['Animation', 'Fantasy'],
          rating: 8.6,
          releaseDate: '2020-10-03',
          mediaType: 'tv',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topAnimeSeriesProvider.overrideWith((ref) => Future.value(mockTvItems)),
            trendingTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            popularTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            topRatedTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            onTheAirTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
          ],
          child: const MaterialApp(
            home: AnimeHubPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Pinned header has 'ANIME & TV'
      expect(find.text('ANIME & TV'), findsOneWidget);
      expect(find.text('SPARROW'), findsOneWidget);

      // Curated TV Show sections
      expect(find.text('Top Anime & Animation'), findsOneWidget);
      expect(find.text('Trending TV Shows'), findsOneWidget);
      expect(find.text('Popular TV Shows'), findsOneWidget);
      expect(find.text('Currently Airing Series'), findsOneWidget);
      expect(find.text('Critically Acclaimed Shows'), findsOneWidget);

      // Verify TV item titles rendered
      expect(find.text('Demon Slayer'), findsWidgets);
      expect(find.text('Jujutsu Kaisen'), findsWidgets);
    });

    testWidgets('GoRouter navigates to /anime and renders AnimeHubPage', (
      tester,
    ) async {
      final mockTvItems = [
        MediaItem(
          id: '1',
          title: 'Demon Slayer',
          imageUrl: '',
          genres: const ['Animation'],
          mediaType: 'tv',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieProviderNotifier.overrideWith(_EmptyMovieNotifier.new),
            trendingNowProvider.overrideWith((ref) => Future.value([])),
            popularMoviesProvider.overrideWith((ref) => Future.value([])),
            topRatedMoviesProvider.overrideWith((ref) => Future.value([])),
            trendingShowProvider.overrideWith((ref) => Future.value([])),
            topAnimeSeriesProvider.overrideWith((ref) => Future.value(mockTvItems)),
            trendingTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            popularTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            topRatedTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
            onTheAirTvShowsProvider.overrideWith((ref) => Future.value(mockTvItems)),
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
      await tester.pump(const Duration(milliseconds: 500));

      // AnimeHubPage is displayed
      expect(find.byType(AnimeHubPage), findsOneWidget);
      expect(find.text('ANIME & TV'), findsOneWidget);
    });
  });
}

class _TestTvMediaTypeNotifier extends SearchMediaTypeNotifier {
  @override
  SearchMediaType build() => SearchMediaType.tvShows;
}

class _TestTvQueryNotifier extends SearchQueryNotifier {
  @override
  String build() => 'Shingeki';
}

class _EmptyResultsNotifier extends SearchResultsProvider {
  @override
  List<dynamic> build() => [];
}

class _EmptyMovieNotifier extends Movieprovider {
  @override
  Future<List<dynamic>> build() async => [];
}

class _TvResultsNotifier extends SearchResultsProvider {
  @override
  List<dynamic> build() {
    return [
      {
        'id': 1429,
        'name': 'Attack on Titan',
        'poster_path': '',
        'first_air_date': '2013-04-07',
        'genre': ['Animation', 'Action & Adventure'],
        'vote_average': 8.9,
        'media_type': 'tv',
      },
    ];
  }
}
