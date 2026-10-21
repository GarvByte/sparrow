import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Wraps a poster card to enable TV remote and keyboard D-pad navigation.
///
/// Restricted strictly to TV layouts via [SparrowResponsive.isTvOrDesktop].
/// On phone and tablet devices, returns [child] directly with zero overhead,
/// preserving existing touch gestures and ripple behavior.
class FocusablePosterCard extends StatelessWidget {
  const FocusablePosterCard({
    super.key,
    required this.child,
    required this.onSelected,
    this.autofocus = false,
    this.borderRadius,
    this.scale = 1.05,
  });

  final Widget child;
  final VoidCallback onSelected;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (!context.responsive.isTvOrDesktop) {
      return child;
    }

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelected,
      autoScroll: true,
      effects: [
        DpadScaleEffect(scale: scale),
        DpadBorderEffect(
          width: 3.0,
          color: ColorPalette.primaryGreen,
          // borderRadius: effectiveRadius,
        ),
        DpadTintEffect(color: ColorPalette.fontWhite, opacity: 0.2),
        // DpadGlowEffect(
        //   color: ColorPalette.primaryGreen,
        //   blurRadius: 18,
        //   spreadRadius: 1.5,
        //   opacity: 0.45,
        //   borderRadius: effectiveRadius,
        // ),
      ],
      child: child,
    );
  }
}

/// Generic TV focusable container for buttons, chips, selectors, and controls.
///
/// Strictly active only when [SparrowResponsive.isTvOrDesktop] is true.
class TvFocusable extends StatelessWidget {
  const TvFocusable({
    super.key,
    required this.child,
    required this.onSelect,
    this.autofocus = false,
    this.borderRadius,
    this.scale = 1.04,
    this.borderWidth = 2.5,
    this.focusColor,
    this.onFocusChange,
  });

  final Widget child;
  final VoidCallback onSelect;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final double scale;
  final double borderWidth;
  final Color? focusColor;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    if (!context.responsive.isTvOrDesktop) {
      return child;
    }

    final effectiveRadius = borderRadius ?? BorderRadius.circular(14);
    final color = focusColor ?? ColorPalette.primaryGreen;

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      onFocusChange: onFocusChange,
      autoScroll: true,
      effects: [
        // DpadScaleEffect(scale: 1.05),
        DpadBorderEffect(width: 3, color: color, borderRadius: effectiveRadius),
        
        DpadGlowEffect(
          color: color,
          blurRadius: 14,
          spreadRadius: 1.0,
          opacity: 0.35,
          borderRadius: effectiveRadius,
        ),
      ],
      child: child,
    );
  }
}
