import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lend/services/maps_configuration.dart';
import 'package:lend/widgets/configured_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lend/maps');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> render(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfiguredMap(child: Text('Native map would mount')),
        ),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('missing iOS key prevents mounting the native map', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'isConfigured');
      return false;
    });
    await MapsConfiguration.initialize();
    await render(tester);
    expect(find.text('Native map would mount'), findsNothing);
    expect(find.text('Map is unavailable'), findsOneWidget);
  });

  testWidgets('configured iOS SDK allows mounting the map', (tester) async {
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    await MapsConfiguration.initialize();
    await render(tester);
    expect(find.text('Native map would mount'), findsOneWidget);
    expect(find.text('Map is unavailable'), findsNothing);
  });

  testWidgets('missing native channel fails safely', (tester) async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw MissingPluginException();
    });
    await MapsConfiguration.initialize();
    await render(tester);
    expect(find.text('Native map would mount'), findsNothing);
    expect(find.text('Map is unavailable'), findsOneWidget);
  });

  testWidgets('Android continues to mount maps without the iOS channel', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await MapsConfiguration.initialize();
    await render(tester);
    expect(find.text('Native map would mount'), findsOneWidget);
  });
}
