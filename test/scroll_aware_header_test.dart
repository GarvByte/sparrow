import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/shared/scroll_aware_header.dart';

void main() {
  testWidgets('ScrollAwareHeader hides on scroll down and reveals on scroll up', (tester) async {
    final controller = ScrollAwareHeaderController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: controller.handleScrollNotification,
                    child: ListView.builder(
                      itemCount: 50,
                      itemBuilder: (context, index) => SizedBox(
                        height: 80,
                        child: Text('Item $index'),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ScrollAwareHeader(
                      isVisible: controller.isVisible,
                      child: Container(
                        height: 60,
                        color: Colors.red,
                        child: const Text('HEADER'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Initial state: visible
    expect(controller.isVisible, isTrue);

    // Scroll down 200 pixels
    await tester.drag(find.text('Item 2'), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isFalse);

    // Scroll up 100 pixels
    await tester.drag(find.text('Item 5'), const Offset(0, 100));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);

    // Scroll back to top
    await tester.drag(find.text('Item 3'), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);
  });
}
