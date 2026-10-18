import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/about_page/widgets/movie_audio_dropdown.dart';
import 'package:sparrow/features/tv_show_details/data/tv_cast_member.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/data/tv_show_detail_info.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';

void main() {
  group('TV Show Details Models & Formatting Tests', () {
    test('TvCastMember parses from JSON correctly', () {
      final member = TvCastMember.fromJson({
        'id': 17419,
        'name': 'Bryan Cranston',
        'character': 'Walter White',
        'profile_path': '/7Jahy5LZX2Fo8fGJltMreAI49hC.jpg',
      });

      expect(member.id, 17419);
      expect(member.name, 'Bryan Cranston');
      expect(member.character, 'Walter White');
      expect(member.profileUrl, contains('7Jahy5LZX2Fo8fGJltMreAI49hC.jpg'));
    });

    test('TvSeasonSummary & TvEpisodeInfo parse from JSON correctly', () {
      final season = TvSeasonSummary.fromJson({
        'id': 3572,
        'season_number': 1,
        'name': 'Season 1',
        'episode_count': 7,
        'air_date': '2008-01-20',
        'poster_path': '/1BP4xYv9ZG4ZVHkL7ocOEZBbSYH.jpg',
      });

      expect(season.seasonNumber, 1);
      expect(season.name, 'Season 1');
      expect(season.episodeCount, 7);
      expect(season.airYear, '2008');
      expect(season.posterUrl, contains('1BP4xYv9ZG4ZVHkL7ocOEZBbSYH.jpg'));

      final episode = TvEpisodeInfo.fromJson({
        'id': 62085,
        'name': 'Pilot',
        'episode_number': 1,
        'season_number': 1,
        'overview': 'A high school chemistry teacher diagnosed with lung cancer...',
        'still_path': '/ydlY3iPxe6og7SZ9vT1yXw1k5L4.jpg',
        'runtime': 58,
        'vote_average': 8.8,
        'air_date': '2008-01-20',
      });

      expect(episode.episodeNumber, 1);
      expect(episode.name, 'Pilot');
      expect(episode.episodeLabel, 'S1 E1 · Pilot');
      expect(episode.runtimeFormatted, '58 min');
      expect(episode.stillUrl, contains('ydlY3iPxe6og7SZ9vT1yXw1k5L4.jpg'));
    });

    test('TvSeasonDetail parses episode list from JSON', () {
      final seasonDetail = TvSeasonDetail.fromJson({
        'id': 3572,
        'season_number': 1,
        'name': 'Season 1',
        'air_date': '2008-01-20',
        'episodes': [
          {
            'id': 62085,
            'name': 'Pilot',
            'episode_number': 1,
            'season_number': 1,
            'overview': 'Pilot episode description',
            'still_path': '/thumb1.jpg',
            'runtime': 58,
          },
          {
            'id': 62086,
            'name': "Cat's in the Bag...",
            'episode_number': 2,
            'season_number': 1,
            'overview': 'Episode 2 description',
            'still_path': '/thumb2.jpg',
            'runtime': 48,
          },
        ],
      });

      expect(seasonDetail.seasonNumber, 1);
      expect(seasonDetail.episodes.length, 2);
      expect(seasonDetail.episodes.first.name, 'Pilot');
      expect(seasonDetail.episodes.last.name, "Cat's in the Bag...");
    });

    test('TvShowDetailInfo parses full TMDB TV json correctly', () {
      final json = {
        'id': 1396,
        'name': 'Breaking Bad',
        'original_name': 'Breaking Bad',
        'adult': false,
        'overview': 'A chemistry teacher diagnosed with inoperable lung cancer...',
        'backdrop_path': '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
        'poster_path': '/ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg',
        'first_air_date': '2008-01-20',
        'last_air_date': '2013-09-29',
        'status': 'Ended',
        'number_of_seasons': 5,
        'number_of_episodes': 62,
        'episode_run_time': [47],
        'vote_average': 9.5,
        'vote_count': 14000,
        'original_language': 'en',
        'genres': [
          {'id': 18, 'name': 'Drama'},
          {'id': 80, 'name': 'Crime'},
        ],
        'created_by': [
          {'id': 66633, 'name': 'Vince Gilligan'},
        ],
        'production_companies': [
          {'name': 'High Bridge Productions'},
          {'name': 'Gran Via Productions'},
        ],
        'seasons': [
          {
            'id': 3572,
            'season_number': 1,
            'name': 'Season 1',
            'episode_count': 7,
            'air_date': '2008-01-20',
          },
          {
            'id': 3573,
            'season_number': 2,
            'name': 'Season 2',
            'episode_count': 13,
            'air_date': '2009-03-08',
          },
        ],
      };

      final info = TvShowDetailInfo.fromTmdbJson(json: json);

      expect(info.id, '1396');
      expect(info.name, 'Breaking Bad');
      expect(info.title, 'Breaking Bad');
      expect(info.isAdult, false);
      expect(info.numberOfSeasons, 5);
      expect(info.seasonsFormatted, '5 Seasons');
      expect(info.numberOfEpisodes, 62);
      expect(info.episodesFormatted, '62 Episodes');
      expect(info.firstAirYear, '2008');
      expect(info.lastAirYear, '2013');
      expect(info.airYearsFormatted, '2008–2013');
      expect(info.status, 'Ended');
      expect(info.creators, 'Vince Gilligan');
      expect(info.originalLanguage, 'ENGLISH');
      expect(info.genres, ['Drama', 'Crime']);
      expect(info.seasons.length, 2);
      expect(info.backdropUrl, contains('tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg'));
      expect(info.posterUrl, contains('ztkUQFLlC19CCMYHW9o1zWhJRNq.jpg'));
    });

    test('TvShowDetailInfo.fromMediaItem produces instant zero-latency baseline', () {
      const item = MediaItem(
        id: '1396',
        title: 'Breaking Bad',
        imageUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        genres: ['Drama'],
        rating: 9.5,
        releaseDate: '2008-01-20',
        isAdult: false,
        mediaType: 'tv',
      );

      final info = TvShowDetailInfo.fromMediaItem(item);
      expect(info.id, '1396');
      expect(info.name, 'Breaking Bad');
      expect(info.firstAirYear, '2008');
      expect(info.isAdult, false);
      expect(info.seasonsFormatted, '1 Season');
    });
  });

  group('Season Selection Provider Tests', () {
    test('SelectedSeasonNotifier tracks season selections per series ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Defaults to season 1
      expect(container.read(selectedSeasonProvider('1396')), 1);

      // Select season 3 for series 1396
      container
          .read(selectedSeasonMapProvider.notifier)
          .selectSeason('1396', 3);

      expect(container.read(selectedSeasonProvider('1396')), 3);

      // Other series remains unaffected
      expect(container.read(selectedSeasonProvider('9999')), 1);
    });
  });

  group('TV Show Navigation & MediaItem Tests', () {
    test('MediaItem mediaType defaults to movie and flags isTvShow correctly', () {
      const movieItem = MediaItem(
        id: '1',
        title: 'Dune',
        imageUrl: '',
        genres: [],
      );
      expect(movieItem.mediaType, 'movie');
      expect(movieItem.isTvShow, false);

      const tvItem = MediaItem(
        id: '2',
        title: 'Breaking Bad',
        imageUrl: '',
        genres: [],
        mediaType: 'tv',
      );
      expect(tvItem.mediaType, 'tv');
      expect(tvItem.isTvShow, true);
    });
  });

  group('TvShowDetailsScreen Widget Rendering Tests', () {
    testWidgets('Renders Mobile layout with show title, metadata, buttons, and audio dropdown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const item = MediaItem(
        id: '1396',
        title: 'Breaking Bad',
        imageUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        genres: ['Crime', 'Drama'],
        rating: 9.5,
        releaseDate: '2008-01-20',
        overview: 'A chemistry teacher diagnosed with terminal lung cancer...',
        isAdult: false,
        mediaType: 'tv',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvShowDetailsScreen(tvData: item),
          ),
        ),
      );

      // Instant baseline rendering
      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);
      expect(find.text('Synopsis'), findsOneWidget);
      expect(find.text('Not Adult'), findsOneWidget);
      expect(find.byType(MovieAudioDropdown), findsOneWidget);
    });

    testWidgets('Renders TV large-screen layout with 16:9 composition and telemetry badges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const item = MediaItem(
        id: '1396',
        title: 'Breaking Bad',
        imageUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        genres: ['Crime', 'Drama'],
        rating: 9.5,
        releaseDate: '2008-01-20',
        overview: 'A chemistry teacher diagnosed with terminal lung cancer...',
        isAdult: false,
        mediaType: 'tv',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvShowDetailsScreen(tvData: item),
          ),
        ),
      );

      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text('HEVC 2160p · HDR10+ · DOLBY ATMOS'), findsOneWidget);
      expect(find.text('SERIES DOSSIER'), findsOneWidget);
      expect(find.byType(MovieAudioDropdown), findsOneWidget);
    });
  });
}
