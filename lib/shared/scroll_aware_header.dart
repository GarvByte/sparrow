import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Controller coordinating scroll-aware header visibility across mobile and TV.
///
/// Automatically hides the header on downward scroll (delta > 3.0 or reverse direction)
/// and reveals it on upward scroll (delta < -3.0 or forward direction).
/// Always reveals and keeps the header visible when scrolled at or near the top.
class ScrollAwareHeaderController extends ChangeNotifier {
  bool _isVisible = true;
  bool get isVisible => _isVisible;

  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    // Always reveal the header at or near the top of the scrollable
    if (notification.metrics.pixels <= 15.0) {
      show();
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta > 3.0) {
        hide();
      } else if (delta < -3.0) {
        show();
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        hide();
      } else if (notification.direction == ScrollDirection.forward) {
        show();
      }
    }

    return false;
  }
}

/// Animated wrapper that smoothly slides and fades its child header in and out.
///
/// Can either be driven directly by a [ScrollAwareHeaderController] or by an explicit [isVisible] boolean.
/// Ignores hit tests and pointer events when hidden so off-screen elements do not
/// inadvertently capture user focus or taps.
class ScrollAwareHeader extends StatelessWidget {
  final Widget child;
  final ScrollAwareHeaderController? controller;
  final bool? isVisible;
  final Duration duration;

  const ScrollAwareHeader({
    super.key,
    required this.child,
    this.controller,
    this.isVisible,
    this.duration = const Duration(milliseconds: 250),
  }) : assert(controller != null || isVisible != null,
            'Either controller or isVisible must be provided');

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => _buildAnimatedHeader(controller!.isVisible),
      );
    }
    return _buildAnimatedHeader(isVisible ?? true);
  }

  Widget _buildAnimatedHeader(bool visible) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: duration,
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: duration,
        curve: Curves.easeInOutCubic,
        child: IgnorePointer(
          ignoring: !visible,
          child: child,
        ),
      ),
    );
  }
}
