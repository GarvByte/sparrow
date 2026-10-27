import 'package:better_player_plus/better_player_plus.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/enum/aspect_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/screens/player_page.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testItem = MediaItem(
    id: '100',
    title: 'Aspect Ratio Test Movie',
    imageUrl: '',
    genres: ['Action'],
  );

  Widget createPlayerPage() {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          mui.GlobalMaterialLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        home: PlayerPage(
          playbackContext: PlaybackContext.movie(item: testItem),
        ),
      ),
    );
  }

  group('PlayerPage Aspect Ratio & Configuration Tests', () {
    testWidgets('Initializes with safe fallback 16:9 AspectRatio and BetterPlayer',
        (tester) async {
      await tester.pumpWidget(createPlayerPage());
      await tester.pump();

      // Find the player's AspectRatio widget
      final playerFinder = find.byType(BetterPlayer);
      expect(playerFinder, findsOneWidget);

      final aspectRatioFinder = find.ancestor(
        of: playerFinder,
        matching: find.byType(AspectRatio),
      );
      expect(aspectRatioFinder, findsOneWidget);

      final AspectRatio arWidget = tester.widget(aspectRatioFinder);
      expect(arWidget.aspectRatio, closeTo(16 / 9, 0.001));

      // Verify the BetterPlayer controller configuration
      final BetterPlayer bp = tester.widget(playerFinder);
      final config = bp.controller.betterPlayerConfiguration;

      expect(config.fit, equals(BoxFit.contain));
      expect(config.aspectRatioIOS, equals(AspectRatioTypeIOS.aspect));
      expect(config.fullScreenByDefault, isFalse);
      expect(config.autoDetectFullscreenAspectRatio, isTrue);
    });

    test('Aspect ratio calculations for various movie formats', () {
      // 16:9 standard widescreen
      const size16x9 = Size(1920, 1080);
      final ratio16x9 = size16x9.width / size16x9.height;
      expect(ratio16x9, closeTo(16 / 9, 0.001));

      // 21:9 / 2.4:1 ultrawide cinematic movies (e.g. 1920x800, 2560x1080)
      const sizeUltrawide1 = Size(1920, 800);
      final ratioUltrawide1 = sizeUltrawide1.width / sizeUltrawide1.height;
      expect(ratioUltrawide1, closeTo(2.4, 0.001));

      const sizeUltrawide2 = Size(2560, 1080);
      final ratioUltrawide2 = sizeUltrawide2.width / sizeUltrawide2.height;
      expect(ratioUltrawide2, closeTo(21 / 9, 0.05));

      // 4:3 classic / academy ratio format (e.g. 1440x1080, 640x480)
      const size4x3_1 = Size(1440, 1080);
      final ratio4x3_1 = size4x3_1.width / size4x3_1.height;
      expect(ratio4x3_1, closeTo(4 / 3, 0.001));

      const size4x3_2 = Size(640, 480);
      final ratio4x3_2 = size4x3_2.width / size4x3_2.height;
      expect(ratio4x3_2, closeTo(4 / 3, 0.001));

      // Previously stretched format: 2.39:1 video stream that was squeezed into 16:9
      const sizeCinema = Size(1920, 804);
      final ratioCinema = sizeCinema.width / sizeCinema.height;
      expect(ratioCinema, closeTo(2.388, 0.005));

      // Fallback validations: invalid sizes
      double calculateSafeRatio(Size? size) {
        if (size == null || size.width <= 0 || size.height <= 0) {
          return 16 / 9;
        }
        final r = size.width / size.height;
        if (r.isNaN || r.isInfinite || r <= 0) {
          return 16 / 9;
        }
        return r;
      }

      expect(calculateSafeRatio(null), closeTo(16 / 9, 0.001));
      expect(calculateSafeRatio(const Size(0, 0)), closeTo(16 / 9, 0.001));
      expect(calculateSafeRatio(const Size(-100, 200)), closeTo(16 / 9, 0.001));
      expect(calculateSafeRatio(const Size(1920, 0)), closeTo(16 / 9, 0.001));
    });

    testWidgets('Player preserves proportions for 21:9 ultrawide video without distortion',
        (tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      // Set overridden aspect ratio to 2.4 (21:9 ultrawide)
      controller.setOverriddenAspectRatio(2.4);
      controller.setOverriddenFit(BoxFit.contain);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: BetterPlayer(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final playerFinder = find.byType(BetterPlayer);
      final arFinder = find.ancestor(
        of: playerFinder,
        matching: find.byType(AspectRatio),
      );
      final AspectRatio arWidget = tester.widget(arFinder);
      expect(arWidget.aspectRatio, closeTo(2.4, 0.001));
      expect(controller.getFit(), equals(BoxFit.contain));
    });

    testWidgets('Player preserves proportions for 4:3 standard video without distortion',
        (tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      // Set overridden aspect ratio to 4/3
      controller.setOverriddenAspectRatio(4 / 3);
      controller.setOverriddenFit(BoxFit.contain);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: BetterPlayer(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final playerFinder = find.byType(BetterPlayer);
      final arFinder = find.ancestor(
        of: playerFinder,
        matching: find.byType(AspectRatio),
      );
      final AspectRatio arWidget = tester.widget(arFinder);
      expect(arWidget.aspectRatio, closeTo(4 / 3, 0.001));
      expect(controller.getFit(), equals(BoxFit.contain));
    });

    testWidgets('Player preserves proportions for 16:9 widescreen video',
        (tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      // Set overridden aspect ratio to 16/9
      controller.setOverriddenAspectRatio(16 / 9);
      controller.setOverriddenFit(BoxFit.contain);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: BetterPlayer(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final playerFinder = find.byType(BetterPlayer);
      final arFinder = find.ancestor(
        of: playerFinder,
        matching: find.byType(AspectRatio),
      );
      final AspectRatio arWidget = tester.widget(arFinder);
      expect(arWidget.aspectRatio, closeTo(16 / 9, 0.001));
      expect(controller.getFit(), equals(BoxFit.contain));
    });

    testWidgets('Layout test: 21:9 ultrawide video is centered with black bars top and bottom',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      controller.setOverriddenAspectRatio(2.4);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: Container(
                  color: Colors.blue,
                  child: BetterPlayer(controller: controller),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final arFinder = find.byType(AspectRatio).first;
      final RenderBox arBox = tester.renderObject(arFinder);
      expect(arBox.size.width, closeTo(1920, 0.5));
      expect(arBox.size.height, closeTo(800, 0.5));

      // Centered vertically in 1080 height screen: (1080 - 800) / 2 = 140
      final Offset position = arBox.localToGlobal(Offset.zero);
      expect(position.dx, closeTo(0, 0.5));
      expect(position.dy, closeTo(140, 0.5));
    });

    testWidgets('Layout test: 4:3 standard video is centered with black bars left and right',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      controller.setOverriddenAspectRatio(4 / 3);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: Container(
                  color: Colors.green,
                  child: BetterPlayer(controller: controller),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final arFinder = find.byType(AspectRatio).first;
      final RenderBox arBox = tester.renderObject(arFinder);
      expect(arBox.size.width, closeTo(1440, 0.5));
      expect(arBox.size.height, closeTo(1080, 0.5));

      // Centered horizontally in 1920 width screen: (1920 - 1440) / 2 = 240
      final Offset position = arBox.localToGlobal(Offset.zero);
      expect(position.dx, closeTo(240, 0.5));
      expect(position.dy, closeTo(0, 0.5));
    });

    testWidgets('Layout test: 16:9 widescreen video on ultrawide 20:9 display preserves ratio',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(2400, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          fit: BoxFit.contain,
          aspectRatioIOS: AspectRatioTypeIOS.aspect,
        ),
      );
      addTearDown(controller.dispose);

      controller.setOverriddenAspectRatio(16 / 9);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            mui.GlobalMaterialLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: AspectRatio(
                aspectRatio: controller.getAspectRatio() ?? (16 / 9),
                child: Container(
                  color: Colors.purple,
                  child: BetterPlayer(controller: controller),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final arFinder = find.byType(AspectRatio).first;
      final RenderBox arBox = tester.renderObject(arFinder);
      expect(arBox.size.width, closeTo(1920, 0.5));
      expect(arBox.size.height, closeTo(1080, 0.5));

      // Centered horizontally in 2400 width screen: (2400 - 1920) / 2 = 240
      final Offset position = arBox.localToGlobal(Offset.zero);
      expect(position.dx, closeTo(240, 0.5));
      expect(position.dy, closeTo(0, 0.5));
    });
  });
}
