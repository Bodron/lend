import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lend/services/payments_api.dart';

void main() {
  test(
    'uses the profile when the payout status route is unavailable',
    () async {
      final requestedPaths = <String>[];
      final api = PaymentsApi(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path.endsWith('/payments/connect/status')) {
            return http.Response(
              'Cannot GET /api/payments/connect/status',
              404,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'fullName': 'Test User',
              'email': 'test@example.com',
              'phone': '0700000000',
              'stripeAccountId': 'acct_123',
              'stripePayoutsEnabled': true,
              'stripeDetailsSubmitted': true,
            }),
            200,
          );
        }),
      );

      final status = await api.getConnectStatus('token');

      expect(status.connected, isTrue);
      expect(status.isLive, isFalse);
      expect(status.payoutsEnabled, isTrue);
      expect(requestedPaths.last, endsWith('/auth/me'));
    },
  );
}
