import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rental_mode.dart';
import 'auth_api.dart';

class RentalOrdersApi {
  RentalOrdersApi({http.Client? client}) : _client = client ?? http.Client();

  static const _requestTimeout = Duration(seconds: 8);

  final http.Client _client;

  Future<RentalOrder> create({
    required String accessToken,
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    required RentalMode rentalMode,
    int? negotiatedSubtotal,
    required String pickupTime,
    required String returnTime,
    double? renterLatitude,
    double? renterLongitude,
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      'startDate': _dateKey(startDate),
      'endDate': _dateKey(endDate),
      'rentalMode': rentalMode == RentalMode.hour
          ? 'hour'
          : rentalMode == RentalMode.month
          ? 'month'
          : 'day',
      'pickupTime': pickupTime,
      'returnTime': returnTime,
    };
    if (negotiatedSubtotal != null) {
      body['negotiatedSubtotal'] = negotiatedSubtotal;
    }
    if (renterLatitude != null) body['renterLatitude'] = renterLatitude;
    if (renterLongitude != null) body['renterLongitude'] = renterLongitude;

    final response = await _client
        .post(
          Uri.parse('${AuthApi.baseUrl}/rental-orders'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru comanda.');
    }

    return RentalOrder.fromJson(payload);
  }

  Future<List<RentalOrder>> findMine(String accessToken) async {
    final response = await _client
        .get(
          Uri.parse('${AuthApi.baseUrl}/rental-orders/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! List) {
      throw RentalOrdersApiException('Raspuns invalid pentru inchirieri.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(RentalOrder.fromJson)
        .toList();
  }

  Future<List<RentalOrder>> findOwned(String accessToken) async {
    final response = await _client
        .get(
          Uri.parse('${AuthApi.baseUrl}/rental-orders/owned'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! List) {
      throw RentalOrdersApiException('Raspuns invalid pentru inchirieri.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(RentalOrder.fromJson)
        .toList();
  }

  Future<RentalOrder> updateStatus({
    required String accessToken,
    required String orderId,
    required String status,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${AuthApi.baseUrl}/rental-orders/$orderId/status'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': status}),
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru retur.');
    }

    return RentalOrder.fromJson(payload);
  }

  Future<RentalOrder> updateSchedule({
    required String accessToken,
    required String orderId,
    required String pickupTime,
    required String returnTime,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${AuthApi.baseUrl}/rental-orders/$orderId/schedule'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'pickupTime': pickupTime,
            'returnTime': returnTime,
          }),
        )
        .timeout(_requestTimeout);

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru program.');
    }

    return RentalOrder.fromJson(payload);
  }

  Future<RentalOrder> markPaymentAuthorized({
    required String accessToken,
    required String orderId,
  }) async {
    return _patchOrder(
      accessToken: accessToken,
      path: '/rental-orders/$orderId/payment-authorized',
      fallback: 'Nu am putut confirma plata.',
    );
  }

  Future<RentalOrder> markRenterReady({
    required String accessToken,
    required String orderId,
  }) async {
    return _patchOrder(
      accessToken: accessToken,
      path: '/rental-orders/$orderId/renter-ready',
      fallback: 'Nu am putut trimite cererea proprietarului.',
    );
  }

  Future<RentalOrder> attachSignedContract({
    required String accessToken,
    required String orderId,
    required String key,
    required String url,
    String contentType = 'application/pdf',
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${AuthApi.baseUrl}/rental-orders/$orderId/contract'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'key': key,
            'url': url,
            'contentType': contentType,
          }),
        )
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru contract.');
    }

