import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';

class FavoritesException implements Exception {
  const FavoritesException(this.message, {this.requiresLogin = false});
  final String message;
  final bool requiresLogin;

  @override
  String toString() => message;
}

class FavoritesService {
  static const _legacyKey = 'favorite_product_ids';
  static const _timeout = Duration(seconds: 10);

  static Future<Set<String>> getIds() async {
    final token = await AuthSessionStore.getToken();
    if (token == null) {
      throw const FavoritesException('Autentifică-te pentru a vedea favoritele.', requiresLogin: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = (prefs.getStringList(_legacyKey) ?? const <String>[])
        .where((id) => RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id))
        .toSet()
        .toList();
    if (legacy.isNotEmpty) {
      Map<String, dynamic> imported = {};
      for (var index = 0; index < legacy.length; index += 200) {
        imported = await _request(
          'POST',
          '/favorites/import',
          token,
          body: {'productIds': legacy.skip(index).take(200).toList()},
        );
      }
      await prefs.remove(_legacyKey);
      return _ids(imported);
    }
    return _ids(await _request('GET', '/favorites', token));
  }

  static Future<bool> toggle(String productId) async {
    final ids = await getIds();
    final token = await AuthSessionStore.getToken();
    if (token == null) {
      throw const FavoritesException('Autentifică-te pentru a salva favorite.', requiresLogin: true);
    }
    final add = !ids.contains(productId);
    await _request(add ? 'PUT' : 'DELETE', '/favorites/$productId', token);
    return add;
  }

  static Set<String> _ids(Map<String, dynamic> data) =>
      (data['productIds'] is List ? data['productIds'] as List : const [])
          .whereType<String>()
          .toSet();

  static Future<Map<String, dynamic>> _request(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AuthApi.baseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final client = http.Client();
    try {
      final http.Response response;
      if (method == 'POST') {
        response = await client.post(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
      } else if (method == 'PUT') {
        response = await client.put(uri, headers: headers).timeout(_timeout);
      } else if (method == 'DELETE') {
        response = await client.delete(uri, headers: headers).timeout(_timeout);
      } else {
        response = await client.get(uri, headers: headers).timeout(_timeout);
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final raw = data['message'];
        final message = raw is List ? raw.join(' ') : raw?.toString();
        throw FavoritesException(
          message?.isNotEmpty == true ? message! : 'Nu am putut actualiza favoritele.',
          requiresLogin: response.statusCode == 401,
        );
      }
      return data;
    } finally {
      client.close();
    }
  }
}
