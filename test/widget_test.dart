import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lend/main.dart';
import 'package:lend/screens/explore_screen.dart';
import 'package:lend/screens/login_screen.dart';
import 'package:lend/screens/main_shell.dart';

void main() {
  testWidgets('guests can explore and protected navigation opens login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LendApp());
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(tester.widget<MainShell>(find.byType(MainShell)).isGuest, isTrue);

    for (final icon in [
      Icons.list_alt_rounded,
      Icons.handshake_outlined,
      Icons.person_outline_rounded,
      Icons.add_rounded,
    ]) {
      await tester.tap(find.byIcon(icon).last);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
    }
  });
}
