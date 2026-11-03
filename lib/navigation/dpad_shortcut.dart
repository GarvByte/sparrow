import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sparrow/navigation/app_router.dart';
import 'package:sparrow/shared/responsive_utils.dart';

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
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;

        // Physical back buttons (both on mobile and Android TV / Fire TV remotes)
        // are handled natively by the platform navigation pipeline (RouterDelegate.popRoute).
        // Intercepting goBack key events here causes duplicate pops (e.g. details closing
        // all the way to the root search page, or player closing when dismissing an overflow sheet).
        if (key == LogicalKeyboardKey.goBack) {
          return KeyEventResult.ignored;
        }

        // On mobile devices, Backspace is an IME / keyboard text-editing key,
        // not a navigation shortcut. Intercepting it here causes the mobile keyboard
        // to close and search fields to lose focus whenever a character is deleted.
        // Even on TV/desktop, if an input field is actively editing text, Backspace
        // must edit text rather than trigger pop navigation.
        final isTv = context.responsive.isTvOrDesktop;
        final isEditingText = FocusManager.instance.primaryFocus?.context
                ?.findAncestorStateOfType<EditableTextState>() !=
            null;

        if (key == LogicalKeyboardKey.backspace && (!isTv || isEditingText)) {
          return KeyEventResult.ignored;
        }

        if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.gameButtonB) {
          appRouter.routerDelegate.popRoute();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
