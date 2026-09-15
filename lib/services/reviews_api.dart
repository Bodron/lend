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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReviewsApiException('Nu am putut încărca review-urile.');
    }
    return (payload as List)
        .whereType<Map<String, dynamic>>()
        .map(ProductReview.fromJson)
        .toList();
  }

  Future<ProductReview> create({
    required String token,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/reviews/product/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
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

  Future<ReviewEligibility> findEligibility({
    required String token,
    required String productId,
  }) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/reviews/product/$productId/eligibility'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReviewsApiException(
        'Nu am putut verifica eligibilitatea review-ului.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw ReviewsApiException(
        'Raspuns invalid pentru eligibilitatea review-ului.',
      );
    }
    return ReviewEligibility.fromJson(payload);
  }
}

class ReviewEligibility {
  const ReviewEligibility({
    required this.canReview,
    required this.rentalOrderId,
    required this.message,
  });

  final bool canReview;
  final String? rentalOrderId;
  final String? message;

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    final rawOrderId = json['rentalOrderId']?.toString();
    final rawMessage = json['message']?.toString();
    return ReviewEligibility(
      canReview: json['canReview'] == true,
      rentalOrderId: rawOrderId?.isEmpty == true ? null : rawOrderId,
      message: rawMessage?.isEmpty == true ? null : rawMessage,
    );
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
