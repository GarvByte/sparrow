import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_player_plus/better_player_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestPlayer(BetterPlayerController controller) {
    return MaterialApp(
      localizationsDelegates: const [
        mui.GlobalMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 450,
          child: BetterPlayer(controller: controller),
        ),
      ),
    );
  }

  testWidgets('Overflow menu opens safely without crash and displays options',
      (tester) async {
    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        controlsConfiguration: BetterPlayerControlsConfiguration(
          playerTheme: BetterPlayerTheme.material,
          showControlsOnInitialize: true,
          enableOverflowMenu: true,
          enablePlaybackSpeed: true,
          enableAudioTracks: true,
          enableQualities: true,
          enableSubtitles: false,
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        'https://example.com/test.mp4',
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildTestPlayer(controller));

    // Allow controls initialization
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final moreIcon = find.byIcon(Icons.more_vert_outlined);
    expect(moreIcon, findsOneWidget);

    // 1. Open overflow menu
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Playback speed'), findsOneWidget);
    expect(find.text('Quality'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);

    // 2. Open and close repeatedly
    // Dismiss by popping the bottom sheet route
    Navigator.of(tester.element(find.text('Playback speed'))).pop();
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Playback speed'), findsNothing);

    // Re-open
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Playback speed'), findsOneWidget);

    // Dismiss again
    Navigator.of(tester.element(find.text('Playback speed'))).pop();
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Playback speed'), findsNothing);

    // 3. Test submenus (Speed, Quality, Audio)
    // Speed:
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Playback speed'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('1.0 x'), findsOneWidget);
    expect(find.text('1.25 x'), findsOneWidget);
    await tester.tap(find.text('1.25 x'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Quality (Auto fallback when no tracks specified):
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Quality'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Auto'), findsOneWidget);
    await tester.tap(find.text('Auto'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Audio (Default fallback when no alternate tracks available):
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Audio'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.text('Default'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('Overflow menu includes Server Selection and Select Link custom items',
      (tester) async {
    bool serverClicked = false;
    bool linkClicked = false;

    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        controlsConfiguration: BetterPlayerControlsConfiguration(
          playerTheme: BetterPlayerTheme.material,
          showControlsOnInitialize: true,
          enableOverflowMenu: true,
          enablePlaybackSpeed: false,
          enableAudioTracks: false,
          enableQualities: false,
          enableSubtitles: false,
          overflowMenuCustomItems: [
            BetterPlayerOverflowMenuItem(
              Icons.dns_rounded,
              'Server Selection',
              () => serverClicked = true,
            ),
            BetterPlayerOverflowMenuItem(
              Icons.link_rounded,
              'Select Link',
              () => linkClicked = true,
            ),
          ],
        ),
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        'https://example.com/test.mp4',
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildTestPlayer(controller));

    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final moreIcon = find.byIcon(Icons.more_vert_outlined);
    expect(moreIcon, findsOneWidget);

    // 1. Open overflow menu and verify custom items exist
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Server Selection'), findsOneWidget);
    expect(find.text('Select Link'), findsOneWidget);

    // 2. Tap Server Selection
    await tester.tap(find.text('Server Selection'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(serverClicked, isTrue);

    // 3. Re-open overflow menu and tap Select Link
    await tester.tap(moreIcon);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Select Link'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(linkClicked, isTrue);
  });
}
