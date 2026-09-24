import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

/// Socket.IO event names shared by the realtime features.
abstract final class RealtimeEvents {
  static const messageNew = 'message.new';
  static const offerUpdated = 'offer.updated';
  static const reviewCreated = 'review.created';
  static const reviewUpdated = 'review.updated';
  static const rentalOrderCreated = 'rental_order.created';
  static const rentalOrderUpdated = 'rental_order.updated';
  static const rentalOrderStatusChanged = 'rental_order.status_changed';
  static const availabilityChanged = 'availability.changed';
  static const reconnect = 'reconnect';

  static const rentalOrderEvents = [
    rentalOrderCreated,
    rentalOrderUpdated,
    rentalOrderStatusChanged,
    reconnect,
    // Compatibility names for older API deployments.
    'rental_order.new',
    'rental-order.created',
    'rental-order.new',
    'rental-order.updated',
    'rental-order.status_changed',
    'rental.created',
    'rental.new',
    'rental.updated',
    'rental.status_changed',
  ];

  static const reviewEvents = [reviewCreated, reviewUpdated];
}

/// Owns the single Socket.IO connection used by the authenticated session.
///
/// Screens subscribe to events and never create or dispose the underlying
/// connection themselves. This prevents duplicate connections when multiple
/// tabs are mounted in an IndexedStack.
class RealtimeSocketService {
  RealtimeSocketService._();

  static final instance = RealtimeSocketService._();

  socket_io.Socket? _socket;
  String? _accessToken;
  String? _apiBaseUrl;
  final Map<String, int> _availabilityRooms = {};

  Future<void>? _connecting;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({
    required String accessToken,
    required String apiBaseUrl,
  }) async {
    if (_socket != null &&
        _accessToken == accessToken &&
        _apiBaseUrl == apiBaseUrl) {
      return;
    }

    final inFlight = _connecting;
    if (inFlight != null) {
      await inFlight;
      if (_socket != null &&
          _accessToken == accessToken &&
          _apiBaseUrl == apiBaseUrl) {
        return;
      }
    }

    late final Future<void> future;
    future = _replaceConnection(
      accessToken: accessToken,
      apiBaseUrl: apiBaseUrl,
    );
    _connecting = future;
    try {
      await future;
    } finally {
      if (identical(_connecting, future)) {
        _connecting = null;
      }
    }
  }

  Future<RealtimeSubscription> subscribe({
    required String accessToken,
    required String apiBaseUrl,
    required String event,
    required void Function(dynamic data) onData,
  }) async {
    await connect(accessToken: accessToken, apiBaseUrl: apiBaseUrl);

    final socket = _socket;
    if (socket == null) {
      throw StateError('Realtime socket is not available.');
    }

    socket.on(event, onData);
    return RealtimeSubscription._(
      event: event,
      onData: onData,
      remove: () => socket.off(event, onData),
    );
  }

  Future<RealtimeSubscription> subscribeToEvents({
    required String accessToken,
    required String apiBaseUrl,
    required Iterable<String> events,
    required void Function(String event, dynamic data) onData,
  }) async {
    await connect(accessToken: accessToken, apiBaseUrl: apiBaseUrl);

    final socket = _socket;
    if (socket == null) {
      throw StateError('Realtime socket is not available.');
    }

    final subscriptions = <({String event, void Function(dynamic) handler})>[];
    for (final event in events) {
      void handler(dynamic data) => onData(event, data);
      socket.on(event, handler);
      subscriptions.add((event: event, handler: handler));
    }

    return RealtimeSubscription._(
      remove: () {
        for (final subscription in subscriptions) {
          socket.off(subscription.event, subscription.handler);
        }
      },
    );
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  void joinAvailability(String productId) {
    final count = _availabilityRooms[productId] ?? 0;
    _availabilityRooms[productId] = count + 1;
    if (count == 0 && isConnected) {
      emit('availability.join', {'productId': productId});
    }
  }

  void leaveAvailability(String productId) {
    final count = _availabilityRooms[productId] ?? 0;
    if (count <= 1) {
      _availabilityRooms.remove(productId);
      if (isConnected) emit('availability.leave', {'productId': productId});
    } else {
      _availabilityRooms[productId] = count - 1;
    }
  }

  Future<void> disconnect() async {
    final inFlight = _connecting;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {
        // A failed connection should not prevent signing out.
      }
    }

    _disconnectSocket();
    _availabilityRooms.clear();
  }

  void _disconnectSocket() {
    final socket = _socket;
    _socket = null;
    _accessToken = null;
    _apiBaseUrl = null;
    socket?.disconnect();
    socket?.dispose();
  }

  Future<void> _replaceConnection({
    required String accessToken,
    required String apiBaseUrl,
  }) async {
    _disconnectSocket();

    final serverUrl = apiBaseUrl.replaceFirst(RegExp(r'/api$'), '');
    final socket = socket_io.io(
      serverUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket = socket;
    _accessToken = accessToken;
    _apiBaseUrl = apiBaseUrl;
    socket.onConnect((_) {
      for (final productId in _availabilityRooms.keys) {
        socket.emit('availability.join', {'productId': productId});
      }
    });
    socket.connect();
  }
}

class RealtimeSubscription {
  RealtimeSubscription._({this.event, this.onData, required this.remove});

  final String? event;
  final void Function(dynamic)? onData;
  final void Function() remove;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    remove();
  }
}
