import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lend/screens/messages_screen.dart';
import 'package:lend/services/products_api.dart';

void main() {
  final product = LendProduct(
    id: 'product-1',
    slug: 'test',
    title: 'Test',
    category: 'Objects',
    categorySlug: 'objects',
    description: 'Test listing',
    pricePerDay: 80,
    pricePerMonth: 500,
    deposit: 0,
    city: 'Iasi',
    address: '',
    latitude: null,
    longitude: null,
    pickupTime: '10:00',
    returnTime: '18:00',
    ownerName: 'Owner',
    rating: 5,
    isAvailable: true,
    images: const [],
  );

  Future<void> openSheet(WidgetTester tester, DateTime today) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<Object>(
                context: context,
                isScrollControlled: true,
                builder: (_) => OfferDraftSheet(
                  modes: const ['hour', 'day', 'month'],
                  today: today,
                  product: product,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'one tap selects one rental day and amount stays above keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
      final today = DateTime.now().add(const Duration(days: 2));
      final firstDay = today.add(const Duration(days: 1));
      await openSheet(tester, today);
      await tester.tap(find.text('Pe zi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('${firstDay.day}'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.textContaining('1 zi'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuă'))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Continuă'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '75');
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(TextField)).bottom, lessThan(500));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Trimite oferta'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hourly offer uses one date with pickup and return times', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final today = DateTime.now().add(const Duration(days: 2));
    await openSheet(tester, today);
    await tester.tap(find.text('Pe oră'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${today.day}'));
    await tester.pumpAndSettle();

    expect(find.text('Ridicare'), findsOneWidget);
    expect(find.text('Retur'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuă'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('monthly offer selects a full month with one date tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final today = DateTime.now().add(const Duration(days: 2));
    final firstDay = today.add(const Duration(days: 1));
    await openSheet(tester, today);
    await tester.tap(find.text('Pe lună'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${firstDay.day}'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 lună'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuă'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
