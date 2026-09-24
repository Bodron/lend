import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class VerificationApi {
  VerificationApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<VerificationStatus> status(String token) async {
    final response = await _client
        .get(
          Uri.parse('${AuthApi.baseUrl}/payments/identity/status'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    final body = _decode(response);
    return VerificationStatus(
      identityVerified: body['identityVerified'] == true,
    );
  }

  Future<String?> startIdentity(String token) async {
    final body = _decode(
      await _client
          .post(
            Uri.parse('${AuthApi.baseUrl}/payments/identity/start'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 12)),
    );
    final url = (body['url'] ?? '').toString();
    return url.isEmpty ? null : url;
  }

  Future<NativeIdentitySession?> startNativeIdentity(String token) async {
    final body = _decode(
      await _client
          .post(
            Uri.parse('${AuthApi.baseUrl}/payments/identity/native/start'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 12)),
    );
    if (body['verified'] == true || body['processing'] == true) return null;
    final id = body['sessionId'];
    final secret = body['ephemeralKeySecret'];
    if (id is! String || id.isEmpty || secret is! String || secret.isEmpty) {
      throw Exception('Sesiunea Stripe Identity nu este disponibila.');
    }
    return NativeIdentitySession(id: id, ephemeralKeySecret: secret);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message'] : null;
      throw Exception(
        message is List
            ? message.join('\n')
            : message?.toString() ?? 'Verificarea nu a reusit.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Raspuns invalid de la server.');
    }
    return decoded;
  }
}

class VerificationStatus {
  const VerificationStatus({required this.identityVerified});

  final bool identityVerified;
  bool get complete => identityVerified;
}

class NativeIdentitySession {
  const NativeIdentitySession({
    required this.id,
    required this.ephemeralKeySecret,
  });

  final String id;
  final String ephemeralKeySecret;
}
