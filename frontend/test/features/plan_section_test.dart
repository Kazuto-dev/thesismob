import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/data/api_client.dart';
import 'package:thesismob/data/google_sheets_client.dart';
import 'package:thesismob/state/google_account_controller.dart';

import '../fake_server.dart';
import '../google_fake.dart';
import '../helpers.dart';

void main() {
  Future<FakeServer> open(
    WidgetTester tester, {
    Size size = const Size(400, 1400),
  }) async {
    final server = FakeServer();
    await pumpApp(
      tester,
      location: '/settings',
      size: size,
      googleAuth: FakeGoogleAuth(),
      sheetsClient: GoogleSheetsClient(client: FakeGoogleApi().client),
      apiClient: ApiClient(baseUrl: 'https://api.test', client: server.client),
      prefs: {GoogleAccountController.skippedKey: true},
    );
    return server;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the plan card signs in, starts the trial and takes a code', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Homeowners Edition'), findsOneWidget);

    await tap(tester, 'Sign in to your account');
    expect(find.text('Signed in as maria@example.com'), findsOneWidget);
    expect(
      find.text('2 projects in the cloud. Try Business free for 14 days.'),
      findsOneWidget,
    );

    await tap(tester, 'Start 14-day free trial');
    expect(find.text('Business Edition'), findsOneWidget);
    expect(find.text('Free trial: 14 days left.'), findsOneWidget);

    await tap(tester, 'Enter a code');
    await tester.enterText(
      find.byType(TextField).last,
      'BQ-0000-0000-0000-0000',
    );
    await tap(tester, 'Use code');
    expect(
      find.text('That code is not valid. Check it against the email we sent.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byType(TextField).last,
      'BQ-AAAA-BBBB-CCCC-DDDD',
    );
    await tap(tester, 'Use code');
    expect(find.textContaining('Paid until'), findsOneWidget);

    await tap(tester, 'Sign out of your account');
    expect(find.text('Homeowners Edition'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  for (final (label, size, sideBySide) in [
    ('a phone', const Size(400, 1400), false),
    ('a wide screen', const Size(1440, 900), true),
  ]) {
    testWidgets('plans are cards, side by side only on $label', (tester) async {
      await open(tester, size: size);
      await tap(tester, 'Compare plans');
      Offset at(String name) => tester.getTopLeft(
        find.descendant(of: find.byType(Dialog), matching: find.text(name)),
      );
      final free = at('Homeowners Edition');
      final business = at('Business Edition');
      final enterprise = at('Enterprise Edition');
      if (sideBySide) {
        // The free card is the user's, so its label pushes its name down.
        expect((business.dy - free.dy).abs(), lessThan(40));
        expect(enterprise.dy, business.dy);
        expect(business.dx, greaterThan(free.dx));
        expect(enterprise.dx, greaterThan(business.dx));
      } else {
        expect(business.dx, free.dx);
        expect(business.dy, greaterThan(free.dy));
        expect(enterprise.dy, greaterThan(business.dy));
      }
      expect(find.text('Your plan'), findsOneWidget);
    });
  }

  testWidgets('plans are compared with peso prices, and Enterprise is asked '
      'about', (tester) async {
    final server = await open(tester);
    await tap(tester, 'Compare plans');
    expect(find.text('\$20 (₱1,150) a month'), findsOneWidget);
    expect(find.text('Up to 2 projects'), findsOneWidget);
    await tap(tester, 'Close');

    await tap(tester, 'Ask about Enterprise');
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Ana Reyes');
    await tester.enterText(fields.at(1), 'ana@reyesbuilders.ph');
    await tester.enterText(fields.at(2), 'Reyes Builders');
    await tester.enterText(fields.at(3), '8');
    await tap(tester, 'Send');
    expect(server.inquiries.single['company'], 'Reyes Builders');
    expect(server.inquiries.single['seats'], 8);
    expect(
      find.text('Thank you. We will reply by email within a working day.'),
      findsOneWidget,
    );
  });

  testWidgets('without a server address there is no plan card', (tester) async {
    await pumpApp(tester, location: '/settings');
    expect(find.text('Compare plans'), findsNothing);
  });

  testWidgets('Backup and restore says where the data is, and saves it to '
      'the account', (tester) async {
    final server = await open(tester);
    expect(find.textContaining('only in this browser for now'), findsOneWidget);

    await tap(tester, 'Save to your account');
    expect(
      find.textContaining('saved to your account, maria@example.com'),
      findsOneWidget,
    );
    expect(find.textContaining('Saved to your account'), findsOneWidget);
    expect(server.calls, contains('GET /v1/projects'));
  });

  testWidgets('signing in on the welcome screen signs in to the account too', (
    tester,
  ) async {
    final server = FakeServer();
    await pumpApp(
      tester,
      googleAuth: FakeGoogleAuth(),
      sheetsClient: GoogleSheetsClient(client: FakeGoogleApi().client),
      apiClient: ApiClient(baseUrl: 'https://api.test', client: server.client),
    );
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(server.calls, contains('POST /v1/auth/google'));
    expect(server.calls, contains('GET /v1/projects'));
  });
}
