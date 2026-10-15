import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/catalog.dart';

void main() {
  // Runs on the VM and in Chrome (CI): ids once used 1 << 32, which is 0
  // in JavaScript and made Random.nextInt throw on the web.
  test('fromResult creates unique ids and keeps the inputs', () {
    final spec = materialById('chb')!;
    final result = spec.calculate(const {
      'length': 10,
      'height': 3,
      'price': 25,
    }, spec.initialChoices);
    final ids = {
      for (var i = 0; i < 50; i++)
        Estimate.fromResult(
          materialId: spec.id,
          result: result,
          inputs: const {'length': 10},
          choices: const {},
        ).id,
    };
    expect(ids, hasLength(50));

    final e = Estimate.fromResult(
      materialId: spec.id,
      result: result,
      inputs: const {'length': 10, 'height': 3, 'price': 25},
      choices: spec.initialChoices,
    );
    // 375 blocks plus the default 5% waste.
    expect(e.total, 9850);
    expect(e.withId('x').sameCalculationAs(e), isTrue);
    expect(Estimate.fromJson(e.toJson()).sameCalculationAs(e), isTrue);
  });

  test('companions are priced and added to the grand total', () {
    final spec = materialById('chb')!;
    final result = spec.calculate(const {
      'length': 10,
      'height': 3,
      'price': 25,
    }, spec.initialChoices);
    final prices = {'cement_40kg': 250.0, 'sand': 1600.0};
    final e = Estimate.fromResult(
      materialId: spec.id,
      result: result,
      inputs: const {'length': 10, 'height': 3, 'price': 25},
      choices: spec.initialChoices,
      priceOf: (key) => prices[key] ?? 0,
    );
    expect(e.itemKey, 'chb_4');
    final cement = e.companions.firstWhere((l) => l.itemKey == 'cement_40kg');
    expect(cement.quantity, 28);
    expect(cement.unit, 'bags');
    expect(cement.total, 7000);
    // Sand 2.5 m³ × 1,600; bars and tie wire have no price here.
    expect(e.companionsTotal, 7000 + 4000);
    expect(e.grandTotal, 9850 + 11000);

    expect(e.toSheetRows().first, ['CHB 4"', 394.0, 'blocks', 25.0, 9850.0]);
    expect(e.toSheetRows()[1], [
      '  Cement for laying and plaster',
      28.0,
      'bags',
      250.0,
      7000.0,
    ]);

    final back = Estimate.fromJson(e.toJson());
    expect(back.companions, hasLength(e.companions.length));
    expect(back.grandTotal, e.grandTotal);
    expect(back.itemKey, 'chb_4');

    final repriced = e.copyWith(unitPrice: 30);
    expect(repriced.total, 394 * 30);
    expect(repriced.companions, e.companions);
  });

  test('entries saved before companions were priced still load', () {
    final e = Estimate.fromJson({
      'id': 'old',
      'materialId': 'chb',
      'label': 'CHB 4"',
      'quantity': 394,
      'unit': 'blocks',
      'unitPrice': 25,
      'total': 9850,
      'createdAt': '2026-10-01T09:00:00.000',
    });
    expect(e.companions, isEmpty);
    expect(e.itemKey, isNull);
    expect(e.grandTotal, 9850);
  });

  test('a mark and a note are saved and shown in the title', () {
    final e = Estimate(
      id: 'e1',
      materialId: 'footing',
      label: 'Footing 1.2 × 1.2 m',
      quantity: 1,
      unit: QuantityUnit.cubicMetres,
      unitPrice: 0,
      total: 0,
      createdAt: DateTime(2026, 10, 9),
    ).copyWith(mark: 'F1', note: 'Four of these');
    expect(e.title, 'F1 – Footing 1.2 × 1.2 m');
    final back = Estimate.fromJson(e.toJson());
    expect(back.mark, 'F1');
    expect(back.note, 'Four of these');
    expect(back.toSheetRows().first.first, 'F1 – Footing 1.2 × 1.2 m');
    expect(back.copyWith(mark: '').title, 'Footing 1.2 × 1.2 m');
    expect(back.copyWith(unitPrice: 5).mark, 'F1', reason: 'kept');
  });
}
