import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/models/resolved_source.dart';
import 'package:sparrow/features/player/models/server_item.dart';
import 'package:sparrow/features/player/providers/stream_resolution_provider.dart';
import 'package:sparrow/features/player/widgets/link_selection_sheet.dart';
import 'package:sparrow/features/player/widgets/server_selection_sheet.dart';
import 'package:sparrow/shared/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testItem = MediaItem(
    id: '84092',
    title: 'Test Movie',
    imageUrl: '',
    genres: ['Action'],
  );

  final testServers = [
    ServerItem(
      id: 1,
      name: 'Nitro Multi-Lang',
      scraper: 'nitro',
      webSupport: true,
      resolutionStatus: ServerResolutionStatus.ready,
      sources: const [
        ResolvedSource(
          id: 'nitro-0',
          provider: 'nitro',
          url: 'https://example.com/nitro1.m3u8',
          quality: '1080p',
          label: 'Nitro Link 1',
        ),
        ResolvedSource(
          id: 'nitro-1',
          provider: 'nitro',
          url: 'https://example.com/nitro2.m3u8',
          quality: '720p',
          label: 'Nitro Link 2',
        ),
      ],
    ),
    const ServerItem(
      id: 2,
      name: 'MegaCloud',
      scraper: 'megacloud',
      webSupport: true,
      resolutionStatus: ServerResolutionStatus.loading,
    ),
    const ServerItem(
      id: 3,
      name: 'StreamWish',
      scraper: 'streamwish',
      webSupport: true,
      resolutionStatus: ServerResolutionStatus.failed,
      errorMessage: 'Network timed out',
    ),
    const ServerItem(
      id: 4,
      name: 'VidCloud',
      scraper: 'vidcloud',
      webSupport: true,
      resolutionStatus: ServerResolutionStatus.idle,
    ),
  ];

  Widget buildTestWidget({
    required Widget child,
    List<ServerItem>? servers,
    int? selectedServerIndex,
    int? selectedSourceIndex,
  }) {
    return ProviderScope(
      overrides: [
        streamResolutionControllerProvider.overrideWith(() {
          final notifier = StreamResolutionNotifier();
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Pre-populate state for testing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final notifier =
                    ref.read(streamResolutionControllerProvider.notifier);
                notifier.state = StreamResolutionState(
                  context: PlaybackContext.movie(item: testItem),
                  servers: servers ?? testServers,
                  selectedServerIndex: selectedServerIndex ?? 0,
                  selectedSourceIndex: selectedSourceIndex ?? 0,
                  currentSource: testServers[0].sources.first,
                );
              });
              return child;
            },
          ),
        ),
      ),
    );
  }

  group('ServerSelectionSheet Tests', () {
    testWidgets('Renders all servers with accurate status badges',
        (tester) async {
      int? selectedIdx;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ServerSelectionSheet.show(
                    context: context,
                    currentPosition: Duration.zero,
                    onSelectServer: (idx) => selectedIdx = idx,
                    onOpenLinks: () {},
                  );
                },
                child: const Text('Open Servers'),
              );
            },
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Servers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Streaming Servers'), findsOneWidget);
      expect(find.text('Nitro Multi-Lang'), findsOneWidget);
      expect(find.text('MegaCloud'), findsOneWidget);
      expect(find.text('StreamWish'), findsOneWidget);
      expect(find.text('VidCloud'), findsOneWidget);

      // Status badges
      expect(find.text('Ready (2)'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Not Resolved'), findsOneWidget);

      // Tap on second server
      await tester.tap(find.text('MegaCloud'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(selectedIdx, equals(1));
    });

    testWidgets('Links button is visible when selected server has multiple links',
        (tester) async {
      bool openedLinks = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ServerSelectionSheet.show(
                    context: context,
                    currentPosition: Duration.zero,
                    onSelectServer: (_) {},
                    onOpenLinks: () {
                      openedLinks = true;
                    },
                  );
                },
                child: const Text('Open Servers'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Servers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final linksBtn = find.text('Links (2)');
      expect(linksBtn, findsOneWidget);

      await tester.tap(linksBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(openedLinks, isTrue);
    });
  });

  group('LinkSelectionSheet Tests', () {
    testWidgets('Renders links and handles user selection', (tester) async {
      int? chosenLinkIndex;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  LinkSelectionSheet.show(
                    context: context,
                    currentPosition: Duration.zero,
                    onSelectSource: (idx) => chosenLinkIndex = idx,
                  );
                },
                child: const Text('Open Links'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Links'));
      await tester.pumpAndSettle();

      expect(find.text('Available Links'), findsOneWidget);
      expect(find.text('Link 1: Nitro Link 1'), findsOneWidget);
      expect(find.text('Link 2: Nitro Link 2'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Select Link 2
      await tester.tap(find.text('Link 2: Nitro Link 2'));
      await tester.pumpAndSettle();

      expect(chosenLinkIndex, equals(1));
    });
  });

  group('Player Controls & Title Overlay Synchronization Tests', () {
    testWidgets(
        'Top bar overlay animates opacity and ignores pointer based on controls visibility',
        (tester) async {
      bool controlsVisible = true;
      const opacityKey = Key('top_bar_opacity');
      const ignoreKey = Key('top_bar_ignore');

      late StateSetter stateSetter;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                stateSetter = setState;
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        key: opacityKey,
                        opacity: controlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          key: ignoreKey,
                          ignoring: !controlsVisible,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  onPressed: () {},
                                ),
                                const Expanded(
                                  child: Text('Iron Man 3'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // 1. Controls visible initially
      expect(find.text('Iron Man 3'), findsOneWidget);
      final animatedOpacityFinder = find.byKey(opacityKey);
      AnimatedOpacity animatedOpacity = tester.widget(animatedOpacityFinder);
      expect(animatedOpacity.opacity, equals(1.0));

      final ignorePointerFinder = find.byKey(ignoreKey);
      IgnorePointer ignorePointer = tester.widget(ignorePointerFinder);
      expect(ignorePointer.ignoring, isFalse);

      // Verify separate overlay buttons are removed from top bar
      expect(find.text('Servers'), findsNothing);
      expect(find.text('Links'), findsNothing);

      // 2. Hide controls
      stateSetter(() {
        controlsVisible = false;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      animatedOpacity = tester.widget(animatedOpacityFinder);
      expect(animatedOpacity.opacity, equals(0.0));

      ignorePointer = tester.widget(ignorePointerFinder);
      expect(ignorePointer.ignoring, isTrue);

      // 3. Show controls again
      stateSetter(() {
        controlsVisible = true;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      animatedOpacity = tester.widget(animatedOpacityFinder);
      expect(animatedOpacity.opacity, equals(1.0));

      ignorePointer = tester.widget(ignorePointerFinder);
      expect(ignorePointer.ignoring, isFalse);
    });
  });
}
