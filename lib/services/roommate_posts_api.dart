import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class RoommatePostsApi {
  RoommatePostsApi({http.Client? client}) : _client = client ?? http.Client();

  static const _requestTimeout = Duration(seconds: 8);

  final http.Client _client;

  Future<List<RoommatePost>> findAll() async {
    final response = await _client
        .get(Uri.parse('${AuthApi.baseUrl}/roommate-posts'))
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RoommatePostsApiException('Nu am putut incarca anunturile.');
    }

    if (payload is! List) {
      throw RoommatePostsApiException('Raspuns invalid pentru colegi.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(RoommatePost.fromJson)
        .toList();
  }

  Future<RoommatePost> create({
    required String accessToken,
    required RoommatePostInput input,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/roommate-posts'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(input.toJson()),
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RoommatePostsApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RoommatePostsApiException('Raspuns invalid pentru anunt.');
    }

    return RoommatePost.fromJson(payload);
  }

  Future<void> sendInterest({
    required String accessToken,
    required String postId,
    String? message,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/roommate-posts/$postId/interests'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (message != null && message.trim().isNotEmpty)
              'message': message.trim(),
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? payload;
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = null;
      }
      throw RoommatePostsApiException(_extractMessage(payload));
    }
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

    return 'A aparut o eroare. Incearca din nou.';
  }
}

class RoommatePostInput {
  const RoommatePostInput({
    this.productId,
    required this.title,
    required this.city,
    required this.area,
    required this.budgetPerMonth,
    required this.moveInDate,
    required this.description,
    required this.preferences,
  });

  final String? productId;
  final String title;
  final String city;
  final String area;
  final int budgetPerMonth;
  final String moveInDate;
  final String description;
  final List<String> preferences;

  Map<String, dynamic> toJson() {
    return {
      if (productId != null && productId!.isNotEmpty) 'productId': productId,
      'title': title,
      'city': city,
      'area': area,
      'budgetPerMonth': budgetPerMonth,
      'moveInDate': moveInDate,
      'description': description,
      'preferences': preferences,
    };
  }
}

class RoommatePost {
  const RoommatePost({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    required this.city,
    required this.area,
    required this.budgetPerMonth,
    required this.moveInDate,
    required this.description,
    required this.preferences,
    this.product,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String city;
  final String area;
  final int budgetPerMonth;
  final String moveInDate;
  final String description;
  final List<String> preferences;
  final RoommatePostProduct? product;

  String get budgetLabel => '$budgetPerMonth RON/luna';
  bool get hasProduct => product != null;

  factory RoommatePost.fromJson(Map<String, dynamic> json) {
    final productPayload = json['product'];
    final avatar = json['authorAvatarUrl'];

    return RoommatePost(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      authorAvatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
      title: (json['title'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      budgetPerMonth: _toInt(json['budgetPerMonth']),
      moveInDate: (json['moveInDate'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      preferences: (json['preferences'] is List)
          ? (json['preferences'] as List)
                .map((item) => item.toString())
                .toList()
          : const [],
      product: productPayload is Map<String, dynamic>
          ? RoommatePostProduct.fromJson(productPayload)
          : null,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class RoommatePostProduct {
  const RoommatePostProduct({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.pricePerMonth,
    required this.pricePerDay,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String city;
  final String address;
  final int? pricePerMonth;
  final int pricePerDay;
  final String imageUrl;

  String get priceLabel {
    if (pricePerMonth != null && pricePerMonth! > 0) {
      return '$pricePerMonth RON/luna';
    }

    return '$pricePerDay RON/zi';
  }

  factory RoommatePostProduct.fromJson(Map<String, dynamic> json) {
    return RoommatePostProduct(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      pricePerMonth: _toNullableInt(json['pricePerMonth']),
      pricePerDay: _toInt(json['pricePerDay']),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}

class RoommatePostsApiException implements Exception {
  RoommatePostsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
