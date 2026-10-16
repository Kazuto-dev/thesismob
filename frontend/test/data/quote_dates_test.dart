import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/checks.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  final today = DateTime(2026, 10, 15);
  final project = Project.create('Wall').copyWith(
    items: [
      Estimate(
        id: 'a',
        materialId: 'chb',
        label: 'CHB 4"',
        quantity: 100,
        unit: QuantityUnit.blocks,
        unitPrice: 25,
        total: 2500,
        createdAt: DateTime(2026, 10, 1),
        itemKey: 'chb_4',
      ),
    ],
  );

  String? oldPrices(Map<String, ({double price, DateTime date})> dated) {
    for (final c in checkProject(project, today: today, datedPrices: dated)) {
      if (c.title.startsWith('Some prices are')) return c.title;
    }
    return null;
  }

  test('a new estimate with no quote date has current prices', () {
    expect(oldPrices(const {}), isNull);
  });

  test('a line at a quoted price is as old as its quote', () {
    expect(
      oldPrices({'chb_4': (price: 25, date: DateTime(2026, 1, 10))}),
      'Some prices are 9 months old',
    );
  });

  test('a quote for a different price does not date the line', () {
    expect(
      oldPrices({'chb_4': (price: 27, date: DateTime(2026, 1, 10))}),
      isNull,
    );
  });
}
