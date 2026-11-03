import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/home%20page/widgets/sparrow_header.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/screens/player_page.dart';
import 'package:sparrow/features/search/screens/search_page.dart';
import 'package:sparrow/features/search/screens/tv_search_results_page.dart';
import 'package:sparrow/features/search/widgets/search_header.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/navigation/dpad_shortcut.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  group('TV Back Bug Fixes & Branding Tests', () {
    testWidgets('Bug 1: TV remote back from Movie Details returns to TvSearchResultsPage and does not reset to Search root', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
            builder: (context, child) {
              return AppBackShortcuts(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate: Search Page -> Submit Query (push TvSearchResultsPage)
      appRouter.go('/search');
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget);

      final BuildContext searchContext = tester.element(find.byType(SearchPage));
      searchContext.push('/search/results', extra: 'pirates');
      await tester.pumpAndSettle();
      expect(find.byType(TvSearchResultsPage), findsOneWidget);

      // Select movie: Push Movie Details
      final BuildContext resultsContext = tester.element(find.byType(TvSearchResultsPage));
      resultsContext.push('/movie-details', extra: const MediaItem(
        id: '999',
        title: 'Pirates of the Caribbean',
        imageUrl: '',
        genres: [],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);

      // Platform back event from TV remote (simulating Android popRoute dispatch)
      final popped = await appRouter.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      // Details screen popped
      expect(find.byType(MovieDetailsScreen), findsNothing);
      // TvSearchResultsPage is restored with query and results intact (not reset to category view)
      expect(find.byType(TvSearchResultsPage), findsOneWidget);
    });

    testWidgets('Bug 1: TV remote back from TV Show Details returns to TvSearchResultsPage', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
            builder: (context, child) {
              return AppBackShortcuts(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.go('/search');
      await tester.pumpAndSettle();

      final BuildContext searchContext = tester.element(find.byType(SearchPage));
      searchContext.push('/search/results', extra: 'one piece');
      await tester.pumpAndSettle();
      expect(find.byType(TvSearchResultsPage), findsOneWidget);

      final BuildContext resultsContext = tester.element(find.byType(TvSearchResultsPage));
      resultsContext.push('/tv-show-details', extra: const MediaItem(
        id: '888',
        title: 'One Piece',
        imageUrl: '',
        genres: [],
        mediaType: 'tv',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(TvShowDetailsScreen), findsOneWidget);

      final popped = await appRouter.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(TvShowDetailsScreen), findsNothing);
      expect(find.byType(TvSearchResultsPage), findsOneWidget);
    });

    testWidgets('Bug 2: Physical Back on TV dismisses open player bottom sheet first, leaving player open', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: appRouter,
            builder: (context, child) {
              return AppBackShortcuts(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.push('/player', extra: PlaybackContext.movie(
        item: const MediaItem(id: '777', title: 'Black Pearl', imageUrl: '', genres: []),
        imdbId: '',
      ));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerPage), findsOneWidget);

      // Open an overflow bottom sheet
      final BuildContext playerContext = tester.element(find.byType(PlayerPage));
      showModalBottomSheet(
        context: playerContext,
        builder: (ctx) => const Text('Player Overflow Options'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Player Overflow Options'), findsOneWidget);

      // Back press 1: Should close ONLY the bottom sheet; PlayerPage remains open
      final pop1 = await appRouter.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(pop1, isTrue);
      expect(find.text('Player Overflow Options'), findsNothing);
      expect(find.byType(PlayerPage), findsOneWidget);

      // Back press 2: Closes the player
      final pop2 = await appRouter.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(pop2, isTrue);
      expect(find.byType(PlayerPage), findsNothing);
    });

    testWidgets('Header Branding renders Weathered Pirate Sparrow Logo image on SparrowHeader and SearchHeader', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: SparrowHeader(subtitle: 'HOME'),
              body: SearchHeader(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Weathered Pirate Sparrow text logo is rendered
      final logoFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == 'assets/images/sparrow_text_logo.png',
      );
      expect(logoFinder, findsNWidgets(2));
    });
  });
}
