import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/data/google_auth.dart';
import 'package:thesismob/data/google_sheets_client.dart';
import 'package:thesismob/state/google_account_controller.dart';

import '../google_fake.dart';
import '../helpers.dart';

void main() {
  GoogleSheetsClient sheets() =>
      GoogleSheetsClient(client: FakeGoogleApi().client);

  testWidgets('without Google set up, the app opens straight away', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Welcome'), findsNothing);
    expect(find.text('Categories'), findsOneWidget);
  });

  testWidgets('first launch asks to sign in; continuing skips it for good', (
    tester,
  ) async {
    await pumpApp(tester, googleAuth: FakeGoogleAuth(), sheetsClient: sheets());
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'full screen');

    await tester.ensureVisible(find.text('Continue without signing in'));
    await tester.tap(find.text('Continue without signing in'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);

    // Next visit: the choice is remembered.
    await pumpApp(
      tester,
      googleAuth: FakeGoogleAuth(),
      sheetsClient: sheets(),
      prefs: {GoogleAccountController.skippedKey: true},
    );
    expect(find.text('Welcome'), findsNothing);
  });

  testWidgets('signing in goes on to the page that was asked for', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/category/structural/chb',
      googleAuth: FakeGoogleAuth(),
      sheetsClient: sheets(),
    );
    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Concrete Hollow Blocks'), findsWidgets);
    expect(projectsOf(tester), isNotNull);
  });

  testWidgets('a failed sign-in explains itself and stays put', (tester) async {
    await pumpApp(
      tester,
      googleAuth: FakeGoogleAuth(failure: GoogleAuthFailure.unavailable),
      sheetsClient: sheets(),
    );
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't reach Google"), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('signing out returns to the login screen', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      googleAuth: FakeGoogleAuth(),
      sheetsClient: sheets(),
      prefs: {
        GoogleAccountController.key:
            '{"email":"maria@example.com","name":"Maria Santos"}',
      },
    );
    expect(find.text('Maria Santos'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('desktops show the introduction beside the sign-in', (
    tester,
  ) async {
    await pumpApp(
      tester,
      size: desktop,
      googleAuth: FakeGoogleAuth(),
      sheetsClient: sheets(),
    );
    expect(
      find.text('Estimate every material.\nPrice every job.'),
      findsOneWidget,
    );
    expect(find.text('Welcome'), findsOneWidget);
  });
}
