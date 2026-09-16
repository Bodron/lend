import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class PaymentsApi {
  PaymentsApi({http.Client? client}) : _client = client ?? http.Client();

  static const _requestTimeout = Duration(seconds: 8);
  static const _payoutRequestTimeout = Duration(seconds: 20);

  final http.Client _client;

  Future<PaymentsConfig> getConfig() async {
    final response = await _client
        .get(Uri.parse('${AuthApi.baseUrl}/payments/config'))
        .timeout(_requestTimeout);
    final payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException(
        _errorMessage(payload, 'Nu am putut incarca setarile Stripe.'),
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Raspuns invalid pentru setarile Stripe.');
    }

    return PaymentsConfig.fromJson(payload);
  }

  Future<String> createConnectOnboardingLink(String accessToken) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/payments/connect/onboarding-link'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException(
        _errorMessage(payload, 'Nu am putut porni configurarea platilor.'),
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Raspuns invalid pentru onboarding.');
    }

    return (payload['url'] ?? '').toString();
  }

  Future<PayoutRequestResult> requestPayout(
    String accessToken, {
    String? businessType,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/payments/payouts/request'),
          headers: headers,
          body: jsonEncode(
            businessType == null ? {} : {'businessType': businessType},
          ),
        )
        .timeout(_payoutRequestTimeout);
    final payload = _decodePayload(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException(
        _errorMessage(payload, 'Nu am putut porni retragerea banilor.'),
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Raspuns invalid pentru retragere.');
    }

    return PayoutRequestResult.fromJson(payload);
  }

  Object? _decodePayload(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String _errorMessage(Object? payload, String fallback) {
    if (payload is! Map<String, dynamic>) {
      return fallback;
    }

    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    if (message is List && message.isNotEmpty) {
      return message.whereType<String>().join('\n');
    }

    final error = payload['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return fallback;
  }
}

class PaymentsConfig {
  const PaymentsConfig({required this.publishableKey});

  final String publishableKey;

  factory PaymentsConfig.fromJson(Map<String, dynamic> json) {
    return PaymentsConfig(
      publishableKey: (json['publishableKey'] ?? '').toString(),
    );
  }
}

class PaymentsApiException implements Exception {
  PaymentsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PayoutRequestResult {
  const PayoutRequestResult({
    required this.status,
    required this.url,
    required this.amount,
  });

  final String status;
  final String url;
  final int amount;

  bool get requiresOnboarding => status == 'requires_onboarding';
  bool get paidOut => status == 'paid_out';

  factory PayoutRequestResult.fromJson(Map<String, dynamic> json) {
    return PayoutRequestResult(
      status: (json['status'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      amount: _toInt(json['amount']),
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
