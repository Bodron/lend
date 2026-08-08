import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _configuredBaseUrl = String.fromEnvironment('APP_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    return withoutTrailingSlash.endsWith('/api')
        ? withoutTrailingSlash
        : '$withoutTrailingSlash/api';
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _postAuth('/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _postAuth('/auth/login', {'email': email, 'password': password});
  }

  Future<AuthSession> loginWithApple({
    required String identityToken,
    String? fullName,
    String? nonce,
  }) async {
    return _postAuth('/auth/apple', {
      'identityToken': identityToken,
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
      if (nonce != null && nonce.trim().isNotEmpty) 'nonce': nonce.trim(),
    });
  }

  Future<AuthSession> loginWithGoogle({
    required String idToken,
    String? fullName,
  }) async {
    return _postAuth('/auth/google', {
      'idToken': idToken,
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
    });
  }

  Future<AuthUser> me(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_extractMessage(payload));
    }

    return AuthUser.fromJson(payload);
  }

  Future<AuthUser> updateAvatar({
    required String accessToken,
    required String avatarUrl,
    String? avatarKey,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/auth/me/avatar'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'avatarUrl': avatarUrl,
        if (avatarKey != null && avatarKey.isNotEmpty) 'avatarKey': avatarKey,
      }),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_extractMessage(payload));
    }

    return AuthUser.fromJson(payload);
  }

  Future<AuthSession> _postAuth(String path, Map<String, String> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_extractMessage(payload));
    }

    final session = AuthSession.fromJson(payload);
    await AuthSessionStore.save(session);
    return session;
  }

  String _extractMessage(Map<String, dynamic> payload) {
    final message = payload['message'];

    if (message is List && message.isNotEmpty) {
      return message.join('\n');
    }

    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'A apărut o eroare. Încearcă din nou.';
  }
}

class AuthApiException implements Exception {
  AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.avatarKey,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? avatarKey;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatarUrl: _optionalString(json['avatarUrl']),
      avatarKey: _optionalString(json['avatarKey']),
    );
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class AuthSessionStore {
  static const _tokenKey = 'auth.accessToken';
  static const _userNameKey = 'auth.user.fullName';

  static Future<void> save(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, session.accessToken);
    await preferences.setString(_userNameKey, session.user.fullName);
  }

  static Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_userNameKey);
  }
}
