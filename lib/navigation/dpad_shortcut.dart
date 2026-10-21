import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sparrow/navigation/app_router.dart';

/// Top-level keyboard and TV remote Back shortcut handler.
///
/// Maps Escape, Backspace, Android TV remote Back ([LogicalKeyboardKey.goBack]),
/// and Gamepad B ([LogicalKeyboardKey.gameButtonB]) to GoRouter pop navigation.
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
            key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.gameButtonB) {
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
