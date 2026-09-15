import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../firebase_options.dart';
import '../widgets/lend_toast.dart';
import 'auth_api.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotifications with WidgetsBindingObserver {
  PushNotifications._();
  static final instance = PushNotifications._();
  final pendingMessage = ValueNotifier<RemoteMessage?>(null);
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final navigatorKey = GlobalKey<NavigatorState>();
  bool _ready = false;
  bool _syncing = false;
  bool _paused = false;
  Timer? _retry;
  int _attempts = 0;
  Future<void> _requests = Future.value();

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> initialize() async {
    if (!supported || _ready) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => pendingMessage.value = message,
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => unawaited(sync()),
      );
      FirebaseMessaging.onMessage.listen((message) {
        if (defaultTargetPlatform != TargetPlatform.android) return;
        final context = navigatorKey.currentState?.context;
        if (context == null) return;
        LendToast.info(
          // The listener runs synchronously when a foreground message arrives.
          // ignore: use_build_context_synchronously
          context,
          title: _titleFor(message),
          message: _bodyFor(message),
          actionLabel: 'Deschide',
          onAction: () => pendingMessage.value = message,
        );
      });
      pendingMessage.value = await FirebaseMessaging.instance
          .getInitialMessage();
      WidgetsBinding.instance.addObserver(this);
      _ready = true;
    } catch (error) {
      _logError('initialization', error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _attempts = 0;
      unawaited(sync());
    }
  }

  Future<void> sessionStarted() async {
    _paused = false;
    _attempts = 0;
    await initialize();
    await sync();
  }

  Future<void> sync() async {
    if (!_ready || _paused || _syncing) return;
    _syncing = true;
    try {
      final accessToken = await AuthSessionStore.getToken();
      if (accessToken == null || _paused) return;
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push permission: ${permission.authorizationStatus.name}');
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        debugPrint('Push: waiting for APNs token (attempt ${_attempts + 1})');
        _scheduleRetry();
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        _scheduleRetry();
        return;
      }
      await _enqueue(() async {
        if (_paused || await AuthSessionStore.getToken() != accessToken) return;
        await _request('POST', accessToken, token);
        debugPrint('Push: device registered with backend');
      });
      _attempts = 0;
    } catch (error) {
      _logError('registration', error);
      _scheduleRetry();
    } finally {
      _syncing = false;
    }
  }

  void _scheduleRetry() {
    if (_paused || _attempts >= 12) return;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: 3 * ++_attempts), () => unawaited(sync()));
  }

  void _logError(String operation, Object error) {
    // Include diagnostic codes, never credentials or registration tokens.
    final detail = error is FirebaseException
        ? '${error.plugin}/${error.code}'
        : error is StateError
        ? error.message
        : error.runtimeType.toString();
    debugPrint('Push $operation failed: $detail');
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _requests.then((_) => action());
    _requests = next.catchError((Object _) {});
    return next;
  }

  Future<void> signOut() async {
    _paused = true;
    _retry?.cancel();
    pendingMessage.value = null;
    if (!_ready) return;
    await _enqueue(() async {
      try {
        final accessToken = await AuthSessionStore.getToken();
        final token = await FirebaseMessaging.instance.getToken();
        if (accessToken != null && token != null) {
          await _request('DELETE', accessToken, token);
        }
      } catch (error) {
        debugPrint('Push unregister failed: ${error.runtimeType}');
      }
      try {
        // Invalidate delivery to the old account even if unregister failed.
        await FirebaseMessaging.instance.deleteToken().timeout(
          const Duration(seconds: 8),
        );
      } catch (error) {
        debugPrint('Push token deletion failed: ${error.runtimeType}');
      }
    });
  }

  Future<void> _request(String method, String accessToken, String token) async {
    final request =
        http.Request(method, Uri.parse('${AuthApi.baseUrl}/push/devices'))
          ..headers.addAll({
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({
            'token': token,
            if (method == 'POST')
              'platform': defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android',
          });
    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 8));
      await response.stream.drain<void>().timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Push HTTP ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  String _titleFor(RemoteMessage message) {
    if (message.notification?.title != null &&
        message.notification!.title!.isNotEmpty) {
      return message.notification!.title!;
    }

    return _isRentalNotification(message)
        ? 'Ai primit o închiriere nouă'
        : 'Mesaj nou';
  }

  String _bodyFor(RemoteMessage message) {
    if (message.notification?.body != null &&
        message.notification!.body!.isNotEmpty) {
      return message.notification!.body!;
    }

    return _isRentalNotification(message)
        ? 'Ai primit o solicitare nouă pentru unul dintre produsele tale.'
        : 'Ai primit un mesaj nou.';
  }

  bool _isRentalNotification(RemoteMessage message) {
    final type = message.data['type'];
    return type == 'rental_received' ||
        type == 'rental_request' ||
        type == 'rental_order_received';
  }
}
