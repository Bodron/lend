import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lend/main.dart';
import 'package:lend/l10n/generated_localizations.dart';
import 'package:lend/screens/home_screen.dart';
import 'package:lend/screens/register_screen.dart';

void main() {
  testWidgets('opens register screen from home screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LendApp());
    await tester.pumpAndSettle();

    final strings = GeneratedLocalizations.of(
      tester.element(find.byType(HomeScreen)),
    )!;
    expect(find.text(strings.heroTitle), findsOneWidget);
    expect(find.text(strings.startNow), findsOneWidget);

    await tester.tap(find.text(strings.startNow));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
