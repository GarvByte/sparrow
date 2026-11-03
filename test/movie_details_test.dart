import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/about_page/data/cast_member.dart';
import 'package:sparrow/features/about_page/data/movie_detail_info.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/about_page/widgets/movie_audio_dropdown.dart';
import 'package:sparrow/features/home%20page/screen/home_page.dart';
import 'package:sparrow/main.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';

void main() {
  group('Movie Details Models & Formatting Tests', () {
    test('CastMember parses from JSON correctly', () {
      final member = CastMember.fromJson({
        'id': 1190668,
        'name': 'Timothée Chalamet',
        'character': 'Paul Atreides',
        'profile_path': '/dFxpwRpmzpVfP1zjluH68DeQhyj.jpg',
      });

      expect(member.name, 'Timothée Chalamet');
      expect(member.character, 'Paul Atreides');
      expect(member.profileUrl, contains('dFxpwRpmzpVfP1zjluH68DeQhyj.jpg'));
    });

    test(
      'MovieDetailInfo parses TMDB json and formats runtime and currencies',
      () {
        final json = {
          'id': 693134,
          'title': 'Dune: Part Two',
          'adult': false,
          'overview': 'Follow the mythic journey of Paul Atreides...',
          'backdrop_path': '/eZ239CUp1d6OryZEBPnO2n87gMG.jpg',
          'poster_path': '/6izwz7rsy95ARzTR3poZ8H6c5pp.jpg',
          'release_date': '2024-03-01',
          'runtime': 166,
          'vote_average': 8.6,
          'budget': 190000000,
          'revenue': 714400000,
          'genres': [
            {'id': 878, 'name': 'Sci-Fi'},
            {'id': 12, 'name': 'Adventure'},
          ],
          'production_companies': [
            {'name': 'Legendary Pictures'},
            {'name': 'Warner Bros.'},
          ],
          'spoken_languages': [
            {'english_name': 'English'},
          ],
        };

        final creditsJson = {
          'crew': [
            {'job': 'Director', 'name': 'Denis Villeneuve'},
            {'job': 'Screenplay', 'name': 'Denis Villeneuve'},
            {'job': 'Writer', 'name': 'Jon Spaihts'},
          ],
        };

        final info = MovieDetailInfo.fromTmdbJson(
          json: json,
          creditsJson: creditsJson,
        );

        expect(info.id, '693134');
        expect(info.title, 'Dune: Part Two');
        expect(info.isAdult, false);
        expect(info.runtimeFormatted, '2h 46m');
        expect(info.releaseYear, '2024');
        expect(info.releaseDateFormatted, 'March 1, 2024');
        expect(info.director, 'Denis Villeneuve');
        expect(info.writers, contains('Jon Spaihts'));
        expect(info.studios, contains('Legendary Pictures'));
        expect(info.originalLanguage, 'ENGLISH');
        expect(info.budgetFormatted, '\$190 Million');
        expect(info.revenueFormatted, '\$714.4 Million');
        expect(info.genres, ['Sci-Fi', 'Adventure']);
      },
    );

    test('MovieDetailInfo.fromMediaItem produces instant baseline', () {
      const item = MediaItem(
        id: '123',
        title: 'Initial Title',
        imageUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        genres: ['Action'],
        rating: 8.5,
        releaseDate: '2023-11-10',
        isAdult: true,
      );

      final info = MovieDetailInfo.fromMediaItem(item);
      expect(info.id, '123');
      expect(info.title, 'Initial Title');
      expect(info.releaseYear, '2023');
      expect(info.rating, 8.5);
      expect(info.genres, ['Action']);
      expect(info.isAdult, true);

      const itemWithoutAdult = MediaItem(
        id: '456',
        title: 'No adult field',
        imageUrl: '',
        genres: [],
      );
      expect(itemWithoutAdult.isAdult, false);
    });
  });

  group('MovieAudioDropdown Widget Tests', () {
    testWidgets(
      'Renders collapsed state with Original Audio selected by default',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: MovieAudioDropdown())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Audio: Original Audio'), findsOneWidget);
        expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping dropdown opens menu with exactly Hindi, Original Audio, Unverified',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: MovieAudioDropdown())),
          ),
        );
        await tester.pumpAndSettle();

        // Tap collapsed trigger
        await tester.tap(find.text('Audio: Original Audio'));
        await tester.pumpAndSettle();

        // Verify all 3 exact options are visible
        expect(find.text('Hindi'), findsOneWidget);
        expect(find.text('Original Audio'), findsOneWidget);
        expect(find.text('Unverified'), findsOneWidget);

        // Select 'Hindi'
        await tester.tap(find.text('Hindi'));
        await tester.pumpAndSettle();

        // Verify collapsed trigger updated to 'Audio: Hindi'
        expect(find.text('Audio: Hindi'), findsOneWidget);
      },
    );
  });

  group('MovieDetailsScreen Widget & Responsiveness Tests', () {
    const testMediaItem = MediaItem(
      id: '693134',
      title: 'Dune: Part Two',
      imageUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
      backdropUrl: 'https://image.tmdb.org/t/p/w500/backdrop.jpg',
      genres: ['Sci-Fi', 'Adventure'],
      rating: 8.6,
      overview: 'Paul Atreides unites with Chani and the Fremen.',
      releaseDate: '2024-03-01',
    );

    testWidgets('Renders mobile layout without overflows', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MovieDetailsScreen(movieData: testMediaItem),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);
      // Audio dropdown is commented out per TV memory & UI cleanup requirements
      expect(find.text('Audio: Original Audio'), findsNothing);
      expect(find.text('Synopsis'), findsOneWidget);
      expect(find.text('Movie Information'), findsOneWidget);
    });

    testWidgets('Renders TV layout without overflows', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MovieDetailsScreen(movieData: testMediaItem),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      // Audio dropdown is commented out per TV memory & UI cleanup requirements
      expect(find.text('Audio: Original Audio'), findsNothing);
      expect(find.text('SYNOPSIS'), findsOneWidget);
      expect(find.text('Production Matrix'), findsOneWidget);
    });

    testWidgets('Displays fallback screen when movieData is null or invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MovieDetailsScreen(movieData: null)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Movie Not Found'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets(
      'GoRouter push opens Movie Details above shell and popping returns to previous page',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        appRouter.go('/');
        await tester.pumpWidget(const ProviderScope(child: SparrowApp()));
        await tester.pump(const Duration(milliseconds: 500));

        // Home page is active
        expect(find.text('SPARROW'), findsWidgets);

        // Open Movie Details using the shared navigation helper
        final context = tester.element(find.byType(HomePage));
        openMovieDetails(context, testMediaItem);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Movie Details screen is displayed with movie title
        expect(find.text('Dune: Part Two'), findsOneWidget);
        expect(find.byType(MovieDetailsScreen), findsOneWidget);

        // Tap back button in MovieDetailsScreen
        final backButton = find.byIcon(Icons.arrow_back_ios);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Returned to Home page without errors
        expect(find.byType(HomePage), findsOneWidget);
      },
    );
  });
}
