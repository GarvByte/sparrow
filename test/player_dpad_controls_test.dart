import 'package:better_player_plus/better_player_plus.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;
import 'package:sparrow/features/player/widgets/sparrow_material_controls.dart';
import 'package:sparrow/theme/color_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildPlayerWithSparrowControls({
    required BetterPlayerController controller,
  }) {
    return MaterialApp(
      builder: Dpad.wrap(),
      localizationsDelegates: const [
        mui.GlobalMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(size: Size(1920, 1080)),
          child: SizedBox(
            width: 1920,
            height: 1080,
            child: BetterPlayer(controller: controller),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'Inbuilt controls have DpadFocusable with DpadBorderEffect and default focus is on Play/Pause',
      (tester) async {
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

    await tester.pumpWidget(buildPlayerWithSparrowControls(controller: controller));

    // Allow controls and post-frame callbacks to settle
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 1. Verify all 5 inbuilt controls exist as DpadFocusable widgets
    final focusableFinders = find.byType(DpadFocusable);
    expect(focusableFinders, findsWidgets);

    // Verify DpadBorderEffects are attached to each control
    final borderEffects = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .where((df) =>
            df.effects != null &&
            df.effects!.any((effect) =>
                effect is DpadBorderEffect &&
                effect.color == ColorPalette.primaryGreen))
        .toList();

    // At least: Play/Pause (center), Backward 10s, Forward 10s, Fullscreen, Overflow menu
    expect(borderEffects.length, greaterThanOrEqualTo(5));

    // 2. Verify default focus is on the Play/Pause button
    // The center play/pause has autofocus: true
    final centerPlayPauseFocusable = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.autofocus == true);
    expect(centerPlayPauseFocusable, isNotNull);
    expect(centerPlayPauseFocusable.focusNode?.hasFocus, isTrue);

    // 3. Test D-pad directional navigation
    // From Play/Pause -> press Left arrow key -> moves focus to Backward 10s
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 100));

    final skipBackFocusNode = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.focusNode?.debugLabel == 'player_skip_back')
        .focusNode;
    expect(skipBackFocusNode?.hasFocus, isTrue);

    // From Backward 10s -> press Right arrow key -> moves back to Play/Pause
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 100));
    expect(centerPlayPauseFocusable.focusNode?.hasFocus, isTrue);

    // From Play/Pause -> press Right arrow key -> moves to Forward 10s
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 100));

    final skipForwardFocusNode = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.focusNode?.debugLabel == 'player_skip_forward')
        .focusNode;
    expect(skipForwardFocusNode?.hasFocus, isTrue);

    // From Forward 10s -> press Up arrow key -> moves to Overflow menu
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 100));

    final overflowFocusNode = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.focusNode?.debugLabel == 'player_overflow')
        .focusNode;
    expect(overflowFocusNode?.hasFocus, isTrue);

    // From Overflow menu -> press Down arrow key -> moves back to Play/Pause
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 100));
    expect(centerPlayPauseFocusable.focusNode?.hasFocus, isTrue);

    // From Play/Pause -> press Down arrow key -> moves to Fullscreen button
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 100));

    final fullscreenFocusNode = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.focusNode?.debugLabel == 'player_fullscreen')
        .focusNode;
    expect(fullscreenFocusNode?.hasFocus, isTrue);

    // From Fullscreen button -> press Up arrow key -> moves back to Play/Pause
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 100));
    expect(centerPlayPauseFocusable.focusNode?.hasFocus, isTrue);
  });

  testWidgets(
      'Overflow menu opens when triggered from DpadFocusable overflow button',
      (tester) async {
    bool serverSelectionClicked = false;
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
      enablePlaybackSpeed: true,
      overflowMenuCustomItems: [
        BetterPlayerOverflowMenuItem(
          Icons.dns_rounded,
          'Server Selection',
          () {
            serverSelectionClicked = true;
          },
        ),
      ],
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

    await tester.pumpWidget(buildPlayerWithSparrowControls(controller: controller));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final focusableFinders = find.byType(DpadFocusable);
    final overflowFocusable = tester
        .widgetList<DpadFocusable>(focusableFinders)
        .firstWhere((df) => df.focusNode?.debugLabel == 'player_overflow');

    // Trigger onSelect on overflow button
    overflowFocusable.onSelect?.call();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Server Selection'), findsOneWidget);
    expect(find.text('Playback speed'), findsOneWidget);

    await tester.tap(find.text('Server Selection'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(serverSelectionClicked, isTrue);
  });
}
