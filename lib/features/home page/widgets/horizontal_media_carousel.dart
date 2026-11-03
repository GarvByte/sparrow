import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/navigation/main_shell_scaffold.dart';
import 'package:sparrow/shared/responsive_utils.dart';

class HorizontalMediaCarousel extends StatelessWidget {
  final double height;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry padding;

  const HorizontalMediaCarousel({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    Widget list = ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );

    if (context.responsive.isTvOrDesktop) {
      list = DpadRegion(
        leftEdge: DpadEdgeBehavior.stop,
        onEdge: (direction) {
          if (direction == TraversalDirection.left) {
            TvDrawerScope.openOf(context);
          }
        },
        child: list,
      );
    }

    return SizedBox(
      height: height,
      child: list,
    );
  }
}
