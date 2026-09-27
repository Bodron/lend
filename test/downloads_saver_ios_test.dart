import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lend/services/downloads_saver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lend/downloads');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'opens the iOS Files picker and treats cancellation as no save',
    () async {
      MethodCall? receivedCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            receivedCall = call;
            return null;
          });

      final result = await DownloadsSaver.savePdf(
        name: 'contract.pdf',
        bytes: Uint8List.fromList([37, 80, 68, 70, 45]),
      );

      expect(result, isNull);
      expect(receivedCall?.method, 'savePdfWithPicker');
      expect(receivedCall?.arguments['name'], 'contract.pdf');
    },
  );
}
