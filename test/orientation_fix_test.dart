import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/screens/player_page.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/responsive_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final orientationCalls = <List<String>>[];
  final systemUiModeCalls = <String>[];

  setUp(() {
    orientationCalls.clear();
    systemUiModeCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'SystemChrome.setPreferredOrientations') {
        orientationCalls.add(List<String>.from(methodCall.arguments as List));
      } else if (methodCall.method == 'SystemChrome.setEnabledSystemUIMode') {
        systemUiModeCalls.add(methodCall.arguments.toString());
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const testItem = MediaItem(
    id: '550',
    title: 'Fight Club',
    imageUrl: 'https://example.com/poster.jpg',
    genres: ['Drama'],
  );
  final testContext = PlaybackContext.fromMediaItem(testItem);

  group('SparrowResponsive Device Classification Tests', () {
    testWidgets('Mobile phone (390x844 portrait) is classified as phone and not TV', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SparrowResponsive responsive;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              responsive = ctx.responsive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(responsive.isPhone, isTrue);
      expect(responsive.isTvOrDesktop, isFalse);
    });

    testWidgets('Mobile phone in landscape (844x390) is classified as phone and not TV', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SparrowResponsive responsive;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              responsive = ctx.responsive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(responsive.isPhone, isTrue);
      expect(responsive.isTvOrDesktop, isFalse);
    });

    testWidgets('Large phone in landscape (915x412) is NOT misclassified as TV', (tester) async {
      tester.view.physicalSize = const Size(915, 412);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SparrowResponsive responsive;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              responsive = ctx.responsive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(responsive.isPhone, isTrue);
      expect(responsive.isTvOrDesktop, isFalse);
    });

    testWidgets('TV screen (1920x1080) is classified as TV and not phone', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SparrowResponsive responsive;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              responsive = ctx.responsive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(responsive.isTvOrDesktop, isTrue);
      expect(responsive.isPhone, isFalse);
    });
  });

  group('Player Orientation Locking & Restoration Tests', () {
    testWidgets('Entering player on mobile phone locks to landscape', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PlayerPage(playbackContext: testContext),
          ),
        ),
      );
      await tester.pump();

      expect(orientationCalls, isNotEmpty);
      expect(
        orientationCalls.first,
        containsAll([
          'DeviceOrientation.landscapeLeft',
          'DeviceOrientation.landscapeRight',
        ]),
      );
      expect(orientationCalls.first, isNot(contains('DeviceOrientation.portraitUp')));
    });

    testWidgets('Exiting player on mobile phone via top-bar in-app back restores portrait', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(playbackContext: testContext),
                        ),
                      );
                    },
                    child: const Text('Open Player'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open player
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsOneWidget);
      final callsAfterEnter = orientationCalls.length;
      expect(callsAfterEnter, greaterThanOrEqualTo(1));
      expect(
        orientationCalls.last,
        containsAll([
          'DeviceOrientation.landscapeLeft',
          'DeviceOrientation.landscapeRight',
        ]),
      );

      // Tap in-app back button in top bar overlay
      final backButtonFinder = find.byIcon(Icons.arrow_back_rounded);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Verified: PlayerPage is popped
      expect(find.byType(PlayerPage), findsNothing);

      // Verified: Portrait orientation was requested
      expect(orientationCalls.length, greaterThan(callsAfterEnter));
      final lastCall = orientationCalls.last;
      expect(lastCall, contains('DeviceOrientation.portraitUp'));
      expect(lastCall, isNot(contains('DeviceOrientation.landscapeLeft')));
      expect(lastCall, isNot(contains('DeviceOrientation.landscapeRight')));

      // Verified: EdgeToEdge SystemUiMode was restored
      expect(systemUiModeCalls.last, contains('edgeToEdge'));
    });

    testWidgets('Exiting player on mobile phone via PopScope / System Back restores portrait', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(playbackContext: testContext),
                        ),
                      );
                    },
                    child: const Text('Open Player'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open player
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsOneWidget);
      final callsAfterEnter = orientationCalls.length;

      // Simulate system back button / back gesture via Flutter engine platform channel
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Verified: PlayerPage is popped
      expect(find.byType(PlayerPage), findsNothing);

      // Verified: Portrait was restored
      expect(orientationCalls.length, greaterThan(callsAfterEnter));
      final lastCall = orientationCalls.last;
      expect(lastCall, contains('DeviceOrientation.portraitUp'));
      expect(lastCall, isNot(contains('DeviceOrientation.landscapeLeft')));
    });

    testWidgets('Exiting player on TV screen keeps landscape and NEVER restores portrait', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(playbackContext: testContext),
                        ),
                      );
                    },
                    child: const Text('Open Player'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open player on TV
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsOneWidget);

      // Tap in-app back
      final backButtonFinder = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsNothing);

      // Verified: TV never received portrait orientation
      for (final call in orientationCalls) {
        expect(call, isNot(contains('DeviceOrientation.portraitUp')));
      }
      expect(
        orientationCalls.last,
        containsAll([
          'DeviceOrientation.landscapeLeft',
          'DeviceOrientation.landscapeRight',
        ]),
      );
    });

    testWidgets('Reopening player after returning to portrait correctly switches back to landscape', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(playbackContext: testContext),
                        ),
                      );
                    },
                    child: const Text('Open Player'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. First open
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();
      expect(orientationCalls.last, contains('DeviceOrientation.landscapeLeft'));

      // 2. First exit
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(orientationCalls.last, contains('DeviceOrientation.portraitUp'));

      // 3. Second open
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();
      expect(orientationCalls.last, contains('DeviceOrientation.landscapeLeft'));
      expect(orientationCalls.last, isNot(contains('DeviceOrientation.portraitUp')));

      // 4. Second exit
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(orientationCalls.last, contains('DeviceOrientation.portraitUp'));
    });

    testWidgets('Modal sheet back handling closes sheet first before popping player', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerPage(playbackContext: testContext),
                        ),
                      );
                    },
                    child: const Text('Open Player'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsOneWidget);

      // Open a modal sheet on top of PlayerPage
      final playerContext = tester.element(find.byType(PlayerPage));
      showModalBottomSheet(
        context: playerContext,
        builder: (_) => const SizedBox(height: 200, child: Text('Test Modal Sheet')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Modal Sheet'), findsOneWidget);

      // System back press should dismiss modal sheet first
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Modal sheet is dismissed, but PlayerPage remains open
      expect(find.text('Test Modal Sheet'), findsNothing);
      expect(find.byType(PlayerPage), findsOneWidget);
      expect(orientationCalls.last, contains('DeviceOrientation.landscapeLeft'));

      // Next back press exits PlayerPage and restores portrait
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(PlayerPage), findsNothing);
      expect(orientationCalls.last, contains('DeviceOrientation.portraitUp'));
    });
  });
}
