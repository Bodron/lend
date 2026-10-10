import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.version,
    required this.hash,
    required this.title,
    required this.body,
  });

  final String id;
  final String version;
  final String hash;
  final String title;
  final String body;

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    id: json['id'] as String,
    version: json['version'] as String,
    hash: json['hash'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
  );
}

class LegalAcceptanceStatus {
  const LegalAcceptanceStatus({
    required this.current,
    required this.acceptedAt,
  });

  final bool current;
  final Map<String, DateTime?> acceptedAt;

  factory LegalAcceptanceStatus.fromJson(Map<String, dynamic> json) {
    final entries = json['documents'] as List<dynamic>;
    return LegalAcceptanceStatus(
      current: json['current'] == true,
      acceptedAt: {
        for (final entry in entries.cast<Map<String, dynamic>>())
          entry['id'] as String: entry['acceptedAt'] == null
              ? null
              : DateTime.parse(entry['acceptedAt'] as String),
      },
    );
  }
}

class LegalApi {
  LegalApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LegalDocument>> documents(String language) async {
    final response = await _client
        .get(Uri.parse('${AuthApi.baseUrl}/legal/documents?lang=$language'))
        .timeout(const Duration(seconds: 10));
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((entry) => LegalDocument.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<LegalAcceptanceStatus> status(String token) async {
    final response = await _client
        .get(
          Uri.parse('${AuthApi.baseUrl}/legal/status'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    _check(response);
    return LegalAcceptanceStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<LegalAcceptanceStatus> accept(
    String token,
    List<LegalDocument> documents,
  ) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/legal/accept'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'documents': [
              for (final document in documents)
                {
                  'id': document.id,
                  'version': document.version,
                  'hash': document.hash,
                },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));
    _check(response);
    return LegalAcceptanceStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String? message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['message'];
      if (detail is String) message = detail;
      if (detail is List) message = detail.join(' ');
    } catch (_) {
      // The HTTP status still identifies the failed request.
    }
    throw LegalApiException(
      message ?? 'Eroare la documentele legale (${response.statusCode}).',
      response.statusCode,
    );
  }
}

class LegalApiException implements Exception {
  const LegalApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
