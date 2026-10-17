import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/data/api_client.dart';
import 'package:thesismob/state/account_controller.dart';

import '../data/sample_house.dart';
import '../fake_server.dart';
import '../helpers.dart';

void main() {
  final later = DateTime.now().toUtc().add(const Duration(days: 30));

  /// Opens [location] on a server, signed in to [server]'s account unless
  /// [signedIn] is false.
  Future<void> open(
    WidgetTester tester,
    FakeServer server, {
    String location = '/project',
    bool signedIn = true,
  }) => pumpApp(
    tester,
    location: location,
    size: const Size(400, 1400),
    apiClient: ApiClient(baseUrl: 'https://api.test', client: server.client),
    prefs: {
      ...projectPrefs(sampleHouse().items),
      if (signedIn) ...{
        AccountController.tokenKey: 'session-1',
        AccountController.meKey: jsonEncode(server.me),
      },
    },
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the free plan locks the contract and points to the plans', (
    tester,
  ) async {
    await open(tester, FakeServer(), signedIn: false);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);

    await tap(tester, find.text('Contract'));
    expect(find.text('Contract is for Business Edition'), findsOneWidget);
    expect(find.text('Your plan: Homeowners Edition'), findsOneWidget);
    await tap(tester, find.text('Not now'));
    expect(find.textContaining('Critical phases: '), findsNothing);

    await tap(tester, find.text('Contract'));
    await tap(tester, find.text('See plans'));
    expect(find.text('Compare plans'), findsOneWidget);
  });

  testWidgets('the free trial unlocks Business features from the lock', (
    tester,
  ) async {
    await open(tester, FakeServer());
    await tap(tester, find.text('Contract'));
    await tap(tester, find.text('Start 14-day free trial'));
    expect(find.text('Your Business trial has started.'), findsOneWidget);

    await tap(tester, find.text('Contract'));
    expect(find.text('Contract is for Business Edition'), findsNothing);
    expect(find.textContaining('Critical phases: '), findsOneWidget);
  });

  testWidgets('Business locks the company, which asks about Enterprise', (
    tester,
  ) async {
    final server = FakeServer()
      ..plan = 'business'
      ..source = 'paid'
      ..paidUntil = later.toIso8601String();
    await open(tester, server, location: '/settings');
    await tap(tester, find.text('Team members'));
    expect(find.text('Team members is for Enterprise Edition'), findsOneWidget);
    expect(find.text('Your plan: Business Edition'), findsOneWidget);
    await tap(tester, find.text('Ask about Enterprise').last);
    expect(find.text('How many people will use it?'), findsOneWidget);
  });

  testWidgets('Enterprise opens the team with roles and invitations', (
    tester,
  ) async {
    final server = FakeServer()
      ..plan = 'enterprise'
      ..source = 'organization'
      ..paidUntil = later.toIso8601String()
      ..organization = {
        'id': 'o1',
        'name': 'Reyes Builders',
        'role': 'owner',
        'seats': 5,
      };
    await open(tester, server, location: '/settings');
    expect(find.text('Reyes Builders, as owner.'), findsOneWidget);
    await tap(tester, find.text('Team members'));
    expect(find.text('2 of 5 seats used'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('jose@example.com'), findsOneWidget);
    expect(find.text('estimator'), findsOneWidget);
  });
}
