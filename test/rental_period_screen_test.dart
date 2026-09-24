import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lend/l10n/generated_localizations.dart';
import 'package:lend/screens/rental_period_screen.dart';
import 'package:lend/services/products_api.dart';
import 'package:lend/services/rental_orders_api.dart';

void main() {
  testWidgets('selects a multi-day rental with two date taps', (tester) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final month = DateTime(DateTime.now().year, DateTime.now().month + 2);
    final api = RentalOrdersApi(
      client: MockClient(
        (_) async => http.Response(
          '{"unavailableDates":[],"reservations":[],"manualBlocks":[]}',
          200,
        ),
      ),
    );
    final product = LendProduct(
      id: 'product-1',
      slug: 'test',
      title: 'Test',
      category: 'Objects',
      categorySlug: 'objects',
      description: 'Test listing',
      pricePerDay: 100,
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

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          GeneratedLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: RentalPeriodScreen(
          enableRealtime: false,
          product: product,
          rentalOrdersApi: api,
          initialStartDate: DateTime(month.year, month.month, 1),
          initialEndDate: DateTime(month.year, month.month, 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('5').first);
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();
    expect(find.text('Now choose the end date'), findsOneWidget);

    await tester.ensureVisible(find.text('7').first);
    await tester.tap(find.text('7').first);
    await tester.pumpAndSettle();
    expect(find.text('Now choose the end date'), findsNothing);
    expect(find.textContaining('(2 days)'), findsOneWidget);
  });
}
