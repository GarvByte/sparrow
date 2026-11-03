import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/home%20page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/navigation/tv_navigation_drawer.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Inherited scope allowing child widgets and carousel regions to trigger opening or closing
/// the TV navigation drawer.
class TvDrawerScope extends InheritedWidget {
  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;
  final bool isOpen;

  const TvDrawerScope({
    super.key,
    required this.openDrawer,
    required this.closeDrawer,
    required this.isOpen,
    required super.child,
  });

  static TvDrawerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TvDrawerScope>();
  }

  static void openOf(BuildContext context) {
    maybeOf(context)?.openDrawer();
  }

  @override
  bool updateShouldNotify(TvDrawerScope oldWidget) => isOpen != oldWidget.isOpen;
}

/// Top-level shell scaffold that hosts the [StatefulNavigationShell] and
/// switches responsively between the TV Navigation Drawer and the Mobile/Tablet
/// Floating Bottom Navigation dock.
///
/// TV Responsibilities:
/// - Replaces FloatingBottomNav with [TvNavigationDrawer].
/// - Detects Left D-pad/keyboard navigation at the far-left boundary of main content
///   and seamlessly triggers the TV Drawer.
/// - Manages TV drawer focus state, Up/Down selection, and Back/Right dismissal.
/// - Restores content focus when drawer is dismissed without branch navigation.
/// - Preserves indexed-stack caching, scroll positions, and Riverpod state across all branches.
class MainShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScaffold({super.key, required this.navigationShell});

  @override
  State<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<MainShellScaffold> {
  bool _isDrawerOpen = false;
  FocusNode? _lastContentFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.responsive.isTvOrDesktop) {
        if (FocusManager.instance.primaryFocus == null ||
            FocusManager.instance.primaryFocus == FocusScope.of(context)) {
          FocusScope.of(context).nextFocus();
        }
      }
    });
  }

  void _openDrawer({FocusNode? fromNode}) {
    if (_isDrawerOpen) return;
    _lastContentFocus = fromNode;
    setState(() {
      _isDrawerOpen = true;
    });
  }

  void _closeDrawer() {
    if (!_isDrawerOpen) return;
    setState(() {
      _isDrawerOpen = false;
    });

    // Restore focus to the content item that was focused before the drawer opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _lastContentFocus;
      if (target != null && target.context != null && target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }

  bool _isAtLeftBoundary(FocusNode node) {
    final context = node.context;
    if (context == null || !context.mounted) return true;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return true;

    final offset = renderObject.localToGlobal(Offset.zero);
    final rect = offset & renderObject.size;

    // If inside a horizontal scrollable, ensure we are at the beginning of the list
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null &&
        (scrollable.axisDirection == AxisDirection.right ||
            scrollable.axisDirection == AxisDirection.left)) {
      if (scrollable.position.pixels > 8.0) {
        return false;
      }
    }

    // Must be in the left section of the viewport (<= 35% of width, min 140, max 360)
    final mediaQuery = MediaQuery.of(context);
    final maxLeftThreshold = (mediaQuery.size.width * 0.35).clamp(140.0, 360.0);

    return rect.left <= maxLeftThreshold;
  }

  KeyEventResult _handleShellKeyEvent(FocusNode node, KeyEvent event) {
    final responsive = context.responsive;
    if (!responsive.isTvOrDesktop) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // 1. When the TV Drawer is open, handle Back/Escape or Right arrow to dismiss
    if (_isDrawerOpen) {
      if (key == LogicalKeyboardKey.arrowRight) {
        _closeDrawer();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.gameButtonB) {
        _closeDrawer();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // 2. When TV Drawer is closed, detect Left at far-left boundary
    if (key == LogicalKeyboardKey.arrowLeft) {
      final primary = FocusManager.instance.primaryFocus;
      if (primary == null || primary.context == null) {
        // No item has focus or screen has no horizontally navigable items: open drawer naturally
        _openDrawer();
        return KeyEventResult.handled;
      }

      // Do NOT intercept when editing text inside an input field
      if (primary.context!.findAncestorStateOfType<EditableTextState>() != null) {
        return KeyEventResult.ignored;
      }

      // Do NOT intercept if an overlay/modal route (e.g. dialog, popup menu) is active
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return KeyEventResult.ignored;
      }

      Offset? oldOffset;
      final oldContext = primary.context;
      if (oldContext != null && oldContext.mounted) {
        final renderObj = oldContext.findRenderObject();
        if (renderObj is RenderBox && renderObj.hasSize) {
          oldOffset = renderObj.localToGlobal(Offset.zero);
        }
      }

      final moved = primary.focusInDirection(TraversalDirection.left);
      if (!moved) {
        if (_isAtLeftBoundary(primary)) {
          _openDrawer(fromNode: primary);
          return KeyEventResult.handled;
        }
      } else {
        // Focus reported moved. Verify if it actually moved horizontally within the current row/carousel
        // or erroneously jumped across vertical sections (e.g. into the hero section or section above).
        final newFocus = FocusManager.instance.primaryFocus;
        if (oldOffset != null && newFocus != null && newFocus.context != null && newFocus.context!.mounted) {
          final newRenderObj = newFocus.context!.findRenderObject();
          if (newRenderObj is RenderBox && newRenderObj.hasSize) {
            final newOffset = newRenderObj.localToGlobal(Offset.zero);
            final verticalJump = (newOffset.dy - oldOffset.dy).abs();
            if (verticalJump > 50.0 && _isAtLeftBoundary(primary)) {
              // The original focused item was already at the left boundary of its carousel/content,
              // and focus jumped vertically across sections instead of navigating horizontally.
              _openDrawer(fromNode: primary);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;

    return TvDrawerScope(
      openDrawer: () => _openDrawer(fromNode: FocusManager.instance.primaryFocus),
      closeDrawer: _closeDrawer,
      isOpen: _isDrawerOpen,
      child: Scaffold(
        backgroundColor: ColorPalette.backgroundBlack,
        body: Stack(
          children: [
            // The current active branch from the indexed stack
            isTv
                ? Focus(
                    autofocus: true,
                    skipTraversal: true,
                    onKeyEvent: _handleShellKeyEvent,
                    child: widget.navigationShell,
                  )
                : widget.navigationShell,

            // Mobile & Tablet: Shared floating bottom navigation dock
            if (!isTv)
              FloatingBottomNav(
                currentIndex: widget.navigationShell.currentIndex,
                onTabSelected: (index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation: index == widget.navigationShell.currentIndex,
                  );
                },
              ),

            // TV Only: Edge-Triggered Navigation Drawer
            if (isTv)
              TvNavigationDrawer(
                currentIndex: widget.navigationShell.currentIndex,
                isOpen: _isDrawerOpen,
                onClose: _closeDrawer,
                onDestinationSelected: (index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation: index == widget.navigationShell.currentIndex,
                  );
                  _closeDrawer();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A placeholder screen for secondary tabs (Anime, Profile)
class TabPlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const TabPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorPalette.backgroundBlack, ColorPalette.gradientEnd],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorPalette.ghostBorder),
                ),
                child: Icon(icon, size: 34, color: ColorPalette.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon in the next release',
                style: TextStyle(color: ColorPalette.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
