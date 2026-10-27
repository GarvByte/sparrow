import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/enum/aspect_enum.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/media_item.dart';
import '../../../theme/color_palette.dart';
import '../models/playback_context.dart';
import '../models/resolved_source.dart';
import '../providers/stream_resolution_provider.dart';
import '../widgets/link_selection_sheet.dart';
import '../widgets/server_selection_sheet.dart';

/// Fullscreen player page powered by Better Player Plus.
/// Features instant playback of the first valid source, background resolution of alternatives,
/// real D-pad accessible server/link selection sheets, and automatic source fallback.
class PlayerPage extends ConsumerStatefulWidget {
  final MediaItem? item;
  final PlaybackContext? playbackContext;

  const PlayerPage({
    super.key,
    this.item,
    this.playbackContext,
  }) : assert(
          item != null || playbackContext != null,
          'Either item or playbackContext must be provided',
        );

  PlaybackContext get resolvedContext =>
      playbackContext ?? PlaybackContext.fromMediaItem(item!);

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  static const double _fallbackAspectRatio = 16 / 9;

  late BetterPlayerController _controller;
  double? _videoAspectRatio;
  VoidCallback? _videoPlayerListener;
  bool _videoFinished = false;
  bool _isSheetOpen = false;
  bool _hasStartedFirstSource = false;
  bool _controlsVisible = true;
  StreamSubscription<bool>? _controlsVisibilitySubscription;
  StreamResolutionNotifier? _streamResolutionNotifier;
  int _playbackSessionToken = 0;
  ResolvedSource? _activeSource;

  PlaybackContext get _context => widget.resolvedContext;

