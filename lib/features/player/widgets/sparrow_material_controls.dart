import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/configuration/better_player_controller_event.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/controls/better_player_clickable_widget.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/controls/better_player_material_progress_bar.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/core/better_player_utils.dart';
// ignore: implementation_imports
import 'package:better_player_plus/src/video_player/video_player.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// TV and remote D-pad optimized Material controls for Better Player.
///
/// Highlights focused inbuilt controls (Play/Pause, Forward 10s, Backward 10s,
/// Fullscreen, Overflow menu) with a vibrant, high-contrast [DpadBorderEffect].
/// Automatically guarantees default focus on the Play/Pause button across
/// all playback contexts (initial launch, waking controls, full screen toggling).
class SparrowMaterialControls extends StatefulWidget {
  final BetterPlayerController? controller;
  final void Function(bool visibility) onControlsVisibilityChanged;
  final BetterPlayerControlsConfiguration controlsConfiguration;

  const SparrowMaterialControls({
    super.key,
    this.controller,
    required this.onControlsVisibilityChanged,
    required this.controlsConfiguration,
  });

  @override
  State<StatefulWidget> createState() => _SparrowMaterialControlsState();
}

class _SparrowMaterialControlsState
    extends BetterPlayerControlsState<SparrowMaterialControls> {
  VideoPlayerValue? _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _displayTapped = false;
  bool _wasLoading = false;
  VideoPlayerController? _controller;
  BetterPlayerController? _betterPlayerController;
  StreamSubscription<dynamic>? _controlsVisibilityStreamSubscription;
  StreamSubscription<BetterPlayerControllerEvent>?
      _controllerEventSubscription;

  // Dedicated focus nodes for TV D-pad / keyboard directional navigation
  final FocusNode _playPauseFocusNode =
      FocusNode(debugLabel: 'player_play_pause');
  final FocusNode _skipBackFocusNode =
      FocusNode(debugLabel: 'player_skip_back');
  final FocusNode _skipForwardFocusNode =
      FocusNode(debugLabel: 'player_skip_forward');
  final FocusNode _overflowFocusNode =
      FocusNode(debugLabel: 'player_overflow');
  final FocusNode _fullscreenFocusNode =
      FocusNode(debugLabel: 'player_fullscreen');
  final FocusNode _bottomPlayPauseFocusNode =
      FocusNode(debugLabel: 'player_bottom_play_pause');
  final FocusNode _progressBarFocusNode =
      FocusNode(debugLabel: 'player_progress_bar');

  BetterPlayerControlsConfiguration get _controlsConfiguration =>
      widget.controlsConfiguration;

  @override
  VideoPlayerValue? get latestValue => _latestValue;

  @override
  BetterPlayerController? get betterPlayerController =>
      _betterPlayerController;

  @override
  BetterPlayerControlsConfiguration
      get betterPlayerControlsConfiguration => _controlsConfiguration;

  @override
  void initState() {
    super.initState();
    if (_controlsConfiguration.showControlsOnInitialize) {
      controlsNotVisible = false;
    }
  }

  void _requestPlayPauseFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controlsNotVisible) {
        _playPauseFocusNode.requestFocus();
      }
    });
  }

  @override
  void changePlayerControlsNotVisible(bool notVisible) {
    final bool wasNotVisible = controlsNotVisible;
    super.changePlayerControlsNotVisible(notVisible);
    if (wasNotVisible && !notVisible) {
      _requestPlayPauseFocus();
    }
  }

  @override
  Widget build(BuildContext context) =>
      buildLTRDirectionality(_buildMainWidget());

  Widget _buildMainWidget() {
    _wasLoading = isLoading(_latestValue);
    if (_latestValue?.hasError ?? false) {
      return ColoredBox(color: Colors.black, child: _buildErrorWidget());
    }

    return GestureDetector(
      onTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onTap?.call();
        }
        if (controlsNotVisible) {
          cancelAndRestartTimer();
          _requestPlayPauseFocus();
        } else {
          changePlayerControlsNotVisible(true);
        }
      },
      onDoubleTap: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onDoubleTap?.call();
        }
        cancelAndRestartTimer();
        _requestPlayPauseFocus();
      },
      onLongPress: () {
        if (BetterPlayerMultipleGestureDetector.of(context) != null) {
          BetterPlayerMultipleGestureDetector.of(context)!.onLongPress?.call();
        }
      },
      child: Focus(
        canRequestFocus: controlsNotVisible,
        onKeyEvent: (node, event) {
          if (controlsNotVisible && event is KeyDownEvent) {
            cancelAndRestartTimer();
            _requestPlayPauseFocus();
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _onPlayPause();
              return KeyEventResult.handled;
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AbsorbPointer(
          absorbing: controlsNotVisible,
          child: fullScreenSafeArea(
            Stack(
              fit: StackFit.expand,
              children: [
                _buildHitArea(),
                if (_wasLoading)
                  Center(child: _buildLoadingWidget()),
                Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
                Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
                _buildNextVideoWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _playPauseFocusNode.dispose();
    _skipBackFocusNode.dispose();
    _skipForwardFocusNode.dispose();
    _overflowFocusNode.dispose();
    _fullscreenFocusNode.dispose();
    _bottomPlayPauseFocusNode.dispose();
    _progressBarFocusNode.dispose();
    _controllerEventSubscription?.cancel();
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
    _controlsVisibilityStreamSubscription?.cancel();
    _controllerEventSubscription?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _betterPlayerController;
    _betterPlayerController = widget.controller ?? BetterPlayerController.of(context);
    _controller = _betterPlayerController!.videoPlayerController;
    _latestValue = _controller!.value;

    if (oldController != _betterPlayerController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildErrorWidget() {
    final errorBuilder =
        _betterPlayerController!.betterPlayerConfiguration.errorBuilder;
    if (errorBuilder != null) {
      return errorBuilder(
        context,
        _betterPlayerController!.videoPlayerController!.value.errorDescription,
      );
    } else {
      final textStyle = TextStyle(color: _controlsConfiguration.textColor);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: _controlsConfiguration.iconsColor, size: 42),
            Text(
              _betterPlayerController!.translations.generalDefaultError,
              style: textStyle,
            ),
            if (_controlsConfiguration.enableRetry)
              TextButton(
                onPressed: () {
                  _betterPlayerController!.retryDataSource();
                },
                child: Text(
                  _betterPlayerController!.translations.generalRetry,
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }

    return (_controlsConfiguration.enableOverflowMenu)
        ? AnimatedOpacity(
            opacity: controlsNotVisible ? 0.0 : 1.0,
            duration: _controlsConfiguration.controlsHideTime,
            onEnd: _onPlayerHide,
            child: SizedBox(
              height: _controlsConfiguration.controlBarHeight,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_controlsConfiguration.enablePip)
                    _buildPipButtonWrapperWidget(
                      controlsNotVisible,
                      _onPlayerHide,
                    )
                  else
                    const SizedBox(),
                  _buildMoreButton(),
                ],
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildPipButton() => BetterPlayerMaterialClickableWidget(
        onTap: () {
          betterPlayerController!.enablePictureInPicture(
            betterPlayerController!.betterPlayerGlobalKey!,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            betterPlayerControlsConfiguration.pipMenuIcon,
            color: betterPlayerControlsConfiguration.iconsColor,
          ),
        ),
      );

  Widget _buildPipButtonWrapperWidget(
    bool hideStuff,
    void Function() onPlayerHide,
  ) =>
      FutureBuilder<bool>(
        future: betterPlayerController!.isPictureInPictureSupported(),
        builder: (context, snapshot) {
          final bool isPipSupported = snapshot.data ?? false;
          if (isPipSupported &&
              _betterPlayerController!.betterPlayerGlobalKey != null) {
            return AnimatedOpacity(
              opacity: hideStuff ? 0.0 : 1.0,
              duration: betterPlayerControlsConfiguration.controlsHideTime,
              onEnd: onPlayerHide,
              child: SizedBox(
                height: betterPlayerControlsConfiguration.controlBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildPipButton()],
                ),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      );

  Widget _buildMoreButton() => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: DpadFocusable(
          focusNode: _overflowFocusNode,
          enabled: !controlsNotVisible,
          onSelect: () {
            cancelAndRestartTimer();
            onShowMoreClicked();
          },
          onFocusChange: (focused) {
            if (focused) cancelAndRestartTimer();
          },
          onDirection: (direction) {
            if (direction == TraversalDirection.down) {
              _playPauseFocusNode.requestFocus();
              return true;
            }
            if (direction == TraversalDirection.left) {
              _skipBackFocusNode.requestFocus();
              return true;
            }
            return false;
          },
          effects: [
            const DpadScaleEffect(scale: 1.08),
            const DpadBorderEffect(
              width: 3.0,
              color: ColorPalette.primaryGreen,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const DpadGlowEffect(
              color: ColorPalette.primaryGreen,
              blurRadius: 12,
              spreadRadius: 1.0,
              opacity: 0.4,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Icon(
              _controlsConfiguration.overflowMenuIcon,
              color: _controlsConfiguration.iconsColor,
              size: 24,
            ),
          ),
        ),
      );

  Widget _buildBottomBar() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return AnimatedOpacity(
      opacity: controlsNotVisible ? 0.0 : 1.0,
      duration: _controlsConfiguration.controlsHideTime,
      onEnd: _onPlayerHide,
      child: SizedBox(
        height: _controlsConfiguration.controlBarHeight + 20.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 75,
              child: Row(
                children: [
                  if (_controlsConfiguration.enablePlayPause)
                    _buildPlayPause(_controller!)
                  else
                    const SizedBox(),
                  if (_betterPlayerController!.isLiveStream())
                    _buildLiveWidget()
                  else if (_controlsConfiguration.enableProgressText)
                    Expanded(child: _buildPosition())
                  else
                    const SizedBox(),
                  const Spacer(),
                  if (_controlsConfiguration.enableMute)
                    _buildMuteButton(_controller)
                  else
                    const SizedBox(),
                  if (_controlsConfiguration.enableFullscreen)
                    _buildExpandButton()
                  else
                    const SizedBox(),
                ],
              ),
            ),
            if (_betterPlayerController!.isLiveStream())
              const SizedBox()
            else if (_controlsConfiguration.enableProgressBar)
              _buildProgressBar()
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWidget() => Text(
        _betterPlayerController!.translations.controlsLive,
        style: TextStyle(
          color: _controlsConfiguration.liveTextColor,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildExpandButton() => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: DpadFocusable(
          focusNode: _fullscreenFocusNode,
          enabled: !controlsNotVisible,
          onSelect: () {
            cancelAndRestartTimer();
            _onExpandCollapse();
          },
          onFocusChange: (focused) {
            if (focused) cancelAndRestartTimer();
          },
          onDirection: (direction) {
            if (direction == TraversalDirection.up) {
              _playPauseFocusNode.requestFocus();
              return true;
            }
            if (direction == TraversalDirection.left) {
              if (_controlsConfiguration.enablePlayPause) {
                _bottomPlayPauseFocusNode.requestFocus();
              } else {
                _skipBackFocusNode.requestFocus();
              }
              return true;
            }
            if (direction == TraversalDirection.down) {
              _progressBarFocusNode.requestFocus();
              return true;
            }
            return false;
          },
          effects: [
            const DpadScaleEffect(scale: 1.08),
            const DpadBorderEffect(
              width: 3.0,
              color: ColorPalette.primaryGreen,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const DpadGlowEffect(
              color: ColorPalette.primaryGreen,
              blurRadius: 12,
              spreadRadius: 1.0,
              opacity: 0.4,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Center(
              child: Icon(
                _betterPlayerController!.isFullScreen
                    ? _controlsConfiguration.fullscreenDisableIcon
                    : _controlsConfiguration.fullscreenEnableIcon,
                color: _controlsConfiguration.iconsColor,
                size: 24,
              ),
            ),
          ),
        ),
      );

  Widget _buildHitArea() {
    if (!betterPlayerController!.controlsEnabled) {
      return const SizedBox();
    }
    return Center(
      child: AnimatedOpacity(
        opacity: controlsNotVisible ? 0.0 : 1.0,
        duration: _controlsConfiguration.controlsHideTime,
        child: _buildMiddleRow(),
      ),
    );
  }

  Widget _buildMiddleRow() => Container(
        color: _controlsConfiguration.controlBarColor,
        width: double.infinity,
        height: double.infinity,
        child: _betterPlayerController?.isLiveStream() ?? false
            ? const SizedBox()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_controlsConfiguration.enableSkips)
                    Expanded(child: _buildSkipButton())
                  else
                    const SizedBox(),
                  Expanded(child: _buildReplayButton(_controller!)),
                  if (_controlsConfiguration.enableSkips)
                    Expanded(child: _buildForwardButton())
                  else
                    const SizedBox(),
                ],
              ),
      );

  Widget _buildHitAreaButton({
    required Widget icon,
    required VoidCallback onClicked,
    required FocusNode focusNode,
    bool autofocus = false,
    DpadDirectionCallback? onDirection,
    bool isSkipButton = false,
  }) {
    final bool isTv = context.responsive.isTvOrDesktop;

    // On mobile, skip buttons are standard touchable clickable buttons
    // without TV D-pad focus highlights (green border / glow).
    if (!isTv && isSkipButton) {
      return Center(
        child: BetterPlayerMaterialClickableWidget(
          onTap: () {
            cancelAndRestartTimer();
            onClicked();
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            child: Center(child: icon),
          ),
        ),
      );
    }

    final List<DpadEffect> effects = [
      const DpadScaleEffect(scale: 1.08),
      const DpadBorderEffect(
        width: 3.0,
        color: ColorPalette.primaryGreen,
        borderRadius: BorderRadius.all(Radius.circular(48)),
      ),
      const DpadGlowEffect(
        color: ColorPalette.primaryGreen,
        blurRadius: 14,
        spreadRadius: 1.5,
        opacity: 0.45,
        borderRadius: BorderRadius.all(Radius.circular(48)),
      ),
    ];

    return Center(
      child: DpadFocusable(
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: !controlsNotVisible,
        onSelect: () {
          cancelAndRestartTimer();
          onClicked();
        },
        onFocusChange: (focused) {
          if (focused) {
            cancelAndRestartTimer();
          }
        },
        onDirection: onDirection,
        effects: effects,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  @override
  void skipBack() {
    if (_controller == null || !_controller!.value.initialized) return;
    cancelAndRestartTimer();
    final position = _controller!.value.position;
    final skipTime = Duration(
      milliseconds:
          _controlsConfiguration.backwardSkipTimeInMilliseconds,
    );
    final target = position - skipTime;
    _betterPlayerController?.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  @override
  void skipForward() {
    if (_controller == null || !_controller!.value.initialized) return;
    final duration = _controller!.value.duration;
    if (duration == null || duration <= Duration.zero) return;
    cancelAndRestartTimer();
    final position = _controller!.value.position;
    final skipTime = Duration(
      milliseconds:
          _controlsConfiguration.forwardSkipTimeInMilliseconds,
    );
    final target = position + skipTime;
    _betterPlayerController?.seekTo(target > duration ? duration : target);
  }

  Widget _buildSkipButton() => _buildHitAreaButton(
        icon: Icon(
          _controlsConfiguration.skipBackIcon,
          size: 28,
          color: _controlsConfiguration.iconsColor,
        ),
        onClicked: skipBack,
        focusNode: _skipBackFocusNode,
        isSkipButton: true,
        onDirection: (direction) {
          if (direction == TraversalDirection.right) {
            _playPauseFocusNode.requestFocus();
            return true;
          }
          if (direction == TraversalDirection.up) {
            _overflowFocusNode.requestFocus();
            return true;
          }
          if (direction == TraversalDirection.down) {
            if (_controlsConfiguration.enablePlayPause) {
              _bottomPlayPauseFocusNode.requestFocus();
            } else {
              _fullscreenFocusNode.requestFocus();
            }
            return true;
          }
          return false;
        },
      );

  Widget _buildForwardButton() => _buildHitAreaButton(
        icon: Icon(
          _controlsConfiguration.skipForwardIcon,
          size: 28,
          color: _controlsConfiguration.iconsColor,
        ),
        onClicked: skipForward,
        focusNode: _skipForwardFocusNode,
        isSkipButton: true,
        onDirection: (direction) {
          if (direction == TraversalDirection.left) {
            _playPauseFocusNode.requestFocus();
            return true;
          }
          if (direction == TraversalDirection.up) {
            _overflowFocusNode.requestFocus();
            return true;
          }
          if (direction == TraversalDirection.down) {
            _fullscreenFocusNode.requestFocus();
            return true;
          }
          return false;
        },
      );

  Widget _buildReplayButton(VideoPlayerController controller) {
    final bool isFinished = isVideoFinished(_latestValue);
    return _buildHitAreaButton(
      icon: isFinished
          ? Icon(
              Icons.replay_rounded,
              size: 38,
              color: _controlsConfiguration.iconsColor,
            )
          : Icon(
              controller.value.isPlaying
                  ? _controlsConfiguration.pauseIcon
                  : _controlsConfiguration.playIcon,
              size: 38,
              color: _controlsConfiguration.iconsColor,
            ),
      onClicked: () {
        if (isFinished) {
          if (_latestValue != null && _latestValue!.isPlaying) {
            if (_displayTapped) {
              changePlayerControlsNotVisible(true);
            } else {
              cancelAndRestartTimer();
            }
          } else {
            _onPlayPause();
            changePlayerControlsNotVisible(true);
          }
        } else {
          _onPlayPause();
        }
      },
      focusNode: _playPauseFocusNode,
      autofocus: true,
      onDirection: (direction) {
        if (direction == TraversalDirection.left) {
          _skipBackFocusNode.requestFocus();
          return true;
        }
        if (direction == TraversalDirection.right) {
          _skipForwardFocusNode.requestFocus();
          return true;
        }
        if (direction == TraversalDirection.up) {
          _overflowFocusNode.requestFocus();
          return true;
        }
        if (direction == TraversalDirection.down) {
          _fullscreenFocusNode.requestFocus();
          return true;
        }
        return false;
      },
    );
  }

  Widget _buildNextVideoWidget() => StreamBuilder<int?>(
        stream: _betterPlayerController!.nextVideoTimeStream,
        builder: (context, snapshot) {
          final time = snapshot.data;
          if (time != null && time > 0) {
            return BetterPlayerMaterialClickableWidget(
              onTap: () {
                _betterPlayerController!.playNextVideo();
              },
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: _controlsConfiguration.controlBarHeight + 20,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: _controlsConfiguration.controlBarColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${_betterPlayerController!.translations.controlsNextVideoIn} $time...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      );

  Widget _buildMuteButton(VideoPlayerController? controller) =>
      BetterPlayerMaterialClickableWidget(
        onTap: () {
          cancelAndRestartTimer();
          if (_latestValue!.volume == 0) {
            _betterPlayerController!.setVolume(_latestVolume ?? 0.5);
          } else {
            _latestVolume = controller!.value.volume;
            _betterPlayerController!.setVolume(0);
          }
        },
        child: AnimatedOpacity(
          opacity: controlsNotVisible ? 0.0 : 1.0,
          duration: _controlsConfiguration.controlsHideTime,
          child: ClipRect(
            child: Container(
              height: _controlsConfiguration.controlBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                (_latestValue != null && _latestValue!.volume > 0)
                    ? _controlsConfiguration.muteIcon
                    : _controlsConfiguration.unMuteIcon,
                color: _controlsConfiguration.iconsColor,
              ),
            ),
          ),
        ),
      );

  Widget _buildPlayPause(VideoPlayerController controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: DpadFocusable(
          key: const Key('better_player_material_controls_play_pause_button'),
          focusNode: _bottomPlayPauseFocusNode,
          enabled: !controlsNotVisible,
          onSelect: () {
            cancelAndRestartTimer();
            _onPlayPause();
          },
          onFocusChange: (focused) {
            if (focused) cancelAndRestartTimer();
          },
          onDirection: (direction) {
            if (direction == TraversalDirection.up) {
              _playPauseFocusNode.requestFocus();
              return true;
            }
            if (direction == TraversalDirection.right) {
              _fullscreenFocusNode.requestFocus();
              return true;
            }
            if (direction == TraversalDirection.down) {
              _progressBarFocusNode.requestFocus();
              return true;
            }
            return false;
          },
          effects: [
            const DpadScaleEffect(scale: 1.08),
            const DpadBorderEffect(
              width: 3.0,
              color: ColorPalette.primaryGreen,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const DpadGlowEffect(
              color: ColorPalette.primaryGreen,
              blurRadius: 12,
              spreadRadius: 1.0,
              opacity: 0.4,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Center(
              child: Icon(
                controller.value.isPlaying
                    ? _controlsConfiguration.pauseIcon
                    : _controlsConfiguration.playIcon,
                color: _controlsConfiguration.iconsColor,
                size: 24,
              ),
            ),
          ),
        ),
      );

  Widget _buildPosition() {
    final position =
        _latestValue != null ? _latestValue!.position : Duration.zero;
    final duration = _latestValue != null && _latestValue!.duration != null
        ? _latestValue!.duration!
        : Duration.zero;

    return Padding(
      padding: _controlsConfiguration.enablePlayPause
          ? const EdgeInsets.only(right: 24)
          : const EdgeInsets.symmetric(horizontal: 22),
      child: RichText(
        text: TextSpan(
          text: BetterPlayerUtils.formatDuration(position),
          style: TextStyle(
            fontSize: 10,
            color: _controlsConfiguration.textColor,
            decoration: TextDecoration.none,
          ),
          children: <TextSpan>[
            TextSpan(
              text: ' / ${BetterPlayerUtils.formatDuration(duration)}',
              style: TextStyle(
                fontSize: 10,
                color: _controlsConfiguration.textColor,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    if (controlsNotVisible) {
      changePlayerControlsNotVisible(false);
    }
    _displayTapped = true;
  }

  Future<void> _initialize() async {
    _controller!.addListener(_updateState);
    _updateState();

    if ((_controller!.value.isPlaying) ||
        _betterPlayerController!.betterPlayerConfiguration.autoPlay) {
      _startHideTimer();
    }

    if (_controlsConfiguration.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        changePlayerControlsNotVisible(false);
      });
    }

    _controlsVisibilityStreamSubscription =
        _betterPlayerController!.controlsVisibilityStream.listen((state) {
      if (controlsNotVisible == !state) {
        return;
      }
      changePlayerControlsNotVisible(!state);
      if (!controlsNotVisible) {
        cancelAndRestartTimer();
        _requestPlayPauseFocus();
      }
    });

    _controllerEventSubscription?.cancel();
    _controllerEventSubscription =
        _betterPlayerController!.controllerEventStream.listen((event) {
      if (event == BetterPlayerControllerEvent.openFullscreen ||
          event == BetterPlayerControllerEvent.hideFullscreen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            cancelAndRestartTimer();
            _playPauseFocusNode.requestFocus();
          }
        });
      }
    });

    _requestPlayPauseFocus();
  }

  void _onExpandCollapse() {
    changePlayerControlsNotVisible(true);
    _betterPlayerController!.toggleFullScreen();
    _showAfterExpandCollapseTimer =
        Timer(_controlsConfiguration.controlsHideTime, () {
      if (mounted) {
        setState(cancelAndRestartTimer);
        _playPauseFocusNode.requestFocus();
      }
    });
  }

  void _onPlayPause() {
    bool isFinished = false;

    if (_latestValue?.position != null && _latestValue?.duration != null) {
      isFinished = _latestValue!.position >= _latestValue!.duration!;
    }

    if (_controller!.value.isPlaying) {
      changePlayerControlsNotVisible(false);
      _hideTimer?.cancel();
      _betterPlayerController!.pause();
    } else {
      cancelAndRestartTimer();

      if (!_controller!.value.initialized) {
      } else {
        if (isFinished) {
          _betterPlayerController!.seekTo(Duration.zero);
        }
        _betterPlayerController!.play();
        _betterPlayerController!.cancelNextVideoTimer();
      }
    }
  }

  void _startHideTimer() {
    if (_betterPlayerController?.controlsAlwaysVisible ?? false) {
      return;
    }
    _hideTimer = Timer(const Duration(milliseconds: 3000), () {
      changePlayerControlsNotVisible(true);
    });
  }

  void _updateState() {
    if (mounted) {
      if (!controlsNotVisible ||
          isVideoFinished(_controller!.value) ||
          _wasLoading ||
          isLoading(_controller!.value)) {
        setState(() {
          _latestValue = _controller!.value;
          if (isVideoFinished(_latestValue) &&
              _betterPlayerController?.isLiveStream() == false) {
            changePlayerControlsNotVisible(false);
          }
        });
      }
    }
  }

  Duration? _pendingSeekPosition;
  DateTime? _lastSeekTime;

  void _seekRelative(Duration offset) {
    if (_controller == null || !_controller!.value.initialized) return;
    final duration = _controller!.value.duration;
    if (duration == null || duration <= Duration.zero) {
      // If duration is unknown, avoid invalid seeking
      return;
    }

    final now = DateTime.now();
    Duration basePosition;
    if (_pendingSeekPosition != null &&
        _lastSeekTime != null &&
        now.difference(_lastSeekTime!).inMilliseconds < 1500) {
      basePosition = _pendingSeekPosition!;
    } else {
      basePosition = _controller!.value.position;
    }

    var newPosition = basePosition + offset;
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (newPosition > duration) {
      newPosition = duration;
    }

    _pendingSeekPosition = newPosition;
    _lastSeekTime = now;
    _betterPlayerController?.seekTo(newPosition);
  }

  Widget _buildProgressBar() {
    final progressBarWidget = BetterPlayerMaterialVideoProgressBar(
      _controller,
      _betterPlayerController,
      onDragStart: () {
        _hideTimer?.cancel();
      },
      onDragEnd: _startHideTimer,
      onTapDown: cancelAndRestartTimer,
      colors: BetterPlayerProgressColors(
        playedColor: _controlsConfiguration.progressBarPlayedColor,
        handleColor: _controlsConfiguration.progressBarHandleColor,
        bufferedColor: _controlsConfiguration.progressBarBufferedColor,
        backgroundColor:
            _controlsConfiguration.progressBarBackgroundColor,
      ),
    );

    if (!context.responsive.isTvOrDesktop) {
      return Expanded(
        flex: 40,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: progressBarWidget,
        ),
      );
    }

    return Expanded(
      flex: 40,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DpadFocusable(
          focusNode: _progressBarFocusNode,
          enabled: !controlsNotVisible,
          onFocusChange: (focused) {
            if (focused) cancelAndRestartTimer();
          },
          onDirection: (direction) {
            if (direction == TraversalDirection.left) {
              cancelAndRestartTimer();
              _seekRelative(const Duration(minutes: -15));
              return true;
            }
            if (direction == TraversalDirection.right) {
              cancelAndRestartTimer();
              _seekRelative(const Duration(minutes: 15));
              return true;
            }
            if (direction == TraversalDirection.up) {
              _fullscreenFocusNode.requestFocus();
              return true;
            }
            if (direction == TraversalDirection.down) {
              return true;
            }
            return false;
          },
          effects: [
            const DpadBorderEffect(
              width: 2.5,
              color: ColorPalette.primaryGreen,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const DpadGlowEffect(
              color: ColorPalette.primaryGreen,
              blurRadius: 10,
              spreadRadius: 1.0,
              opacity: 0.4,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: progressBarWidget,
          ),
        ),
      ),
    );
  }

  void _onPlayerHide() {
    _betterPlayerController!.toggleControlsVisibility(!controlsNotVisible);
    _betterPlayerController!.setControlsVisibility(!controlsNotVisible);
    widget.onControlsVisibilityChanged(!controlsNotVisible);
  }

  Widget? _buildLoadingWidget() {
    if (_controlsConfiguration.loadingWidget != null) {
      return ColoredBox(
        color: _controlsConfiguration.controlBarColor,
        child: _controlsConfiguration.loadingWidget,
      );
    }

    return CircularProgressIndicator(
      valueColor:
          AlwaysStoppedAnimation<Color>(_controlsConfiguration.loadingColor),
    );
  }
}
