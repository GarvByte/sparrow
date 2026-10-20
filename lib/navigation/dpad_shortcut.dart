import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/navigation/app_router.dart';

class AppBackShortcuts extends StatelessWidget {
  final Widget child;

  const AppBackShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.backspace) {
          if (appRouter.canPop()) {
            appRouter.pop();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
