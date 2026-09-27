import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class Viewing {
  const Viewing({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.ownerId,
    required this.visitorId,
    required this.visitorName,
    required this.startsAt,
    required this.status,
    required this.priceRon,
    required this.serviceFeeRon,
    required this.hasCommission,
    this.stripeTransferId,
    this.refundStatus,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String ownerId;
  final String visitorId;
  final String visitorName;
  final DateTime startsAt;
  final String status;
  final int priceRon;
  final int serviceFeeRon;
  final bool hasCommission;
  final String? stripeTransferId;
  int get totalRon => priceRon + serviceFeeRon;
  final String? refundStatus;

  factory Viewing.fromJson(Map<String, dynamic> json) => Viewing(
    id: (json['_id'] ?? '').toString(),
    productId: (json['productId'] ?? '').toString(),
    productTitle: (json['productTitle'] ?? '').toString(),
    ownerId: (json['ownerId'] ?? '').toString(),
    visitorId: (json['visitorId'] ?? '').toString(),
    visitorName: (json['visitorName'] ?? '').toString(),
    startsAt: DateTime.parse((json['startsAt'] ?? '').toString()).toLocal(),
    status: (json['status'] ?? '').toString(),
    priceRon: (json['priceRon'] as num?)?.toInt() ?? 0,
    serviceFeeRon: (json['serviceFeeRon'] as num?)?.toInt() ?? 0,
    hasCommission: json.containsKey('serviceFeeRon'),
    stripeTransferId: json['stripeTransferId']?.toString(),
    refundStatus: json['refundStatus']?.toString(),
  );
}

class ViewingsApi {
  ViewingsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Viewing>> mine(String token) async {
    final data = await _send('GET', 'me', token);
    if (data is! List) throw Exception('Invalid viewings response');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Viewing.fromJson)
        .toList();
  }

  Future<Viewing> request(
    String token,
    String productId,
    DateTime startsAt,
  ) async {
    final data = await _send(
      'POST',
      '',
      token,
      body: {
        'productId': productId,
        'startsAt': startsAt.toUtc().toIso8601String(),
      },
    );
    return Viewing.fromJson(data as Map<String, dynamic>);
  }

  Future<Viewing> action(String token, String id, String action) async {
    final data = await _send('PATCH', '$id/$action', token);
    return Viewing.fromJson(data as Map<String, dynamic>);
  }

  Future<String> startPayment(String token, String id) async {
    final data =
        await _send('POST', '$id/payment', token) as Map<String, dynamic>;
    return (data['clientSecret'] ?? '').toString();
  }

  Future<Viewing> confirmPayment(String token, String id) =>
      action(token, id, 'payment-confirmed');

  Future<Object?> _send(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${AuthApi.baseUrl}/viewings${path.isEmpty ? '' : '/$path'}',
    );
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
      _ => _client.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
    }.timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic> ? data['message'] : null;
      throw Exception(
        message is List
            ? message.join('\n')
            : message?.toString() ?? 'Request failed',
      );
    }
    return data;
  }
}