    return RentalOrder.fromJson(payload);
  }

  Future<RentalOrder> accept({
    required String accessToken,
    required String orderId,
  }) async {
    return _patchOrder(
      accessToken: accessToken,
      path: '/rental-orders/$orderId/accept',
      fallback: 'Nu am putut accepta cererea.',
    );
  }

  Future<RentalOrder> reject({
    required String accessToken,
    required String orderId,
  }) async {
    return _patchOrder(
      accessToken: accessToken,
      path: '/rental-orders/$orderId/reject',
      fallback: 'Nu am putut refuza cererea.',
    );
  }

  Future<RentalOrder> completeReturn({
    required String accessToken,
    required String orderId,
  }) {
    return updateStatus(
      accessToken: accessToken,
      orderId: orderId,
      status: 'completed',
    );
  }

  Future<RentalOrder> _patchOrder({
    required String accessToken,
    required String path,
    required String fallback,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${AuthApi.baseUrl}$path'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException(fallback);
    }

    return RentalOrder.fromJson(payload);
  }

  Future<ProductAvailability> getAvailability({
    required String productId,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse(
      '${AuthApi.baseUrl}/rental-orders/products/$productId/availability',
    ).replace(queryParameters: {'from': _dateKey(from), 'to': _dateKey(to)});
    final response = await _client.get(uri).timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru disponibilitate.');
    }

    return ProductAvailability.fromJson(payload);
  }

  Future<AvailabilityBlock> createAvailabilityBlock({
    required String accessToken,
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    String reason = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '${AuthApi.baseUrl}/rental-orders/products/$productId/availability-blocks',
          ),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'startDate': _dateKey(startDate),
            'endDate': _dateKey(endDate),
            if (reason.trim().isNotEmpty) 'reason': reason.trim(),
          }),
        )
        .timeout(_requestTimeout);
    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw RentalOrdersApiException('Raspuns invalid pentru blocaj.');
    }

    return AvailabilityBlock.fromJson(payload);
  }

  Future<void> deleteAvailabilityBlock({
    required String accessToken,
    required String blockId,
  }) async {
    final response = await _client
        .delete(
          Uri.parse(
            '${AuthApi.baseUrl}/rental-orders/availability-blocks/$blockId',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_requestTimeout);
    final payload = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RentalOrdersApiException(_extractMessage(payload));
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

    return 'Nu am putut crea comanda. Incearca din nou.';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class ProductAvailability {
  const ProductAvailability({
    required this.productId,
    required this.from,
    required this.to,
    required this.unavailableDates,
    required this.reservations,
    required this.manualBlocks,
  });

  final String productId;
  final DateTime? from;
  final DateTime? to;
  final Set<String> unavailableDates;
  final List<AvailabilityReservation> reservations;
  final List<AvailabilityBlock> manualBlocks;

  factory ProductAvailability.fromJson(Map<String, dynamic> json) {
    final unavailable = json['unavailableDates'];
    final reservations = json['reservations'];
    final blocks = json['manualBlocks'];

    return ProductAvailability(
      productId: (json['productId'] ?? '').toString(),
      from: DateTime.tryParse((json['from'] ?? '').toString()),
      to: DateTime.tryParse((json['to'] ?? '').toString()),
      unavailableDates: unavailable is List
          ? unavailable.map((value) => value.toString()).toSet()
          : const {},
      reservations: reservations is List
          ? reservations
                .whereType<Map<String, dynamic>>()
                .map(AvailabilityReservation.fromJson)
                .toList()
          : const [],
      manualBlocks: blocks is List
          ? blocks
                .whereType<Map<String, dynamic>>()
                .map(AvailabilityBlock.fromJson)
                .toList()
          : const [],
    );
  }
}

class AvailabilityReservation {
  const AvailabilityReservation({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.returnTime,
    required this.status,
    this.occupiedFrom,
    this.occupiedUntil,
  });

  final String id;
  final DateTime? startDate;
  final DateTime? endDate;
  final String pickupTime;
  final String returnTime;
  final String status;
  final DateTime? occupiedFrom;
  final DateTime? occupiedUntil;

  factory AvailabilityReservation.fromJson(Map<String, dynamic> json) {
    return AvailabilityReservation(
      id: (json['id'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
      pickupTime: (json['pickupTime'] ?? '00:00').toString(),
      returnTime: (json['returnTime'] ?? '24:00').toString(),
      status: (json['status'] ?? '').toString(),
      occupiedFrom: DateTime.tryParse((json['occupiedFrom'] ?? '').toString()),
      occupiedUntil: DateTime.tryParse(
        (json['occupiedUntil'] ?? '').toString(),
      ),
    );
  }
}

class AvailabilityBlock {
  const AvailabilityBlock({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  final String id;
  final DateTime? startDate;
  final DateTime? endDate;
  final String reason;

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) {
    return AvailabilityBlock(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class RentalOrder {
  const RentalOrder({
    required this.id,
    required this.productId,
    required this.status,
    required this.productTitle,
    required this.productOwnerName,
    required this.productImageUrl,
    required this.productImageContentType,
    required this.productImageType,
    required this.renterName,
    required this.renterEmail,
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.returnTime,
    required this.rentalMode,
    required this.rentalHours,
    required this.paymentStatus,
    required this.renterVerifiedAt,
    required this.ownerVerifiedAt,
    required this.paymentClientSecret,
    required this.payoutStatus,
    required this.payoutEligibleAt,
    required this.rentalDays,
    required this.subtotal,
    required this.ownerEarnings,
    required this.serviceFee,
    required this.deposit,
    required this.total,
    this.contractPdfUrl,
    this.contractSignedAt,
  });

  final String id;
  final String productId;
  final String status;
  final String productTitle;
  final String productOwnerName;
  final String productImageUrl;
  final String productImageContentType;
  final String productImageType;
  final String renterName;
  final String renterEmail;
  final DateTime? startDate;
  final DateTime? endDate;
  final String pickupTime;
  final String returnTime;
  final String rentalMode;
  final int rentalHours;
  final String paymentStatus;
  final DateTime? renterVerifiedAt;
  final DateTime? ownerVerifiedAt;
  final String paymentClientSecret;
  final String payoutStatus;
  final DateTime? payoutEligibleAt;
  final int rentalDays;
  final int subtotal;
  final int ownerEarnings;
  final int serviceFee;
  final int deposit;
  final int total;
  final String? contractPdfUrl;
  final DateTime? contractSignedAt;

  bool isPayoutEligible(DateTime now) {
    if (status != 'completed' || paymentStatus != 'captured') {
      return false;
    }

    if (payoutStatus == 'eligible') {
      return true;
    }

    if (payoutStatus != 'held_until_return') {
      return false;
    }

    final eligibleAt = payoutEligibleAt;
    return eligibleAt != null && !eligibleAt.isAfter(now);
  }

  factory RentalOrder.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productSnapshot'];
    final productSnapshot = snapshot is Map<String, dynamic>
        ? snapshot
        : const <String, dynamic>{};
    final renterPayload = json['renter'];
    final renter = renterPayload is Map<String, dynamic>
        ? renterPayload
        : const <String, dynamic>{};

    return RentalOrder(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      productTitle: (productSnapshot['title'] ?? '').toString(),
      productOwnerName: (productSnapshot['ownerName'] ?? '').toString(),
      productImageUrl: (productSnapshot['imageUrl'] ?? '').toString(),
      productImageContentType: (productSnapshot['imageContentType'] ?? '')
          .toString(),
      productImageType: (productSnapshot['imageType'] ?? '').toString(),
      renterName: (renter['fullName'] ?? '').toString(),
      renterEmail: (renter['email'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      endDate: DateTime.tryParse((json['endDate'] ?? '').toString()),
      pickupTime: (json['pickupTime'] ?? '10:00').toString(),
      returnTime: (json['returnTime'] ?? '18:00').toString(),
      rentalMode: (json['rentalMode'] ?? 'day').toString(),
      rentalHours: _toInt(json['rentalHours']),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      renterVerifiedAt: DateTime.tryParse(
        (json['renterVerifiedAt'] ?? '').toString(),
      ),
      ownerVerifiedAt: DateTime.tryParse(
        (json['ownerVerifiedAt'] ?? '').toString(),
      ),
      paymentClientSecret: (json['stripePaymentClientSecret'] ?? '').toString(),
      payoutStatus: (json['payoutStatus'] ?? '').toString(),
      payoutEligibleAt: DateTime.tryParse(
        (json['payoutEligibleAt'] ?? '').toString(),
      ),
      rentalDays: _toInt(json['rentalDays']),
      subtotal: _toInt(json['subtotal']),
      ownerEarnings: _toInt(json['ownerEarnings']),
      serviceFee: _toInt(json['serviceFee']),
      deposit: _toInt(json['deposit']),
      total: _toInt(json['total']),
      contractPdfUrl: _optionalString(json['contractPdfUrl']),
      contractSignedAt: DateTime.tryParse(
        (json['contractSignedAt'] ?? '').toString(),
      ),
    );
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
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

class RentalOrdersApiException implements Exception {
  RentalOrdersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
