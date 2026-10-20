import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:sparrow/theme/color_palette.dart';

class FocusablePosterCard extends StatelessWidget {
  const FocusablePosterCard({
    super.key,
    required this.child,
    required this.onSelected,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback onSelected;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onSelected,
      autoScroll: true,
      effects: [
        DpadScaleEffect(scale: 1.05),
        DpadBorderEffect(width: 5, color: ColorPalette.primaryGreen),

        DpadTintEffect(color: ColorPalette.fontWhite, opacity: 0.2),
      ],
      child: child,
    );
  }
}
