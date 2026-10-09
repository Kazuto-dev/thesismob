import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/estimate_repository.dart';
import 'package:thesismob/data/sheet_settings.dart';
import 'package:thesismob/materials/material_spec.dart';

Estimate sample(String id, {double total = 100}) => Estimate(
  id: id,
  materialId: 'chb',
  label: 'CHB 4"',
  area: 30,
  quantity: 4,
  unit: QuantityUnit.blocks,
  unitPrice: total / 4,
  total: total,
  createdAt: DateTime(2026, 10, 9, 8),
  inputs: const {'length': 10, 'height': 3, 'price': 25},
  choices: const {'size': '4', 'contingency': 'none'},
);

Future<EstimateRepository> repo(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return EstimateRepository(await SharedPreferences.getInstance());
}

void main() {
  test('round-trips estimates', () async {
    final r = await repo({});
    await r.saveSummary([sample('a'), sample('b', total: 9375)]);
    final loaded = r.loadSummary();
    expect(loaded.map((e) => e.id), ['a', 'b']);
    expect(loaded.last.total, 9375);
    expect(loaded.first.inputs, {'length': 10, 'height': 3, 'price': 25});
    expect(loaded.first.choices['size'], '4');
    expect(loaded.first.unit, QuantityUnit.blocks);
  });

  test('imports the original app data once and keeps the old keys', () async {
    final legacy = jsonEncode([
      {
        'materialName': 'CHB Default',
        'quantity': '375pcs',
        'totalamount': '₱9375.0',
      },
      {
        'materialName': 'Tiles',
        'quantity': '223pcs',
        'totalamount': '₱1,003.50',
      },
    ]);
    final r = await repo({EstimateRepository.legacySummaryKey: legacy});
    final migrated = r.loadSummary();
    expect(migrated.map((e) => e.total), [9375, 1003.5]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(EstimateRepository.summaryKey), isNotNull);
    expect(prefs.getString(EstimateRepository.legacySummaryKey), legacy);

    // Later loads read the new key, so deleting an item sticks.
    await r.saveSummary(migrated.take(1).toList());
    expect(r.loadSummary(), hasLength(1));
  });

  test('skips corrupted entries instead of losing the list', () async {
    final r = await repo({
      EstimateRepository.summaryKey: jsonEncode([
        sample('ok').toJson(),
        {'id': 'broken', 'total': 'a lot'},
        'not even a map',
      ]),
    });
    expect(r.loadSummary().map((e) => e.id), ['ok']);
  });

  test('unreadable JSON is treated as empty', () async {
    final r = await repo({EstimateRepository.historyKey: '{nope'});
    expect(r.loadHistory(), isEmpty);
  });

  group('SheetSettingsRepository', () {
    test('reads settings saved by the original app', () async {
      SharedPreferences.setMockInitialValues({
        'sheetInfo': jsonEncode({'sheetId': 'abc', 'sheetName': 'Sheet1'}),
      });
      final s = SheetSettingsRepository(await SharedPreferences.getInstance())
          .load()!;
      expect(s.spreadsheetId, 'abc');
      expect(s.sheetName, 'Sheet1');
    });

    test('saves in the same shape and can clear', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final r = SheetSettingsRepository(prefs);
      await r.save(const SheetSettings(spreadsheetId: 'id', sheetName: 'Tab'));
      expect(jsonDecode(prefs.getString('sheetInfo')!), {
        'sheetId': 'id',
        'sheetName': 'Tab',
      });
      await r.clear();
      expect(r.load(), isNull);
    });
  });
}
