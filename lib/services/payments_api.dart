import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class PaymentsApi {
  PaymentsApi({http.Client? client}) : _client = client ?? http.Client();

  static const _requestTimeout = Duration(seconds: 8);

  final http.Client _client;

  Future<PaymentsConfig> getConfig() async {
    final response = await _client
        .get(Uri.parse('${AuthApi.baseUrl}/payments/config'))
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException('Nu am putut incarca setarile Stripe.');
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
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException('Nu am putut porni configurarea platilor.');
    }

    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Raspuns invalid pentru onboarding.');
    }

    return (payload['url'] ?? '').toString();
  }

  Future<PayoutRequestResult> requestPayout(String accessToken) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/payments/payouts/request'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException('Nu am putut porni retragerea banilor.');
    }

    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Raspuns invalid pentru retragere.');
    }

    return PayoutRequestResult.fromJson(payload);
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
