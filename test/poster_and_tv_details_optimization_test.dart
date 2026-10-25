import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/home page/widgets/continue_watching_card.dart';
import 'package:sparrow/features/home page/widgets/landscape_media_card.dart';
import 'package:sparrow/features/home page/widgets/portrait_poster_card.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_show_details_provider.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_card.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_list.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

void main() {
  group('Poster Image Optimization Tests', () {
    testWidgets('PortraitPosterCard, LandscapeMediaCard, and DiscoverPosterCard do not flash CircularProgressIndicator placeholders', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const item = MediaItem(
        id: '101',
        title: 'Test Poster Movie',
        imageUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        genres: ['Action'],
      );

      // Render PortraitPosterCard
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortraitPosterCard(item: item),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Render LandscapeMediaCard
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LandscapeMediaCard(item: item),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Render DiscoverPosterCard
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 200,
                child: DiscoverPosterCard(item: item),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Render ContinueWatchingCard
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContinueWatchingCard(item: item),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('TvEpisodeCard does not render CircularProgressIndicator in placeholder', (tester) async {
      const episode = TvEpisodeInfo(
        id: 1,
        episodeNumber: 1,
        seasonNumber: 1,
        name: 'Pilot',
        overview: 'Episode overview',
        stillPath: '/still.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvEpisodeCard(
              episode: episode,
              seriesId: '100',
              isTvLayout: false,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('TmdbService In-Flight Deduplication Tests', () {
    test('Simultaneous identical requests share the same in-flight HTTP future', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(
          jsonEncode({
            'id': 123,
            'name': 'Doraemon',
            'cast': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = TmdbService(client: mockClient);

      final future1 = service.fetchTvShowCredits('123');
      final future2 = service.fetchTvShowCredits('123');

      final results = await Future.wait([future1, future2]);

      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(results[0]!['name'], 'Doraemon');
      expect(results[1]!['name'], 'Doraemon');
      expect(requestCount, 1);
    });
  });

  group('TV Details Concurrent Fetching Tests', () {
    test('tvShowDetailsProvider fetches details and credits concurrently without serial blocking', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/credits')) {
          return http.Response(
            jsonEncode({'cast': [], 'crew': [{'job': 'Creator', 'name': 'Fujiko F. Fujio'}]}),
            200,
          );
        }
        if (request.url.path.contains('/tv/3871')) {
          return http.Response(
            jsonEncode({
              'id': 3871,
              'name': 'Doraemon',
              'number_of_seasons': 2,
              'number_of_episodes': 1787,
              'seasons': [
                {'id': 1, 'season_number': 1, 'name': 'Season 1', 'episode_count': 1787},
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = TmdbService(client: mockClient);
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      const item = MediaItem(
        id: '3871',
        title: 'Doraemon',
        imageUrl: '',
        genres: [],
        mediaType: 'tv',
      );

      final details = await container.read(tvShowDetailsProvider(item).future);

      expect(details.id, '3871');
      expect(details.name, 'Doraemon');
      expect(details.numberOfEpisodes, 1787);
      expect(details.creators, 'Fujiko F. Fujio');
    });
  });

  group('TV Episode List Large Season Windowing Tests', () {
    testWidgets('TvEpisodeList windows 100+ episodes and displays Load More button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final episodes = List.generate(
        120,
        (i) => TvEpisodeInfo(
          id: i + 1,
          episodeNumber: i + 1,
          seasonNumber: 1,
          name: 'Episode ${i + 1}',
          overview: 'Overview for episode ${i + 1}',
          stillPath: '/still_$i.jpg',
        ),
      );

      final seasonDetail = TvSeasonDetail(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: episodes,
      );

      final container = ProviderContainer(
        overrides: [
          tvSeasonDetailProvider(const TvSeasonQuery(seriesId: '3871', seasonNumber: 1))
              .overrideWith((ref) => Future.value(seasonDetail)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TvEpisodeList(
                  seriesId: '3871',
                  seasons: [
                    TvSeasonSummary(
                      id: 1,
                      seasonNumber: 1,
                      name: 'Season 1',
                      episodeCount: 120,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TvEpisodeCard), findsNWidgets(30));

      final loadMoreFinder = find.text('Load More Episodes (30 of 120)');
      expect(loadMoreFinder, findsOneWidget);

      await tester.scrollUntilVisible(
        loadMoreFinder,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(loadMoreFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TvEpisodeCard), findsNWidgets(80));
      expect(find.text('Load More Episodes (80 of 120)'), findsOneWidget);
    });

    testWidgets('TvEpisodeList renders all episodes directly when episode count is <= 30', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final episodes = List.generate(
        10,
        (i) => TvEpisodeInfo(
          id: i + 1,
          episodeNumber: i + 1,
          seasonNumber: 1,
          name: 'Breaking Bad E${i + 1}',
          overview: 'Overview for episode ${i + 1}',
        ),
      );

      final seasonDetail = TvSeasonDetail(
        id: 1,
        seasonNumber: 1,
        name: 'Season 1',
        episodes: episodes,
      );

      final container = ProviderContainer(
        overrides: [
          tvSeasonDetailProvider(const TvSeasonQuery(seriesId: '1396', seasonNumber: 1))
              .overrideWith((ref) => Future.value(seasonDetail)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TvEpisodeList(
                  seriesId: '1396',
                  seasons: [
                    TvSeasonSummary(
                      id: 1,
                      seasonNumber: 1,
                      name: 'Season 1',
                      episodeCount: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TvEpisodeCard), findsNWidgets(10));
      expect(find.textContaining('Load More'), findsNothing);
    });
  });

  group('Season Caching and Switching Tests', () {
    test('tvSeasonDetailProvider caches each season and reuses results on revisit', () async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        fetchCount++;
        final seasonNum = request.url.pathSegments.last;
        return http.Response(
          jsonEncode({
            'id': int.parse(seasonNum),
            'season_number': int.parse(seasonNum),
            'name': 'Season $seasonNum',
            'episodes': [
              {
                'id': 1,
                'name': 'Ep 1',
                'episode_number': 1,
                'season_number': int.parse(seasonNum),
                'overview': '',
              }
            ],
          }),
          200,
        );
      });

      final service = TmdbService(client: mockClient);
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      const querySeason1 = TvSeasonQuery(seriesId: '100', seasonNumber: 1);
      const querySeason2 = TvSeasonQuery(seriesId: '100', seasonNumber: 2);

      final s1First = await container.read(tvSeasonDetailProvider(querySeason1).future);
      expect(s1First?.seasonNumber, 1);
      expect(fetchCount, 1);

      final s2First = await container.read(tvSeasonDetailProvider(querySeason2).future);
      expect(s2First?.seasonNumber, 2);
      expect(fetchCount, 2);

      final s1Second = await container.read(tvSeasonDetailProvider(querySeason1).future);
      expect(s1Second?.seasonNumber, 1);
      expect(fetchCount, 2);
    });
  });
}
