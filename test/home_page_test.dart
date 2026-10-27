import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/main.dart';
import 'package:sparrow/features/continue_watching/data/continue_watching_repository.dart';
import 'package:sparrow/features/home page/widgets/horizontal_media_carousel.dart';
import 'package:sparrow/features/home page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/features/home page/data/mock_home_data.dart';
import 'package:sparrow/theme/color_palette.dart';

void main() {
  setUp(() async {
    final repo = ContinueWatchingRepository();
    await repo.clearAll();
    await repo.saveProgress(
      mediaType: 'movie',
      tmdbId: '693134',
      title: 'Dune: Part Two',
      imageUrl:
          'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      positionMs: 300000,
      durationMs: 7200000,
    );
  });

  tearDown(() async {
    final repo = ContinueWatchingRepository();
    await repo.clearAll();
  });

  testWidgets(
    'Sparrow Home Page renders layered featured carousel with rounded brown container on each movie card',
    (WidgetTester tester) async {
      // Provide a standard mobile viewport (390x844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SparrowApp());
      await tester.pump();

      // 1. Verify Branding Header
      expect(find.text('SPARROW'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      // 2. Verify Carousel is present without any outer wrapper container
      expect(find.byType(CarouselSlider), findsOneWidget);

      // 3. Verify the ACTIVE movie card has its own rounded brown container (#281913)
      final activeCardContainer = find.byKey(
        const Key('featured_brown_container'),
      );
      expect(activeCardContainer, findsOneWidget);

      // Check brown container decoration and color (#281913)
      final containerWidget = tester.widget<Container>(activeCardContainer);
      final boxDecoration = containerWidget.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(ColorPalette.heroContainer));
      expect(boxDecoration.borderRadius, isNotNull);

      // 4. Verify ALL elements for this movie live INSIDE its rounded brown container:
      // - Poster artwork (exact 17:16 aspect ratio)
      final posterFinder = find.descendant(
        of: activeCardContainer,
        matching: find.byType(AspectRatio),
      );
      expect(posterFinder, findsOneWidget);
      final ar = tester.widget<AspectRatio>(posterFinder);
      expect(
        (ar.aspectRatio - (16.0 / 17.0)).abs() < 0.01,
        isTrue,
        reason: 'Hero poster must use exact 16:17 aspect ratio',
      );

      // - Movie title
      expect(
        find.descendant(
          of: activeCardContainer,
          matching: find.text('DUNE: PART TWO'),
        ),
        findsOneWidget,
      );
      // - Movie badge
      expect(
        find.descendant(
          of: activeCardContainer,
          matching: find.text('MOVIE'),
        ),
        findsOneWidget,
      );
      // - Rating
      expect(
        find.descendant(of: activeCardContainer, matching: find.text('8.8')),
        findsOneWidget,
      );
      // - Watch Now button
      expect(
        find.descendant(
          of: activeCardContainer,
          matching: find.text('Watch Now'),
        ),
        findsOneWidget,
      );

      // 5. Verify pagination dots are COMPLETELY REMOVED per user requirement
      expect(find.byKey(const Key('featured_pagination_dots')), findsNothing);

      // 6. Test Horizontal Swipe to verify carousel behavior and state synchronization
      await tester.drag(find.byType(CarouselSlider), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify second featured title is now active inside its brown container
      final updatedCardContainer = find.byKey(
        const Key('featured_brown_container'),
      );
      expect(updatedCardContainer, findsOneWidget);
      expect(
        find.descendant(
          of: updatedCardContainer,
          matching: find.text(MockHomeData.featuredHeroes[1].title),
        ),
        findsOneWidget,
      );

      // 7. Verify Section Headers and Bottom Nav remain intact
      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.text('Trending Now'), findsOneWidget);
      expect(find.byType(FloatingBottomNav), findsOneWidget);

      // 8. Test Vertical Scroll down to reveal remaining sections
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pump();

      expect(find.text('Popular Movies'), findsOneWidget);

      expect(find.text('Blockbusters & Classics'), findsOneWidget);

      // 9. Test horizontal scroll on media carousels
      final carousels = find.byType(HorizontalMediaCarousel);
      if (carousels.evaluate().isNotEmpty) {
        await tester.drag(carousels.first, const Offset(-100, 0));
        await tester.pump();
      }
    },
  );

  testWidgets(
    'Sparrow Home Page adapts responsively on small phone viewport (340x640) without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(340, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SparrowApp());
      await tester.pump();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('featured_brown_container')), findsOneWidget);
      expect(find.byKey(const Key('featured_pagination_dots')), findsNothing);
      expect(find.text('SPARROW'), findsOneWidget);
    },
  );

  testWidgets(
    'Sparrow Home Page adapts responsively on large phone viewport (430x932) without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SparrowApp());
      await tester.pump();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('featured_brown_container')), findsOneWidget);
      expect(find.byKey(const Key('featured_pagination_dots')), findsNothing);
      expect(find.text('SPARROW'), findsOneWidget);
    },
  );

  testWidgets(
    'Sparrow Home Page adapts responsively on tablet viewport (800x1200) without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SparrowApp());
      await tester.pump();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('featured_brown_container')), findsOneWidget);
      expect(find.byKey(const Key('featured_pagination_dots')), findsNothing);
      expect(find.text('SPARROW'), findsOneWidget);
    },
  );
}
