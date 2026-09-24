import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lend/l10n/generated_localizations.dart';
import 'package:lend/screens/availability_management_screen.dart';
import 'package:lend/services/products_api.dart';
import 'package:lend/services/rental_orders_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('one tap blocks exactly one day', (tester) async {
    final posts = <Map<String, dynamic>>[];
    await _pumpScreen(tester, posts);
    final month = _nextMonth();

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    final blockDay = find.text('Block day');
    expect(blockDay, findsOneWidget);
    await tester.ensureVisible(blockDay);
    await tester.tap(blockDay);
    await tester.pumpAndSettle();

    expect(posts, hasLength(1));
    expect(posts.single['startDate'], _dateKey(month, 5));
    expect(posts.single['endDate'], _dateKey(month, 6));
  });

  testWidgets('two taps block the whole selected range', (tester) async {
    final posts = <Map<String, dynamic>>[];
    await _pumpScreen(tester, posts);
    final month = _nextMonth();

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7').first);
    await tester.pumpAndSettle();

    final blockRange = find.text('Block period');
    expect(blockRange, findsOneWidget);
    await tester.ensureVisible(blockRange);
    await tester.tap(blockRange);
    await tester.pumpAndSettle();

    expect(posts, hasLength(1));
    expect(posts.single['startDate'], _dateKey(month, 5));
    expect(posts.single['endDate'], _dateKey(month, 8));
  });

  testWidgets('can select a visible day from the next month', (tester) async {
    final posts = <Map<String, dynamic>>[];
    final requests = <Uri>[];
    await _pumpScreen(tester, posts, getRequests: requests);
    final month = _nextMonth();

    final nextMonthDay = find.text('2').last;
    await tester.ensureVisible(nextMonthDay);
    await tester.tap(nextMonthDay);
    await tester.pumpAndSettle();

    final blockDay = find.text('Block day');
    expect(blockDay, findsOneWidget);
    await tester.ensureVisible(blockDay);
    await tester.tap(blockDay);
    await tester.pumpAndSettle();

    expect(posts.single['startDate'], _dateKey(month, 2));
    expect(posts.single['endDate'], _dateKey(month, 3));
    expect(
      requests.first.queryParameters['to']!.compareTo(_dateKey(month, 2)),
      greaterThan(0),
    );
  });

  testWidgets('an hourly rental prevents a whole-day manual block', (
    tester,
  ) async {
    final posts = <Map<String, dynamic>>[];
    final month = _nextMonth();
    final occupiedDay = _dateKey(month, 5);
    await _pumpScreen(
      tester,
      posts,
      availabilityPayload: jsonEncode({
        'unavailableDates': [occupiedDay],
        'reservations': [
          {
            'id': 'hourly-order',
            'startDate': occupiedDay,
            'endDate': occupiedDay,
            'pickupTime': '10:00',
            'returnTime': '12:00',
            'status': 'confirmed',
          },
        ],
        'manualBlocks': [],
      }),
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    expect(find.text('Block day'), findsNothing);
    expect(posts, isEmpty);
  });

  testWidgets('an overnight turnaround prevents blocking the next day', (
    tester,
  ) async {
    final posts = <Map<String, dynamic>>[];
    final month = _nextMonth();
    final occupiedDay = _dateKey(month, 5);
    final nextDay = _dateKey(month, 6);
    await _pumpScreen(
      tester,
      posts,
      availabilityPayload: jsonEncode({
        'unavailableDates': [occupiedDay, nextDay],
        'reservations': [
          {
            'id': 'late-hourly-order',
            'startDate': occupiedDay,
            'endDate': occupiedDay,
            'pickupTime': '23:00',
            'returnTime': '23:30',
            'status': 'confirmed',
            'occupiedFrom': '${occupiedDay}T23:00:00.000Z',
            'occupiedUntil': '${nextDay}T00:30:00.000Z',
          },
        ],
        'manualBlocks': [],
      }),
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').first);
    await tester.pumpAndSettle();

    expect(find.text('Block day'), findsNothing);
    expect(posts, isEmpty);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<Map<String, dynamic>> posts, {
  List<Uri>? getRequests,
  String? availabilityPayload,
}) async {
  tester.view.physicalSize = const Size(400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  SharedPreferences.setMockInitialValues({'auth.accessToken': 'test-token'});

  final api = RentalOrdersApi(
    client: MockClient((request) async {
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        posts.add(body);
        return http.Response(
          jsonEncode({
            '_id': 'block-1',
            'startDate': body['startDate'],
            'endDate': body['endDate'],
            'reason': '',
          }),
          201,
        );
      }
      getRequests?.add(request.url);
      return http.Response(
        availabilityPayload ??
            '{"unavailableDates":[],"reservations":[],"manualBlocks":[]}',
        200,
      );
    }),
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
      home: AvailabilityManagementScreen(
        enableRealtime: false,
        product: const LendProduct(
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
          images: [],
        ),
        rentalOrdersApi: api,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DateTime _nextMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1);
}

String _dateKey(DateTime month, int day) {
  final date = DateTime(month.year, month.month, day);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
