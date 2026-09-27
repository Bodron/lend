import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lend/widgets/lend_toast.dart';

void main() {
  testWidgets('toast slides right before it disappears', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => LendToast.info(
                context,
                message: 'Test toast',
                duration: const Duration(seconds: 1),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    final startX = tester.getTopLeft(find.text('Test toast')).dx;

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 240));
    expect(
      tester.getTopLeft(find.text('Test toast')).dx,
      greaterThan(startX + 50),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Test toast'), findsNothing);
  });
}
