import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/google_auth.dart';
import 'package:thesismob/data/google_sheets_client.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/google_account_controller.dart';

import '../google_fake.dart';
import '../helpers.dart';

final project = Project.create('Santos residence').copyWith(
  items: [
    Estimate(
      id: 'e1',
      materialId: 'chb',
      label: 'CHB 4"',
      quantity: 394,
      unit: QuantityUnit.blocks,
      unitPrice: 25,
      total: 9850,
      createdAt: DateTime(2026, 10, 9),
      itemKey: 'chb_4',
    ),
  ],
);

void main() {
  late FakeGoogleAuth auth;
  late FakeGoogleApi api;
  late SharedPreferences prefs;

  var now = DateTime(2026, 10, 15, 9);

  Future<GoogleAccountController> setup([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    auth = FakeGoogleAuth();
    api = FakeGoogleApi();
    now = DateTime(2026, 10, 15, 9);
    return GoogleAccountController(
      prefs,
      auth,
      GoogleSheetsClient(client: api.client),
      clock: () => now,
    );
  }

  test('signing in remembers the account, signing out forgets it', () async {
    final c = await setup();
    expect(c.isSignedIn, isFalse);
    final result = await c.signIn();
    expect(result.ok, isTrue);
    expect(result.message, 'Signed in as maria@example.com.');
    expect(c.account!.name, 'Maria Santos');
    expect(
      jsonDecode(prefs.getString(GoogleAccountController.key)!)['email'],
      'maria@example.com',
    );

    await c.signOut();
    expect(c.isSignedIn, isFalse);
    expect(prefs.getString(GoogleAccountController.key), isNull);
    expect(auth.signedOut, isTrue);
  });

  test('the account is remembered between visits', () async {
    final c = await setup({
      GoogleAccountController.key: jsonEncode({
        'email': 'jo@example.com',
        'name': 'Jo',
      }),
    });
    expect(c.account, const GoogleAccount(email: 'jo@example.com', name: 'Jo'));
  });

  test('saving creates a spreadsheet, then updates the same one', () async {
    final c = await setup();
    final first = await c.saveProject(project);
    expect(first.ok, isTrue);
    expect(first.sheet!.id, 'sheet1');
    expect(first.message, contains('BuildQuantify – Santos residence'));
    expect(c.isSignedIn, isTrue, reason: 'saving signs the user in');
    expect(api.spreadsheets['sheet1'], [
      'Bill of quantities',
      'Materials',
      'Budget',
    ]);

    api.requests.clear();
    final second = await c.saveProject(project.copyWith(sheetId: 'sheet1'));
    expect(second.sheet!.id, 'sheet1');
    expect(api.calls.first, 'GET /v4/spreadsheets/sheet1');
    expect(api.spreadsheets, hasLength(1));
  });

  test('a deleted spreadsheet is made again', () async {
    final c = await setup();
    final result = await c.saveProject(project.copyWith(sheetId: 'gone'));
    expect(result.ok, isTrue);
    expect(result.sheet!.id, 'sheet1');
  });

  test('problems come back as messages, not errors', () async {
    final c = await setup();
    auth.failure = GoogleAuthFailure.cancelled;
    expect(
      (await c.saveProject(project)).message,
      'Google sign-in was cancelled.',
    );
    expect(c.isBusy, isFalse);

    auth.failure = null;
    await c.signIn();
    api
      ..failNext = 403
      ..failBody = '{"error":{"details":[{"reason":"SERVICE_DISABLED"}]}}';
    final disabled = await c.saveProject(project);
    expect(disabled.ok, isFalse);
    expect(disabled.message, contains('Sheets API'));

    api.failNext = 401;
    final expired = await c.saveProject(project);
    expect(expired.message, contains('expired'));
    expect(auth.forgotten, isNotEmpty, reason: 'the bad token is dropped');
  });

  test('a build without a client ID says so', () async {
    SharedPreferences.setMockInitialValues({});
    final c = GoogleAccountController(
      await SharedPreferences.getInstance(),
      FakeGoogleAuth(configured: false),
      GoogleSheetsClient(client: FakeGoogleApi().client),
    );
    expect(c.isConfigured, isFalse);
    expect((await c.signIn()).message, contains("isn't set up"));
  });

  test('backs up to Drive and restores from it', () async {
    final c = await setup();
    final none = await c.fetchBackup();
    expect(none.content, isNull);
    expect(none.result.message, contains('no BuildQuantify backup'));

    final saved = await c.backUp('{"version":1}');
    expect(saved.ok, isTrue);
    expect(c.lastBackup, DateTime.utc(2026, 10, 15, 8));
    expect(api.driveFiles.values, ['{"version":1}']);

    // The same file is updated, and remembered across visits.
    final again = GoogleAccountController(
      prefs,
      auth,
      GoogleSheetsClient(client: api.client),
    );
    await again.backUp('{"version":2}');
    expect(api.driveFiles.values, ['{"version":2}']);
    expect((await again.fetchBackup()).content, '{"version":2}');
  });

  test('automatic backups reuse a recent sign-in and never ask', () async {
    final c = await setup();
    await c.autoBackUp('{"a":1}');
    expect(api.driveFiles, isEmpty, reason: 'off until turned on');

    c.setAutoBackup(true);
    await c.autoBackUp('{"a":1}');
    expect(api.driveFiles, isEmpty, reason: 'no token yet');

    await c.signIn();
    final asked = auth.authorizations;
    await c.autoBackUp('{"a":2}');
    expect(api.driveFiles.values, ['{"a":2}']);
    expect(auth.authorizations, asked, reason: 'no Google window');

    now = now.add(const Duration(hours: 1));
    await c.autoBackUp('{"a":3}');
    expect(api.driveFiles.values, ['{"a":2}'], reason: 'the token expired');

    await c.signOut();
    expect(c.autoBackup, isFalse);
    expect(c.lastBackup, isNull);
  });
}
