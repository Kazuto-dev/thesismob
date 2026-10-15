import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/sheet_settings.dart';
import 'package:thesismob/data/sheets_export_service.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/sheet_settings_controller.dart';

const _id = '1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789';

final _estimate = Estimate(
  id: 'a',
  materialId: 'chb',
  label: 'CHB 4"',
  area: 30,
  quantity: 375,
  unit: QuantityUnit.blocks,
  unitPrice: 25,
  total: 9375,
  createdAt: DateTime(2026, 10, 9),
);

Future<SheetSettingsController> controller(SheetsExportService exporter) async {
  SharedPreferences.setMockInitialValues({});
  return SheetSettingsController(
    SheetSettingsRepository(await SharedPreferences.getInstance()),
    exporter,
  );
}

void main() {
  test('accepts a sheet link and stores just the ID', () async {
    final c = await controller(SheetsExportService(endpoint: ''));
    final error = c.save(
      spreadsheet: 'https://docs.google.com/spreadsheets/d/$_id/edit#gid=0',
      sheetName: ' Estimates ',
    );
    expect(error, isNull);
    expect(c.settings!.spreadsheetId, _id);
    expect(c.settings!.sheetName, 'Estimates');
  });

  test('rejects input that is not a spreadsheet', () async {
    final c = await controller(SheetsExportService(endpoint: ''));
    expect(c.save(spreadsheet: 'not a real id', sheetName: 'x'), isNotNull);
    expect(c.save(spreadsheet: _id, sheetName: '  '), isNotNull);
    expect(c.settings, isNull);
  });

  test(
    'export sends each estimate as item, quantity, unit, cost and amount',
    () async {
      late Map<String, dynamic> body;
      final c = await controller(
        SheetsExportService(
          endpoint: 'https://proxy.example',
          client: MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response('{"ok":true}', 200);
          }),
        ),
      );
      c.save(spreadsheet: _id, sheetName: 'Sheet1');
      final result = await c.export([_estimate]);
      expect(result.isSuccess, isTrue);
      expect(body['rows'], [
        ['CHB 4"', 375, 'blocks', 25, 9375],
      ]);
      expect(body['header'], SheetsExportService.header);
      expect(c.isExporting, isFalse);
    },
  );

  test('export explains what is missing', () async {
    final unconfigured = await controller(SheetsExportService(endpoint: ''));
    expect(
      (await unconfigured.export([_estimate])).status,
      SheetsExportStatus.notConfigured,
    );

    final noSheet = await controller(
      SheetsExportService(endpoint: 'https://proxy.example'),
    );
    expect(
      (await noSheet.export([_estimate])).status,
      SheetsExportStatus.missingSheetInfo,
    );
  });
}