  @override
  void initState() {
    super.initState();
    _streamResolutionNotifier =
        ref.read(streamResolutionControllerProvider.notifier);
    _lockLandscape();
    _setupPlayerController();

    // Start resolution on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startResolution();
      }
    });
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setupPlayerController() {
    final controlsConfig = BetterPlayerControlsConfiguration(
      playerTheme: BetterPlayerTheme.material,
      
      enableFullscreen: true,
      enableOverflowMenu: true,
      enableAudioTracks: true,
      enableSubtitles: true,
      enablePlaybackSpeed: true,
      enableRetry: true,
      enableQualities: true,
      iconsColor: Colors.white,
      enableProgressBarDrag: true,
      overflowModalColor: ColorPalette.canvas,
      overflowModalTextColor: ColorPalette.fontWhite,
      overflowMenuIconsColor: ColorPalette.fontWhite,
      overflowMenuCustomItems: [
        BetterPlayerOverflowMenuItem(
          Icons.dns_rounded,
          'Server Selection',
          _openServerSheet,
        ),
        BetterPlayerOverflowMenuItem(
          Icons.link_rounded,
          'Select Link',
          _openLinkSheet,
        ),
      ],
      progressBarPlayedColor: ColorPalette.primaryGreen,
      progressBarHandleColor: ColorPalette.primaryGreen,
      progressBarBufferedColor: Colors.white30,
      progressBarBackgroundColor: Colors.white10,
      controlBarColor: const Color.fromARGB(51, 0, 0, 0)
    );

    final configuration = BetterPlayerConfiguration(
      autoPlay: true,
      fit: BoxFit.contain,
      aspectRatioIOS: AspectRatioTypeIOS.aspect,
      useRootNavigator: false,
      controlsConfiguration: controlsConfig,
      fullScreenByDefault: false,
      autoDetectFullscreenAspectRatio: true,
    );

    _controller = BetterPlayerController(configuration);
    _controller.addEventsListener(_handlePlayerEvent);
    _controlsVisibilitySubscription =
        _controller.controlsVisibilityStream.listen((visible) {
      if (mounted && _controlsVisible != visible) {
        setState(() {
          _controlsVisible = visible;
        });
      }
    });
  }

  double? _extractVideoAspectRatio() {
    final vpc = _controller.videoPlayerController;
    if (vpc == null || !vpc.value.initialized) {
      return null;
    }
    final size = vpc.value.size;
    if (size == null || size.width <= 0 || size.height <= 0) {
      return null;
    }
    final ratio = size.width / size.height;
    if (ratio.isNaN || ratio.isInfinite || ratio <= 0) {
      return null;
    }
    return ratio;
  }

  void _updateAspectRatio() {
    final newRatio = _extractVideoAspectRatio();
    if (newRatio != null &&
        (newRatio - (_videoAspectRatio ?? 0)).abs() > 0.001) {
      if (mounted) {
        setState(() {
          _videoAspectRatio = newRatio;
        });
      } else {
        _videoAspectRatio = newRatio;
      }
      _controller.setOverriddenAspectRatio(newRatio);
      _controller.setOverriddenFit(BoxFit.contain);
    }
  }

  void _attachVideoPlayerListener() {
    _removeVideoPlayerListener();
    final vpc = _controller.videoPlayerController;
    if (vpc != null) {
      _videoPlayerListener = () {
        if (mounted) {
          _updateAspectRatio();
        }
      };
      vpc.addListener(_videoPlayerListener!);
    }
  }

  void _removeVideoPlayerListener() {
    final listener = _videoPlayerListener;
    if (listener != null) {
      try {
        _controller.videoPlayerController?.removeListener(listener);
      } catch (_) {}
      _videoPlayerListener = null;
    }
  }

  void _handlePlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
      case BetterPlayerEventType.changedResolution:
        _attachVideoPlayerListener();
        _updateAspectRatio();
        break;

      case BetterPlayerEventType.controlsVisible:
        if (_controlsVisible != true) {
          setState(() {
            _controlsVisible = true;
          });
        }
        break;

      case BetterPlayerEventType.controlsHiddenStart:
      case BetterPlayerEventType.controlsHiddenEnd:
        if (_controlsVisible != false) {
          setState(() {
            _controlsVisible = false;
          });
        }
        break;

      case BetterPlayerEventType.finished:
        setState(() {
          _videoFinished = true;
        });
        break;

      case BetterPlayerEventType.exception:
        debugPrint('PlayerPage: Playback exception occurred: $event');
        _triggerAutomaticFallback(_activeSource);
        break;

      case BetterPlayerEventType.play:
        setState(() {
          _videoFinished = false;
        });
        break;

      default:
        break;
    }
  }

  Duration _captureCurrentPosition() {
    try {
      final pos = _controller.videoPlayerController?.value.position;
      return pos ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  void _startResolution() {
    ref
        .read(streamResolutionControllerProvider.notifier)
        .startPlaybackResolution(
          context: _context,
          onSourceReady: (source, startAt) {
            if (!mounted) return;
            _hasStartedFirstSource = true;
            _playSource(source, startAt: startAt);
          },
        );
  }

  Future<void> _playSource(
    ResolvedSource source, {
    Duration startAt = Duration.zero,
  }) async {
    final currentToken = ++_playbackSessionToken;
    _activeSource = source;

    final isHls = source.type == 'm3u8' ||
        source.url.toLowerCase().contains('.m3u8');
    final isMp4 = source.type == 'mp4' ||
        source.url.toLowerCase().contains('.mp4');

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      source.url,
      headers: source.headers,
      videoFormat: isHls
          ? BetterPlayerVideoFormat.hls
          : (isMp4 ? BetterPlayerVideoFormat.other : null),
      videoExtension: isMp4 ? 'mp4' : (isHls ? 'm3u8' : null),
      useAsmsSubtitles: isHls,
      useAsmsTracks: isHls,
      useAsmsAudioTracks: isHls,
    );

    try {
      await _controller.setupDataSource(dataSource);
      if (currentToken != _playbackSessionToken) return;
      _attachVideoPlayerListener();
      _updateAspectRatio();
      if (startAt > Duration.zero) {
        await _controller.seekTo(startAt);
      }
      if (mounted && currentToken == _playbackSessionToken) {
        await _controller.play();
      }
    } catch (e) {
      debugPrint('PlayerPage: setupDataSource failed: $e');
      if (mounted && currentToken == _playbackSessionToken) {
        _triggerAutomaticFallback(source);
      }
    }
  }

  void _triggerAutomaticFallback([ResolvedSource? failedSource]) {
    final currentPos = _captureCurrentPosition();
    ref.read(streamResolutionControllerProvider.notifier).handleSourceFailure(
      failedSource: failedSource ?? _activeSource,
      currentPosition: currentPos,
      onSourceReady: (source, startAt) {
        if (!mounted) return;
        _playSource(source, startAt: startAt);
      },
    );
  }

  void _openServerSheet() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isSheetOpen = true;
      });

      final currentPos = _captureCurrentPosition();
      ServerSelectionSheet.show(
        context: context,
        currentPosition: currentPos,
        onSelectServer: (serverIndex) {
          ref.read(streamResolutionControllerProvider.notifier).selectServer(
            serverIndex,
            currentPosition: currentPos,
            onSourceReady: (source, startAt) {
              if (!mounted) return;
              _playSource(source, startAt: startAt);
            },
          );
        },
        onOpenLinks: _openLinkSheet,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
      });
    });
  }

  void _openLinkSheet() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(streamResolutionControllerProvider);
      if (state.selectedServer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No server selected yet.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isSheetOpen = true;
      });

      final currentPos = _captureCurrentPosition();
      LinkSelectionSheet.show(
        context: context,
        currentPosition: currentPos,
        onSelectSource: (sourceIndex) {
          ref.read(streamResolutionControllerProvider.notifier).selectSource(
            sourceIndex,
            currentPosition: currentPos,
            onSourceReady: (source, startAt) {
              if (!mounted) return;
              _playSource(source, startAt: startAt);
            },
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() {
            _isSheetOpen = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _removeVideoPlayerListener();
    _restoreOrientation();
    _controlsVisibilitySubscription?.cancel();
    _controller.removeEventsListener(_handlePlayerEvent);
    _controller.dispose();
    _streamResolutionNotifier?.cancelSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streamResolutionControllerProvider);
    final isResolvingInitial =
        state.isResolvingFirstSource && !_hasStartedFirstSource;
    final errorMessage = state.errorMessage;
    final statusMsg = state.statusMessage;

    return PopScope(
      canPop: !_isSheetOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSheetOpen) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: _videoAspectRatio ?? _fallbackAspectRatio,
                child: BetterPlayer(controller: _controller),
              ),
            ),

            // Top Bar Overlay (Title & Back Button) - Fades synchronously with Better Player controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          DpadFocusable(
                            onSelect: () => context.pop(),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _context.displayTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (state.selectedServer != null)
                                  Text(
                                    'Server: ${state.selectedServer!.name}${state.currentSource != null ? " • ${state.currentSource!.displayName}" : ""}',
                                    style: const TextStyle(
                                      color: ColorPalette.textMuted,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Loading / Initial Resolution Overlay
            if (isResolvingInitial)
              Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: ColorPalette.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        statusMsg.isNotEmpty
                            ? statusMsg
                            : 'Resolving streaming sources...',
                        style: const TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Fatal Error / Exhausted Fallback Overlay
            if (errorMessage != null && !_hasStartedFirstSource)
              Container(
                color: Colors.black.withValues(alpha: 0.92),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 50,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Playback Error',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DpadFocusable(
                              onSelect: _startResolution,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorPalette.primaryGreen,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _startResolution,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            DpadFocusable(
                              onSelect: _openServerSheet,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white30),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _openServerSheet,
                                icon: const Icon(Icons.dns_rounded),
                                label: const Text('Change Server'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Video Finished Replay Button
            if (_videoFinished)
              Center(
                child: DpadFocusable(
                  onSelect: () async {
                    setState(() {
                      _videoFinished = false;
                    });
                    await _controller.seekTo(Duration.zero);
                    await _controller.play();
                  },
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      setState(() {
                        _videoFinished = false;
                      });
                      await _controller.seekTo(Duration.zero);
                      await _controller.play();
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Replay'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
