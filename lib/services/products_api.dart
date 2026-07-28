import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';
import 'storage_api.dart';

class ProductsApi {
  ProductsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LendProduct>> findAll() async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/products'),
    );
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductsApiException('Nu am putut incarca produsele.');
    }

    if (payload is! List) {
      throw ProductsApiException('Raspuns invalid pentru produse.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LendProduct.fromJson)
        .toList();
  }

  Future<List<LendProduct>> findMine(String accessToken) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/products/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductsApiException('Nu am putut incarca anunturile tale.');
    }

    if (payload is! List) {
      throw ProductsApiException('Raspuns invalid pentru anunturile tale.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(LendProduct.fromJson)
        .toList();
  }

  Future<LendProduct> create({
    required String accessToken,
    required ProductSaveInput input,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/products'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    return _decodeProductResponse(response, 'Nu am putut publica anuntul.');
  }

  Future<LendProduct> update({
    required String accessToken,
    required String productId,
    required ProductSaveInput input,
  }) async {
    final response = await _client.patch(
      Uri.parse('${AuthApi.baseUrl}/products/$productId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    return _decodeProductResponse(response, 'Nu am putut salva modificarile.');
  }

  LendProduct _decodeProductResponse(http.Response response, String fallback) {
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductsApiException(_extractMessage(payload, fallback));
    }

    if (payload is! Map<String, dynamic>) {
      throw ProductsApiException('Raspuns invalid pentru produs.');
    }

    return LendProduct.fromJson(payload);
  }

  String _extractMessage(Object? payload, String fallback) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];

      if (message is List && message.isNotEmpty) {
        return message.join('\n');
      }

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}

class ProductSaveInput {
  const ProductSaveInput({
    required this.title,
    required this.category,
    required this.categorySlug,
    required this.description,
    required this.pricePerDay,
    required this.deposit,
    required this.city,
    required this.media,
  });

  final String title;
  final String category;
  final String categorySlug;
  final String description;
  final int pricePerDay;
  final int deposit;
  final String city;
  final List<UploadedMedia> media;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'categorySlug': categorySlug,
      'description': description,
      'pricePerDay': pricePerDay,
      'deposit': deposit,
      'city': city,
      'media': media.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductsApiException implements Exception {
  ProductsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LendProduct {
  const LendProduct({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.categorySlug,
    required this.description,
    required this.pricePerDay,
    required this.deposit,
    required this.city,
    required this.ownerName,
    required this.rating,
    required this.isAvailable,
    required this.images,
  });

  final String id;
  final String slug;
  final String title;
  final String category;
  final String categorySlug;
  final String description;
  final int pricePerDay;
  final int deposit;
  final String city;
  final String ownerName;
  final double rating;
  final bool isAvailable;
  final List<LendProductImage> images;

  LendProductImage? get primaryMedia {
    for (final image in images) {
      if (!image.isVideo) {
        return image;
      }
    }

    return images.isEmpty ? null : images.first;
  }

  String get imageUrl {
    return primaryMedia?.url ?? '';
  }

  String get priceLabel => '$pricePerDay lei';
  String get pricePerDayLabel => '$pricePerDay lei/zi';
  String get ratingLabel => rating.toStringAsFixed(1);

  factory LendProduct.fromJson(Map<String, dynamic> json) {
    final imagesPayload = json['images'];

    return LendProduct(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      categorySlug: (json['categorySlug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      pricePerDay: _toInt(json['pricePerDay']),
      deposit: _toInt(json['deposit']),
      city: (json['city'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      isAvailable: json['isAvailable'] != false,
      images: imagesPayload is List
          ? imagesPayload
                .whereType<Map<String, dynamic>>()
                .map(LendProductImage.fromJson)
                .toList()
          : const [],
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

  static double _toDouble(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LendProductImage {
  const LendProductImage({
    required this.url,
    required this.key,
    required this.alt,
    required this.contentType,
    required this.type,
  });

  final String url;
  final String key;
  final String alt;
  final String contentType;
  final String type;

  bool get isVideo {
    final normalizedType = type.toLowerCase();
    final normalizedContentType = contentType.toLowerCase();
    final normalizedUrl = url.toLowerCase();
    final uri = Uri.tryParse(normalizedUrl);
    final path = uri?.path.toLowerCase() ?? normalizedUrl;

    return normalizedType == 'video' ||
        normalizedContentType.startsWith('video/') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm');
  }

  factory LendProductImage.fromJson(Map<String, dynamic> json) {
    final document = json['_doc'];
    final source = document is Map<String, dynamic> ? document : json;

    return LendProductImage(
      url: (json['url'] ?? source['url'] ?? '').toString(),
      key: (json['key'] ?? source['key'] ?? '').toString(),
      alt: (json['alt'] ?? source['alt'] ?? '').toString(),
      contentType: (json['contentType'] ?? source['contentType'] ?? '')
          .toString(),
      type: (json['type'] ?? source['type'] ?? 'image').toString(),
    );
  }
}
