import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api.dart';

class ReviewsApi {
  ReviewsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<ProductReview>> findForProduct(String productId) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/reviews/product/$productId'),
    );
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw ReviewsApiException('Nu am putut încărca review-urile.');
    return (payload as List)
        .whereType<Map<String, dynamic>>()
        .map(ProductReview.fromJson)
        .toList();
  }

  Future<ProductReview> create({
    required String token,
    required String productId,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/reviews/product/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rentalOrderId': orderId,
        'rating': rating,
        'comment': comment,
      }),
    );
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReviewsApiException(
        payload is Map
            ? (payload['message'] ?? 'Review invalid.').toString()
            : 'Review invalid.',
      );
    }
    return ProductReview.fromJson(payload as Map<String, dynamic>);
  }
}

class ProductReview {
  const ProductReview({
    required this.id,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
  final String id;
  final String reviewerId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: (json['_id'] ?? json['id'] ?? '').toString(),
    reviewerId: (json['reviewerId'] ?? '').toString(),
    rating: json['rating'] is num ? (json['rating'] as num).toInt() : 0,
    comment: (json['comment'] ?? '').toString(),
    createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
  );
}

class ReviewsApiException implements Exception {
  ReviewsApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
