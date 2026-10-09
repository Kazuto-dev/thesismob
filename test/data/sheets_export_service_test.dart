import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:thesismob/data/sheets_export_service.dart';

const _id = '1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789';

SheetsExportService _service(int status, {String body = '{}'}) =>
    SheetsExportService(
      endpoint: 'https://proxy.example/append',
      client: MockClient((_) async => http.Response(body, status)),
    );

void main() {
  group('normalizeSpreadsheetId', () {
    test('accepts a bare ID', () {
      expect(SheetsExportService.normalizeSpreadsheetId(' $_id '), _id);
    });

    test('extracts the ID from a sheet URL', () {
      expect(
        SheetsExportService.normalizeSpreadsheetId(
          'https://docs.google.com/spreadsheets/d/$_id/edit#gid=0',
        ),
        _id,
      );
    });

    test('rejects text that is not an ID', () {
      expect(SheetsExportService.normalizeSpreadsheetId('not a real id'), null);
      expect(SheetsExportService.normalizeSpreadsheetId(''), null);
    });
  });

  group('appendRows', () {
    test('reports notConfigured without an endpoint', () async {
      final result = await SheetsExportService(endpoint: '').appendRows(
        spreadsheetId: _id,
        sheetName: 'Sheet1',
        rows: [
          ['CHB', 30, 375, 9375],
        ],
      );
      expect(result.status, SheetsExportStatus.notConfigured);
    });

    test('asks for sheet details when they are missing', () async {
      final result = await _service(200).appendRows(
        spreadsheetId: 'nope',
        sheetName: '',
        rows: [
          ['CHB', 30, 375, 9375],
        ],
      );
      expect(result.status, SheetsExportStatus.missingSheetInfo);
    });

    test('posts the header and rows as JSON', () async {
      late Map<String, dynamic> sent;
      final service = SheetsExportService(
        endpoint: 'https://proxy.example/append',
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"ok":true}', 200);
        }),
      );
      final result = await service.appendRows(
        spreadsheetId: _id,
        sheetName: ' Sheet1 ',
        rows: [
          ['CHB', 30, 375, 9375],
        ],
      );
      expect(result.isSuccess, isTrue);
      expect(sent['spreadsheetId'], _id);
      expect(sent['sheetName'], 'Sheet1');
      expect(sent['header'], SheetsExportService.header);
      expect(sent['rows'], [
        ['CHB', 30, 375, 9375],
      ]);
    });

    test('maps proxy errors to user-facing statuses', () async {
      final rows = [
        ['CHB', 30, 375, 9375],
      ];
      Future<SheetsExportStatus> statusFor(int code) async => (await _service(
        code,
      ).appendRows(spreadsheetId: _id, sheetName: 'Sheet1', rows: rows)).status;

      expect(await statusFor(403), SheetsExportStatus.permissionDenied);
      expect(await statusFor(404), SheetsExportStatus.notFound);
      expect(await statusFor(400), SheetsExportStatus.invalidInput);
      expect(await statusFor(500), SheetsExportStatus.server);
    });

    test('reports network failures', () async {
      final service = SheetsExportService(
        endpoint: 'https://proxy.example/append',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final result = await service.appendRows(
        spreadsheetId: _id,
        sheetName: 'Sheet1',
        rows: [
          ['CHB', 30, 375, 9375],
        ],
      );
      expect(result.status, SheetsExportStatus.network);
    });
  });
}
