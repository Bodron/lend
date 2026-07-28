import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

class StorageApi {
  StorageApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<UploadedMedia> uploadMedia({
    required String accessToken,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
    required String alt,
  }) async {
    final upload = await _createUploadUrl(
      accessToken: accessToken,
      fileName: fileName,
      contentType: contentType,
      size: bytes.length,
    );

    final uploadResponse = await _client.put(
      Uri.parse(upload.uploadUrl),
      headers: upload.headers,
      body: bytes,
    );

    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw StorageApiException(
        'Nu am putut urca fisierul in AWS S3 (${uploadResponse.statusCode}).',
      );
    }

    return UploadedMedia(
      key: upload.key,
      url: upload.readableUrl,
      alt: alt,
      contentType: contentType,
      type: upload.mediaType,
    );
  }

  Future<_PresignedUpload> _createUploadUrl({
    required String accessToken,
    required String fileName,
    required String contentType,
    required int size,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/storage/uploads'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fileName': fileName,
        'contentType': contentType,
        'size': size,
      }),
    );

    final payload = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StorageApiException(_extractMessage(payload));
    }

    if (payload is! Map<String, dynamic>) {
      throw StorageApiException('Raspuns invalid pentru upload.');
    }

    return _PresignedUpload.fromJson(payload);
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

    return 'Nu am putut pregati upload-ul.';
  }
}

class UploadedMedia {
  const UploadedMedia({
    required this.key,
    required this.url,
    required this.alt,
    required this.contentType,
    required this.type,
  });

  final String key;
  final String url;
  final String alt;
  final String contentType;
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'url': url,
      'alt': alt,
      'contentType': contentType,
      'type': type,
    };
  }
}

class _PresignedUpload {
  const _PresignedUpload({
    required this.key,
    required this.uploadUrl,
    required this.readableUrl,
    required this.contentType,
    required this.mediaType,
    required this.headers,
  });

  final String key;
  final String uploadUrl;
  final String readableUrl;
  final String contentType;
  final String mediaType;
  final Map<String, String> headers;

  factory _PresignedUpload.fromJson(Map<String, dynamic> json) {
    final headersPayload = json['headers'];

    return _PresignedUpload(
      key: (json['key'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? '').toString(),
      readableUrl: (json['readableUrl'] ?? '').toString(),
      contentType: (json['contentType'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? '').toString(),
      headers: headersPayload is Map<String, dynamic>
          ? headersPayload.map((key, value) => MapEntry(key, value.toString()))
          : const {},
    );
  }
}

class StorageApiException implements Exception {
  StorageApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
