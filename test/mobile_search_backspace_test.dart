import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/search/screens/search_page.dart';
import 'package:sparrow/main.dart';
import 'package:sparrow/navigation/app_router.dart';

void main() {
  group('Mobile Search Backspace Keyboard Bug Fix Tests', () {
    testWidgets(
      'Mobile search: Backspace deletes characters and preserves search field focus and open keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        appRouter.go('/');
        await tester.pumpWidget(const SparrowApp());
        await tester.pumpAndSettle();

        // 1. Navigate to Search
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        expect(find.byType(SearchPage), findsOneWidget);

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // 2. Tap search field to focus it
        await tester.tap(textFieldFinder);
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Search field must be focused');

        // 3. Type some text
        await tester.enterText(textFieldFinder, 'batman');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();

        expect(find.text('batman'), findsOneWidget);
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Field should retain focus after typing');

        // 4. Press Backspace repeatedly (both key events and IME deletions)
        // Simulating soft keyboard backspace key event
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pumpAndSettle();
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Field must retain focus after backspace key event');

        // Delete a character via IME
        await tester.enterText(textFieldFinder, 'batma');
        await tester.pumpAndSettle();
        expect(find.text('batma'), findsOneWidget);
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Field must retain focus after deleting character');

        // Delete another character
        await tester.enterText(textFieldFinder, 'batm');
        await tester.pumpAndSettle();
        expect(find.text('batm'), findsOneWidget);
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Field must retain focus after deleting another character');

        // Continue typing after deleting characters
        await tester.enterText(textFieldFinder, 'batman begins');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();
        expect(find.text('batman begins'), findsOneWidget);
        expect(textField.focusNode?.hasFocus, isTrue);

        // 5. Clear entire query via backspace
        await tester.enterText(textFieldFinder, '');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();
        expect(textField.focusNode?.hasFocus, isTrue, reason: 'Keyboard must remain open and field focused when query is cleared via backspace');

        // Continue typing again after clearing
        await tester.enterText(textFieldFinder, 'spiderman');
        await tester.pumpAndSettle();
        expect(find.text('spiderman'), findsOneWidget);
        expect(textField.focusNode?.hasFocus, isTrue);
      },
    );
  });
}
