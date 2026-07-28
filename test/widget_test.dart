import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lend/main.dart';
import 'package:lend/screens/register_screen.dart';

void main() {
  testWidgets('opens register screen from home screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LendApp());
    await tester.pumpAndSettle();

    expect(find.text('Imprumuta. Ofera. Simplu.'), findsOneWidget);
    expect(find.text('Incepe acum'), findsOneWidget);

    await tester.tap(find.text('Incepe acum'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
