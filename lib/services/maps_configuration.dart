import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MapsConfiguration {
  static bool get requiresNativeCheck =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool _iosConfigured = false;
  static bool get available => !requiresNativeCheck || _iosConfigured;

  static Future<void> initialize() async {
    if (!requiresNativeCheck) return;
    try {
      _iosConfigured =
          await const MethodChannel(
            'lend/maps',
          ).invokeMethod<bool>('isConfigured') ??
          false;
    } on PlatformException {
      _iosConfigured = false;
    } on MissingPluginException {
      _iosConfigured = false;
    }
    if (!_iosConfigured) {
      debugPrint(
        'Maps disabled: configure GOOGLE_MAPS_IOS_API_KEY and rebuild.',
      );
    }
  }
}
