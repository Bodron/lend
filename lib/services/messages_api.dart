import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'auth_api.dart';

class MessagesApi {
  MessagesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  socket_io.Socket connectSocket(String accessToken) {
    final serverUrl = AuthApi.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return socket_io.io(
      serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    )..connect();
  }

  Future<List<MessageThreadSummary>> findThreads(String accessToken) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/messages'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MessagesApiException(_message(payload));
    }
    return (payload as List)
        .whereType<Map<String, dynamic>>()
        .map(MessageThreadSummary.fromJson)
        .toList();
  }

  Future<MessageThread> getForProduct({
    required String accessToken,
    required String productId,
  }) async {
    final response = await _client.get(
      Uri.parse('${AuthApi.baseUrl}/messages/product/$productId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _decodeThread(response);
  }

  Future<Message> send({
    required String accessToken,
    required String productId,
    required String body,
  }) async {
    final response = await _client.post(
      Uri.parse('${AuthApi.baseUrl}/messages'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'productId': productId, 'body': body}),
    );
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MessagesApiException(_message(payload));
    }
    return Message.fromJson(payload as Map<String, dynamic>);
  }

  MessageThread _decodeThread(http.Response response) {
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MessagesApiException(_message(payload));
    }
    return MessageThread.fromJson(payload as Map<String, dynamic>);
  }

  String _message(Object? payload) {
    if (payload is Map<String, dynamic> && payload['message'] is String) {
      return payload['message'] as String;
    }
    return 'Nu am putut încărca mesajele.';
  }
}

class MessageThread {
  const MessageThread({
    required this.productId,
    required this.productTitle,
    required this.ownerName,
    required this.messages,
  });

  final String productId;
  final String productTitle;
  final String ownerName;
  final List<Message> messages;

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return MessageThread(
      productId: (json['productId'] ?? '').toString(),
      productTitle: (json['productTitle'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map<String, dynamic>>()
                .map(Message.fromJson)
                .toList()
          : const [],
    );
  }
}

class MessageThreadSummary {
  const MessageThreadSummary({
    required this.productId,
    required this.productTitle,
    required this.ownerName,
    required this.latestMessage,
    required this.unreadCount,
  });

  final String productId;
  final String productTitle;
  final String ownerName;
  final String latestMessage;
  final int unreadCount;

  factory MessageThreadSummary.fromJson(Map<String, dynamic> json) {
    final latest = json['latestMessage'];
    return MessageThreadSummary(
      productId: (json['productId'] ?? '').toString(),
      productTitle: (json['productTitle'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
      latestMessage: latest is Map<String, dynamic>
          ? (latest['body'] ?? '').toString()
          : '',
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
    );
  }
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime? createdAt;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class MessagesApiException implements Exception {
  MessagesApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
