import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class CategoriesApi {
  CategoriesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LendCategory>> findAll() async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/categories'),
    );
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CategoriesApiException('Nu am putut incarca categoriile.');
    }

    if (payload is! List) {
      throw CategoriesApiException('Raspuns invalid pentru categorii.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LendCategory.fromJson)
        .toList();
  }
}

class CategoriesApiException implements Exception {
  CategoriesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LendCategory {
  const LendCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.iconName,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String iconName;
  final int sortOrder;

  factory LendCategory.fromJson(Map<String, dynamic> json) {
    return LendCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      iconName: (json['iconName'] ?? '').toString(),
      sortOrder: _toInt(json['sortOrder']),
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
