import 'package:better_player_plus/better_player_plus.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;
// ignore: implementation_imports
import 'package:better_player_plus/src/controls/better_player_clickable_widget.dart';
import 'package:sparrow/features/home%20page/widgets/continue_watching_card.dart';
import 'package:sparrow/features/player/widgets/sparrow_material_controls.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/theme/color_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithDpad(Widget child, {Size size = const Size(1920, 1080)}) {
    return MaterialApp(
      builder: Dpad.wrap(),
      localizationsDelegates: const [
        mui.GlobalMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: child),
      ),
    );
  }

  group('ContinueWatchingCard TV D-pad Focus and Close Button Tests', () {
    testWidgets('Close button is reachable from card using D-pad UP on TV',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool removeCalled = false;
      bool tapCalled = false;

      final testItem = MediaItem(
        id: '12345',
        title: 'Test Movie',
        imageUrl: 'https://example.com/test.jpg',
        overview: 'Overview',
        rating: 8.0,
        genres: const ['Action'],
        isAdult: false,
      );

      await tester.pumpWidget(
        wrapWithDpad(
          Center(
            child: ContinueWatchingCard(
              item: testItem,
              onTap: () => tapCalled = true,
              onRemove: () => removeCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the card focusable and close button focusable
      final cardFinder = find.byType(FocusablePosterCard);
      final closeButtonFinder = find.byType(TvFocusable);

      expect(cardFinder, findsOneWidget);
      expect(closeButtonFinder, findsOneWidget);

      // Verify close button has red accent focus color styling
      final tvFocusableWidget = tester.widget<TvFocusable>(closeButtonFinder);
      expect(tvFocusableWidget.focusColor, Colors.redAccent);

      // Focus the card
      final cardFocusNode = tester.widget<FocusablePosterCard>(cardFinder).focusNode;
      expect(cardFocusNode, isNotNull);
      cardFocusNode!.requestFocus();
      await tester.pump();
      expect(cardFocusNode.hasFocus, isTrue);

      // Press D-pad UP -> focus should navigate to the close button
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      final closeFocusNode = tester.widget<TvFocusable>(closeButtonFinder).focusNode;
      expect(closeFocusNode, isNotNull);
      expect(closeFocusNode!.hasFocus, isTrue);

      // Press D-pad DOWN -> focus returns to the card
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(cardFocusNode.hasFocus, isTrue);

      // Return to close button and select it
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(closeFocusNode.hasFocus, isTrue);

      // Press Select/Enter key on close button
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(removeCalled, isTrue);
      expect(tapCalled, isFalse);
    });
  });

  group('TV Progress Bar D-pad Navigation and Seeking Tests', () {
    testWidgets(
        'TV progress bar is reachable via D-pad Down from Fullscreen and has green border effects',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controlsConfig = BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.custom,
        customControlsBuilder:
            (controller, onControlsVisibilityChanged, controlsConfiguration) {
          return SparrowMaterialControls(
            controller: controller,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
            controlsConfiguration: controlsConfiguration,
          );
        },
        showControlsOnInitialize: true,
        enableFullscreen: true,
        enableOverflowMenu: true,
        enableSkips: true,
        enablePlayPause: true,
        enableProgressBar: true,
      );

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          controlsConfiguration: controlsConfig,
          autoPlay: false,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          'https://example.com/test.mp4',
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrapWithDpad(
          BetterPlayer(controller: controller),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Find progress bar focus node
      final focusables = find.byType(DpadFocusable);
      final progressBarFinder = find.byWidgetPredicate((widget) {
        return widget is DpadFocusable &&
            widget.focusNode?.debugLabel == 'player_progress_bar';
      });

      expect(progressBarFinder, findsOneWidget);

      final pbWidget = tester.widget<DpadFocusable>(progressBarFinder);
      expect(pbWidget.effects, isNotNull);
      final hasGreenBorder = pbWidget.effects!.any(
        (e) => e is DpadBorderEffect && e.color == ColorPalette.primaryGreen,
      );
      expect(hasGreenBorder, isTrue);

      // Verify traversal path: Fullscreen -> Down -> Progress Bar
      final fullscreenFocusNode = tester
          .widgetList<DpadFocusable>(focusables)
          .firstWhere((df) => df.focusNode?.debugLabel == 'player_fullscreen')
          .focusNode;

      fullscreenFocusNode!.requestFocus();
      await tester.pump();
      expect(fullscreenFocusNode.hasFocus, isTrue);

      // Press Down from Fullscreen -> moves to Progress Bar
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(pbWidget.focusNode?.hasFocus, isTrue);

      // Press Up from Progress Bar -> moves back to Fullscreen
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(fullscreenFocusNode.hasFocus, isTrue);
    });
  });

  group('Skip 10s Button Highlight Tests (TV vs Mobile)', () {
    testWidgets('TV displays highlight effects on skip 10s buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controlsConfig = BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.custom,
        customControlsBuilder:
            (controller, onControlsVisibilityChanged, controlsConfiguration) {
          return SparrowMaterialControls(
            controller: controller,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
            controlsConfiguration: controlsConfiguration,
          );
        },
        showControlsOnInitialize: true,
        enableFullscreen: true,
        enableOverflowMenu: true,
        enableSkips: true,
        enablePlayPause: true,
      );

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          controlsConfiguration: controlsConfig,
          autoPlay: false,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          'https://example.com/test.mp4',
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrapWithDpad(
          BetterPlayer(controller: controller),
          size: const Size(1920, 1080),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final focusables = find.byType(DpadFocusable);
      final skipBackFocusable = tester
          .widgetList<DpadFocusable>(focusables)
          .firstWhere((df) => df.focusNode?.debugLabel == 'player_skip_back');
      final skipForwardFocusable = tester
          .widgetList<DpadFocusable>(focusables)
          .firstWhere((df) => df.focusNode?.debugLabel == 'player_skip_forward');

      // On TV, effects must be present with DpadBorderEffect and DpadGlowEffect
      expect(skipBackFocusable.effects, isNotEmpty);
      expect(
        skipBackFocusable.effects!.any((e) => e is DpadBorderEffect),
        isTrue,
      );
      expect(skipForwardFocusable.effects, isNotEmpty);
      expect(
        skipForwardFocusable.effects!.any((e) => e is DpadBorderEffect),
        isTrue,
      );
    });

    testWidgets(
        'Mobile disables highlight effects on skip 10s buttons and uses clickable widgets',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controlsConfig = BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.custom,
        customControlsBuilder:
            (controller, onControlsVisibilityChanged, controlsConfiguration) {
          return SparrowMaterialControls(
            controller: controller,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
            controlsConfiguration: controlsConfiguration,
          );
        },
        showControlsOnInitialize: true,
        enableFullscreen: true,
        enableOverflowMenu: true,
        enableSkips: true,
        enablePlayPause: true,
      );

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          controlsConfiguration: controlsConfig,
          autoPlay: false,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          'https://example.com/test.mp4',
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrapWithDpad(
          BetterPlayer(controller: controller),
          size: const Size(390, 844),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // On Mobile, skip buttons are BetterPlayerMaterialClickableWidgets (not DpadFocusable)
      final clickableWidgets = find.byType(BetterPlayerMaterialClickableWidget);
      expect(clickableWidgets, findsWidgets);

      // Verify that no DpadFocusable has player_skip_back or player_skip_forward
      final focusables = find.byType(DpadFocusable);
      final hasSkipBackDpad = tester
          .widgetList<DpadFocusable>(focusables)
          .any((df) => df.focusNode?.debugLabel == 'player_skip_back');
      final hasSkipForwardDpad = tester
          .widgetList<DpadFocusable>(focusables)
          .any((df) => df.focusNode?.debugLabel == 'player_skip_forward');

      expect(hasSkipBackDpad, isFalse);
      expect(hasSkipForwardDpad, isFalse);

      // Verify skip buttons have InkWell / clickable interaction
      final skipBackFinder = find.byIcon(controlsConfig.skipBackIcon);
      expect(skipBackFinder, findsOneWidget);

      final skipForwardFinder = find.byIcon(controlsConfig.skipForwardIcon);
      expect(skipForwardFinder, findsOneWidget);

      // Tapping the skip back button triggers cleanly without throwing
      await tester.tap(skipBackFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Tapping the skip forward button triggers cleanly without throwing
      await tester.tap(skipForwardFinder);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
