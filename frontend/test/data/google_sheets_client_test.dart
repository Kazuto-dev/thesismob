import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/google_sheets_client.dart';

import '../google_fake.dart';

SheetTab tab(String title, List<List<Object?>> rows) => (
  title: title,
  rows: rows,
  headerRow: 0,
  moneyColumns: const [1],
  quantityColumns: const <int>[],
  boldRows: const [2],
);

void main() {
  late FakeGoogleApi api;
  late GoogleSheetsClient client;

  setUp(() {
    api = FakeGoogleApi();
    client = GoogleSheetsClient(client: api.client);
  });

  test('reads who the user is', () async {
    final account = await client.userInfo('t');
    expect(account.email, 'maria@example.com');
    expect(account.name, 'Maria Santos');
    expect(account.displayName, 'Maria Santos');
  });

  test('creates a spreadsheet with its tabs, values and formats', () async {
    final sheet = await client.create('t', 'BuildQuantify – House', [
      tab("Bill of 'quantities'", [
        ['Item', 'Amount'],
        ['Blocks', 9850.0, null],
      ]),
      tab('Budget', [
        ['Total', 1],
      ]),
    ]);
    expect(sheet.id, 'sheet1');
    expect(sheet.url, 'https://docs.google.com/spreadsheets/d/sheet1/edit');
    expect(api.calls, [
      'POST /v4/spreadsheets',
      'POST /v4/spreadsheets/sheet1/values:batchUpdate',
      'POST /v4/spreadsheets/sheet1:batchUpdate',
    ]);
    final created = api.bodies('/v4/spreadsheets').first;
    expect(created['properties'], {'title': 'BuildQuantify – House'});

    final values = api.bodies('values:batchUpdate').single;
    expect(values['valueInputOption'], 'RAW');
    final data = values['data'] as List;
    // Quotes in tab names are doubled in A1 ranges; nulls become blanks.
    expect(data.first['range'], "'Bill of ''quantities'''!A1");
    expect(data.first['values'][1], ['Blocks', 9850.0, '']);

    final formats = api.bodies(':batchUpdate').last['requests'] as List;
    expect(
      formats.where((r) => (r as Map).containsKey('autoResizeDimensions')),
      hasLength(2),
    );
    final frozen = formats.firstWhere(
      (r) => (r as Map).containsKey('updateSheetProperties'),
    );
    expect(frozen['updateSheetProperties']['properties']['gridProperties'], {
      'frozenRowCount': 1,
    });
  });

  test('updating clears the tabs and puts back a deleted one', () async {
    final first = await client.create('t', 'House', [
      tab('Bill of quantities', [
        ['a'],
      ]),
    ]);
    api.requests.clear();
    final again = await client.update('t', first.id, [
      tab('Bill of quantities', [
        ['b'],
      ]),
      tab('Budget', [
        ['c'],
      ]),
    ]);
    expect(again.id, first.id);
    expect(api.calls, [
      'GET /v4/spreadsheets/sheet1',
      'POST /v4/spreadsheets/sheet1:batchUpdate',
      'POST /v4/spreadsheets/sheet1/values:batchClear',
      'POST /v4/spreadsheets/sheet1/values:batchUpdate',
      'POST /v4/spreadsheets/sheet1:batchUpdate',
    ]);
    expect(api.spreadsheets['sheet1'], ['Bill of quantities', 'Budget']);
    expect(api.bodies('values:batchClear').single['ranges'], [
      "'Bill of quantities'",
      "'Budget'",
    ]);
  });

  test('Google errors become failures the app can explain', () async {
    Future<GoogleSheetsFailure> failure(
      int status, [
      String body = '{}',
    ]) async {
      api
        ..failNext = status
        ..failBody = body;
      try {
        await client.userInfo('t');
      } on GoogleSheetsException catch (e) {
        return e.failure;
      }
      fail('no exception');
    }

    expect(await failure(401), GoogleSheetsFailure.unauthorized);
    expect(
      await failure(
        403,
        '{"error":{"status":"PERMISSION_DENIED","details":'
        '[{"reason":"SERVICE_DISABLED"}]}}',
      ),
      GoogleSheetsFailure.apiDisabled,
    );
    expect(await failure(403), GoogleSheetsFailure.forbidden);
    expect(await failure(404), GoogleSheetsFailure.notFound);
    expect(await failure(429), GoogleSheetsFailure.rateLimited);
    expect(await failure(500), GoogleSheetsFailure.failed);
  });

  test('a missing spreadsheet is reported as not found', () async {
    expect(
      () => client.update('t', 'gone', [
        tab('Budget', [
          ['x'],
        ]),
      ]),
      throwsA(
        isA<GoogleSheetsException>().having(
          (e) => e.failure,
          'failure',
          GoogleSheetsFailure.notFound,
        ),
      ),
    );
  });

  test('keeps one backup file in Drive', () async {
    expect(await client.findBackup('t'), isNull);
    final created = await client.saveBackup('t', '{"version":1}');
    expect(api.driveFiles[created.id], '{"version":1}');
    expect(created.modified, DateTime.utc(2026, 10, 15, 8));
    final created1 = api.requests.last;
    expect(created1.url.queryParameters['uploadType'], 'multipart');
    expect(created1.body, contains('"name":"BuildQuantify backup.json"'));

    final found = await client.findBackup('t');
    expect(found?.id, created.id);
    expect(
      api.requests.last.url.queryParameters['q'],
      "name = 'BuildQuantify backup.json' and trashed = false",
    );

    await client.saveBackup('t', '{"version":2}', id: created.id);
    expect(api.requests.last.method, 'PATCH');
    expect(api.driveFiles, hasLength(1));
    expect(await client.readBackup('t', created.id), '{"version":2}');
  });
}
