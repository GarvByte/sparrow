import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sparrow/theme/color_palette.dart';

/// TV-only Navigation Drawer destination item metadata.
class TvDrawerDestination {
  final int index;
  final String label;
  final IconData icon;

  const TvDrawerDestination({
    required this.index,
    required this.label,
    required this.icon,
  });
}

const List<TvDrawerDestination> kTvDrawerDestinations = [
  TvDrawerDestination(index: 0, label: 'Home', icon: Icons.home_rounded),
  TvDrawerDestination(index: 1, label: 'Search', icon: Icons.explore_outlined),
  TvDrawerDestination(
    index: 2,
    label: 'TV Shows',
    icon: Icons.auto_awesome_rounded,
  ),
  TvDrawerDestination(
    index: 3,
    label: 'Watchlist',
    icon: Icons.bookmarks_rounded,
  ),
];

/// TV-Only Navigation Drawer widget.
///
/// Features:
/// - Replaces FloatingBottomNav exclusively in TV layout.
/// - Matches Sparrow's black and neon green design language.
/// - Contains exactly the 4 primary navigation destinations:
///   Home, Search, TV Shows, Watchlist.
/// - Fully navigable via D-pad (Up/Down) and keyboard arrow keys.
/// - Enter/Select switches navigation branch and closes drawer.
/// - Right arrow key or Back/Escape dismisses drawer and restores focus.
/// - Visually distinct active/selected indicator.
/// - Clean slide-in animation with semi-transparent scrim keeping main content visible.
/// - Excludes focus when closed so offscreen targets never trap or steal focus.
class TvNavigationDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onClose;
  final bool isOpen;

  const TvNavigationDrawer({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onClose,
    required this.isOpen,
  });

  static const double drawerWidth = 270.0;

  @override
  State<TvNavigationDrawer> createState() => _TvNavigationDrawerState();
}

class _TvNavigationDrawerState extends State<TvNavigationDrawer> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      kTvDrawerDestinations.length,
      (i) => FocusNode(debugLabel: 'tv_drawer_item_$i'),
    );
  }

  @override
  void didUpdateWidget(TvNavigationDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isOpen && widget.isOpen) {
      // When drawer opens, focus the currently selected destination
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isOpen) {
          final targetIndex = widget.currentIndex.clamp(
            0,
            _focusNodes.length - 1,
          );
          _focusNodes[targetIndex].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      widget.onClose();
      return;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.gameButtonB) {
      widget.onClose();
      return;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (index < _focusNodes.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
      return;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      widget.onDestinationSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent scrim over main content
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.isOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              opacity: widget.isOpen ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ),

        // Sliding Drawer Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          left: widget.isOpen ? 0.0 : -TvNavigationDrawer.drawerWidth - 10,
          top: 0,
          bottom: 0,
          width: TvNavigationDrawer.drawerWidth,
          child: ExcludeFocus(
            excluding: !widget.isOpen,
            child: FocusScope(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorPalette.backgroundBlack,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorPalette.backgroundBlack,
                      ColorPalette.surface,
                    ],
                  ),
                  border: const Border(
                    right: BorderSide(
                      color: ColorPalette.ghostBorder,
                      width: 1.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 32,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Sparrow Logo & TV Telemetry
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Offstage(offstage: true, child: Text('SPARROW')),
                            Image.asset(
                              'assets/images/sparrow_text_logo.png',
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'CINEMATIC HUB',
                              style: TextStyle(
                                color: ColorPalette.primaryGreen,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(
                          color: ColorPalette.ghostBorder,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation Destinations
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: kTvDrawerDestinations.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final dest = kTvDrawerDestinations[index];
                            final isSelected =
                                widget.currentIndex == dest.index;

                            return _TvDrawerItem(
                              destination: dest,
                              isSelected: isSelected,
                              focusNode: _focusNodes[index],
                              onKey: (event) => _handleKey(index, event),
                              onTap: () =>
                                  widget.onDestinationSelected(dest.index),
                            );
                          },
                        ),
                      ),

                      // Bottom Hint / Remote Legend
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '▶',
                                style: TextStyle(
                                  color: ColorPalette.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Press Right to return',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorPalette.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
      ],
    );
  }
}

class _TvDrawerItem extends StatefulWidget {
  final TvDrawerDestination destination;
  final bool isSelected;
  final FocusNode focusNode;
  final ValueChanged<KeyEvent> onKey;
  final VoidCallback onTap;

  const _TvDrawerItem({
    required this.destination,
    required this.isSelected,
    required this.focusNode,
    required this.onKey,
    required this.onTap,
  });

  @override
  State<_TvDrawerItem> createState() => _TvDrawerItemState();
}

class _TvDrawerItemState extends State<_TvDrawerItem> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_TvDrawerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        widget.onKey(event);
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.gameButtonB) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _isFocused
                ? const Color.fromARGB(74, 255, 255, 255)
                : (widget.isSelected
                      ? const Color.fromARGB(
                          255,
                          51,
                          52,
                          53,
                        ).withValues(alpha: 0.75)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? ColorPalette.primaryGreen
                  : (widget.isSelected
                        ? ColorPalette.primaryGreen.withValues(alpha: 0.5)
                        : Colors.transparent),
              width: _isFocused ? 2.0 : 1.0,
            ),
            // boxShadow: _isFocused
            //     ? [
            //         BoxShadow(
            //           color: ColorPalette.fontWhite.withValues(alpha: 0.35),
            //           blurRadius: 16,
            //           offset: const Offset(0, 2),
            //         ),
            //       ]
            //     : null,
          ),
          child: Row(
            children: [
              // Active emerald indicator pill on left edge
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                height: widget.isSelected ? 26 : 0,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: widget.isSelected ? 10 : 4),

              // Destination Icon
              Icon(
                widget.destination.icon,
                size: 22,
                color: _isFocused
                    ? ColorPalette.primaryGreen
                    : (widget.isSelected
                          ? ColorPalette.primaryGreen
                          : ColorPalette.textSecondary),
              ),
              const SizedBox(width: 14),

              // Label
              Expanded(
                child: Text(
                  widget.destination.label,
                  style: TextStyle(
                    color: _isFocused
                        ? ColorPalette.fontWhite
                        : (widget.isSelected
                              ? ColorPalette.fontWhite
                              : ColorPalette.textMuted),
                    fontSize: 15,
                    fontWeight: widget.isSelected || _isFocused
                        ? FontWeight.w800
                        : FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Active dot if selected
              if (widget.isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ColorPalette.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
