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

  Future<String> createConnectOnboardingLink(
    String accessToken, {
    String? businessType,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/payments/connect/onboarding-link'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(
            businessType == null ? {} : {'businessType': businessType},
          ),
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

  Future<ConnectAccountStatus> getConnectStatus(String accessToken) async {
    final response = await _client
        .get(
          Uri.parse('${AuthApi.baseUrl}/payments/connect/status'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = _decodePayload(response.body);
    if (response.statusCode == 404) {
      final profileResponse = await _client
          .get(
            Uri.parse('${AuthApi.baseUrl}/auth/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(_requestTimeout);
      if (profileResponse.statusCode >= 200 &&
          profileResponse.statusCode < 300) {
        final profile = _decodePayload(profileResponse.body);
        if (profile is Map<String, dynamic>) {
          return ConnectAccountStatus.fromProfile(AuthUser.fromJson(profile));
        }
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException('Payout status is unavailable.');
    }
    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Răspuns invalid pentru contul de încasări.');
    }
    return ConnectAccountStatus.fromJson(payload);
  }

  Future<String> createConnectLoginLink(String accessToken) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/payments/connect/login-link'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = _decodePayload(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentsApiException(
        _errorMessage(payload, 'Nu am putut deschide contul de încasări.'),
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw PaymentsApiException('Răspuns invalid pentru contul de încasări.');
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

class ConnectAccountStatus {
  const ConnectAccountStatus({
    required this.connected,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.currentlyDue,
    required this.pastDue,
    required this.pendingVerification,
    required this.errors,
    this.isLive = true,
  });

  final bool connected;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final int currentlyDue;
  final int pastDue;
  final int pendingVerification;
  final List<String> errors;
  final bool isLive;

  factory ConnectAccountStatus.fromProfile(AuthUser user) =>
      ConnectAccountStatus(
        connected: user.stripeAccountId != null,
        payoutsEnabled: user.stripePayoutsEnabled,
        detailsSubmitted: user.stripeDetailsSubmitted,
        currentlyDue: 0,
        pastDue: 0,
        pendingVerification: 0,
        errors: const [],
        isLive: false,
      );

  bool get isReady =>
      connected &&
      payoutsEnabled &&
      detailsSubmitted &&
      currentlyDue == 0 &&
      pastDue == 0 &&
      errors.isEmpty;
  bool get needsAction =>
      connected && (currentlyDue > 0 || pastDue > 0 || errors.isNotEmpty);
  bool get isPending =>
      connected && !isReady && !needsAction && pendingVerification > 0;

  factory ConnectAccountStatus.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) => value is num ? value.toInt() : 0;
    return ConnectAccountStatus(
      connected: json['connected'] == true,
      payoutsEnabled: json['payoutsEnabled'] == true,
      detailsSubmitted: json['detailsSubmitted'] == true,
      currentlyDue: asInt(json['currentlyDue']),
      pastDue: asInt(json['pastDue']),
      pendingVerification: asInt(json['pendingVerification']),
      errors: (json['errors'] as List?)?.whereType<String>().toList() ?? [],
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
