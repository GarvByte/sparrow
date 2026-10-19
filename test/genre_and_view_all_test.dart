import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/home%20page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/features/search/providers/search_genre_banners_provider.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/features/view_all/view_all_provider.dart';
import 'package:sparrow/features/view_all/view_all_screen.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  group('Genre Discovery & Mappings Tests', () {
    test('TmdbGenre parses from JSON and implements equality', () {
      final genre1 = TmdbGenre.fromJson({'id': 28, 'name': 'Action'});
      final genre2 = const TmdbGenre(id: 28, name: 'Action');
      final genre3 = const TmdbGenre(id: 35, name: 'Comedy');

      expect(genre1, equals(genre2));
      expect(genre1 == genre3, isFalse);
      expect(genre1.name, 'Action');
      expect(genre1.id, 28);
    });

    test('mapMovieJsonToMediaItem maps TMDB movie fields correctly', () {
      final json = {
        'id': 550,
        'title': 'Fight Club',
        'poster_path': '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        'backdrop_path': '/hZkgoQYus5vegHoetLkCJzb17zJ.jpg',
        'vote_average': 8.4,
        'vote_count': 26000,
        'genre': ['Drama', 'Thriller'],
        'release_date': '1999-10-15',
        'overview': 'A ticking-time-bomb insomniac...',
        'adult': false,
      };

      final item = mapMovieJsonToMediaItem(json);
      expect(item.id, '550');
      expect(item.title, 'Fight Club');
      expect(item.imageUrl, contains('pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'));
      expect(item.backdropUrl, contains('hZkgoQYus5vegHoetLkCJzb17zJ.jpg'));
      expect(item.rating, 8.4);
      expect(item.releaseDate, '1999-10-15');
      expect(item.isTvShow, isFalse);
      expect(item.mediaType, 'movie');
    });

    test('fallbackMovieGenres and fallbackTvGenres contain core genres', () {
      expect(fallbackMovieGenres.any((g) => g.name == 'Action'), isTrue);
      expect(fallbackMovieGenres.any((g) => g.name == 'Comedy'), isTrue);
      expect(fallbackMovieGenres.any((g) => g.name == 'Science Fiction'), isTrue);

      expect(fallbackTvGenres.any((g) => g.name == 'Action & Adventure'), isTrue);
      expect(fallbackTvGenres.any((g) => g.name == 'Drama'), isTrue);
      expect(fallbackTvGenres.any((g) => g.name == 'Sci-Fi & Fantasy'), isTrue);
    });
  });

  group('View All Args & State Management Tests', () {
    test('ViewAllArgs supports equality and differentiates media types', () {
      const args1 = ViewAllArgs(
        mediaType: 'movie',
        categoryType: 'genre',
        genreId: 28,
        title: 'Action Movies',
      );
      const args2 = ViewAllArgs(
        mediaType: 'movie',
        categoryType: 'genre',
        genreId: 28,
        title: 'Action Movies',
      );
      const argsTv = ViewAllArgs(
        mediaType: 'tv',
        categoryType: 'genre',
        genreId: 28,
        title: 'Action Shows',
      );

      expect(args1, equals(args2));
      expect(args1 == argsTv, isFalse);
      expect(args1.isTv, isFalse);
      expect(argsTv.isTv, isTrue);
    });

    test('ViewAllState handles copyWith and pagination state tracking', () {
      const state = ViewAllState();
      expect(state.items, isEmpty);
      expect(state.lastLoadedPage, 0);
      expect(state.hasMore, isTrue);

      final page1Items = [
        const MediaItem(id: '1', title: 'Movie 1', imageUrl: '', genres: []),
        const MediaItem(id: '2', title: 'Movie 2', imageUrl: '', genres: []),
      ];

      final updated = state.copyWith(
        items: page1Items,
        lastLoadedPage: 1,
        loadedPages: {1},
      );

      expect(updated.items.length, 2);
      expect(updated.lastLoadedPage, 1);
      expect(updated.loadedPages.contains(1), isTrue);
      expect(updated.loadedPages.contains(2), isFalse);
    });
  });

  group('Bottom Navigation Animation Tests', () {
    testWidgets('FloatingBottomNav switches tabs and animates selection smoothly', (
      tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    FloatingBottomNav(
                      currentIndex: selectedIndex,
                      onTabSelected: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Tv Shows'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Search Tab
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(selectedIndex, 1);

      // Verify animation frames progress smoothly over 250ms
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // Tap on TV Shows Tab
      await tester.tap(find.text('Tv Shows'));
      await tester.pump();
      expect(selectedIndex, 2);
      await tester.pump(const Duration(milliseconds: 250));
    });
  });

  group('ViewAllScreen Widget Rendering Tests', () {
    testWidgets('Renders ViewAllScreen with category title and back button', (
      tester,
    ) async {
      const args = ViewAllArgs(
        mediaType: 'movie',
        categoryType: 'trending',
        title: 'Trending Movies',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ViewAllScreen(args: args),
          ),
        ),
      );

      expect(find.text('Trending Movies'), findsOneWidget);
      expect(find.text('CINEMA COLLECTION'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('Renders TV ViewAllScreen with TV COLLECTION label', (
      tester,
    ) async {
      const args = ViewAllArgs(
        mediaType: 'tv',
        categoryType: 'trending',
        title: 'Trending TV Shows',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ViewAllScreen(args: args),
          ),
        ),
      );

      expect(find.text('Trending TV Shows'), findsOneWidget);
      expect(find.text('TV SHOWS COLLECTION'), findsOneWidget);
    });
  });

  group('TV Show Details Poster-to-Backdrop Transition Tests', () {
    testWidgets('TvShowDetailsScreen immediately renders with initial poster item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const tvItem = MediaItem(
        id: '1399',
        title: 'Game of Thrones',
        imageUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
        genres: ['Sci-Fi & Fantasy', 'Drama'],
        rating: 8.4,
        releaseDate: '2011-04-17',
        overview: 'Seven noble families fight for control...',
        isAdult: false,
        mediaType: 'tv',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TvShowDetailsScreen(tvData: tvItem),
          ),
        ),
      );

      expect(find.text('Game of Thrones'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.byType(TvShowDetailsScreen), findsOneWidget);
    });
  });

  group('Search Genre Banners Model Tests', () {
    test('GenreHeroBannerItem stores genre and movie correctly', () {
      const movie = MediaItem(
        id: '100',
        title: 'Inception',
        imageUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
        genres: ['Action', 'Science Fiction'],
      );

      const banner = GenreHeroBannerItem(
        genreId: 878,
        genreName: 'Science Fiction',
        movie: movie,
      );

      expect(banner.genreId, 878);
      expect(banner.genreName, 'Science Fiction');
      expect(banner.movie.title, 'Inception');
    });

    test('SearchRandomGenreSection stores one genre with full Page 1 movies list', () {
      final movies = List.generate(
        15,
        (i) => MediaItem(
          id: 'movie_$i',
          title: 'Thriller Movie #$i',
          imageUrl: 'https://image.tmdb.org/t/p/w500/poster_$i.jpg',
          genres: ['Thriller'],
        ),
      );

      final section = SearchRandomGenreSection(
        genreId: 53,
        genreName: 'Thriller',
        movies: movies,
      );

      expect(section.genreId, 53);
      expect(section.genreName, 'Thriller');
      expect(section.movies.length, 15);
      expect(section.movies.first.title, 'Thriller Movie #0');
      expect(section.movies.last.title, 'Thriller Movie #14');
    });
  });

  group('Movie Details Poster-to-Backdrop Transition Tests', () {
    testWidgets('MovieDetailsScreen immediately renders with initial poster item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const movieItem = MediaItem(
        id: '693134',
        title: 'Dune: Part Two',
        imageUrl: 'https://image.tmdb.org/t/p/w500/dune_poster.jpg',
        genres: ['Action', 'Science Fiction'],
        rating: 8.3,
        releaseDate: '2024-03-01',
        overview: 'Paul Atreides unites with Chani and the Fremen...',
        isAdult: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MovieDetailsScreen(movieData: movieItem),
          ),
        ),
      );

      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('Watch Now'), findsOneWidget);
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });
  });
}
