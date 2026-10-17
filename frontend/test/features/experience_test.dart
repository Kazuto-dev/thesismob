import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/state/account_controller.dart';
import 'package:thesismob/state/appearance_controller.dart';

import '../helpers.dart';

void main() {
  testWidgets('the Homeowners Edition asks once and remembers', (tester) async {
    await pumpApp(tester);
    expect(find.text('Do you know construction?'), findsOneWidget);
    expect(find.text('Concrete Hollow Blocks'), findsOneWidget);

    await tester.tap(find.text("I'm new to this"));
    await tester.pumpAndSettle();
    expect(find.text('Do you know construction?'), findsNothing);
    expect(find.text('Build a block wall'), findsOneWidget);
    expect(find.text('Concrete Hollow Blocks'), findsNothing);
    expect(find.text('Build the house'), findsOneWidget);
    expect(find.text('Common jobs around the house'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.experienceKey), 'beginner');
  });

  testWidgets('experienced users keep the trade names', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('I know construction'));
    await tester.pumpAndSettle();
    expect(find.text('Do you know construction?'), findsNothing);
    expect(find.text('Concrete Hollow Blocks'), findsOneWidget);
    expect(find.text('Structural'), findsOneWidget);
  });

  testWidgets('a beginner sees the trade name in the calculator', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/category/structural/chb',
      prefs: {AppearanceController.experienceKey: 'beginner'},
    );
    expect(find.text('Build a block wall'), findsWidgets);
    expect(
      find.text('Builders and stores call this: Concrete Hollow Blocks'),
      findsOneWidget,
    );
  });

  testWidgets('beginners find calculators by everyday words', (tester) async {
    await pumpApp(
      tester,
      prefs: {AppearanceController.experienceKey: 'beginner'},
    );
    await tester.enterText(find.byType(TextField).first, 'septic');
    await tester.pump();
    expect(find.text('Put in a septic tank'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'sockets');
    await tester.pump();
    expect(find.text('Add wall sockets'), findsOneWidget);
  });

  testWidgets('Settings changes the answer', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      prefs: {AppearanceController.experienceKey: 'experienced'},
    );
    await tester.ensureVisible(find.text('Everyday words'));
    await tester.tap(find.text('Everyday words'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.experienceKey), 'beginner');
  });

  testWidgets('the Business Edition neither asks nor changes names', (
    tester,
  ) async {
    final me = jsonEncode({
      'user': {'id': '1', 'email': 'builder@example.com'},
      'plan': {
        'plan': 'business',
        'source': 'paid',
        'paidUntil': '2099-01-01T00:00:00Z',
      },
    });
    await pumpApp(
      tester,
      prefs: {
        AccountController.tokenKey: 'token',
        AccountController.meKey: me,
        AppearanceController.experienceKey: 'beginner',
      },
    );
    expect(find.text('Do you know construction?'), findsNothing);
    expect(find.text('Concrete Hollow Blocks'), findsOneWidget);
    expect(find.text('Build a block wall'), findsNothing);
  });
}
