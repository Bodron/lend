import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class RentalOrdersApi {
  RentalOrdersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RentalOrder> create({
    required String accessToken,
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/rental-orders'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
        'startDate': _dateKey(startDate),
        'endDate': _dateKey(endDate),
      }),
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru comanda.');
    }

    return RentalOrder.fromJson(payload);
  }

  Future<List<RentalOrder>> findMine(String accessToken) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/rental-orders/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! List) {
      throw RentalOrdersApiException('Raspuns invalid pentru inchirieri.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(RentalOrder.fromJson)
        .toList();
  }

  String _extractMessage(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];

      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return 'Nu am putut crea comanda. Incearca din nou.';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class RentalOrder {
  const RentalOrder({
    required this.id,
    required this.status,
    required this.productTitle,
    required this.productImageUrl,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.subtotal,
    required this.serviceFee,
    required this.deposit,
    required this.total,
  });

  final String id;
  final String status;
  final String productTitle;
  final String productImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int rentalDays;
  final int subtotal;
  final int serviceFee;
  final int deposit;
  final int total;

  factory RentalOrder.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productSnapshot'];
    final productSnapshot = snapshot is Map<String, dynamic>
        ? snapshot
        : const <String, dynamic>{};

    return RentalOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      productTitle: (productSnapshot['title'] ?? '').toString(),
      productImageUrl: (productSnapshot['imageUrl'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
      rentalDays: _toInt(json['rentalDays']),
      subtotal: _toInt(json['subtotal']),
      serviceFee: _toInt(json['serviceFee']),
      deposit: _toInt(json['deposit']),
      total: _toInt(json['total']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class RentalOrdersApiException implements Exception {
  RentalOrdersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
