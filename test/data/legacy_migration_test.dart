import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/legacy_migration.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  group('parseLegacyNumber', () {
    test('reads the formats the original app saved', () {
      expect(parseLegacyNumber('₱9375.0'), 9375);
      expect(parseLegacyNumber('9375.0₱'), 9375);
      expect(parseLegacyNumber('₱1,250.50'), 1250.5);
      expect(parseLegacyNumber('375pcs'), 375);
      expect(parseLegacyNumber('1.06Gal'), 1.06);
      expect(parseLegacyNumber('30.0sqm'), 30);
      expect(parseLegacyNumber('-187pcs'), -187);
      expect(parseLegacyNumber('₱1.5e+7'), 15000000);
      expect(parseLegacyNumber('₱1.249999975e+26'), 1.249999975e26);
    });

    test('returns null when there is no number', () {
      expect(parseLegacyNumber('₱'), isNull);
      expect(parseLegacyNumber(null), isNull);
      expect(parseLegacyNumber(double.nan), isNull);
    });
  });

  test('summary entry keeps its label and real totals', () {
    final e = estimateFromLegacySummary({
      'materialName': 'CHB 4"',
      'quantity': '375pcs',
      'totalamount': '₱9375.0',
    }, 0)!;
    expect(e.label, 'CHB 4"');
    expect(e.quantity, 375);
    expect(e.total, 9375);
    expect(e.unitPrice, 25);
    expect(e.materialId, Estimate.legacyMaterialId);
  });

  test('history entry keeps date, area and unit', () {
    final e = estimateFromLegacyHistory({
      'calculatorType': 'Paint Estimator',
      'material': 'Paint 2.0 coat',
      'area': '30.0sqm',
      'quantity': '1.98Gal',
      'date': '2024-02-05T10:00:00.000',
      'totalamount': '₱1600.0',
    }, 3)!;
    expect(e.area, 30);
    expect(e.unit, QuantityUnit.gallons);
    expect(e.createdAt, DateTime(2024, 2, 5, 10));
  });

  test('multi-line insulation labels become one line', () {
    final e = estimateFromLegacySummary({
      'materialName': 'Insulation\nnone\nThickness: 0.0(m)\nSize: 1.0(m)',
      'quantity': '2pcs',
      'totalamount': '₱1800.0',
    }, 0)!;
    expect(e.label, 'Insulation, Thickness: 0.0(m), Size: 1.0(m)');
  });

  test('entries without numbers are dropped', () {
    expect(
      estimateFromLegacySummary({
        'materialName': 'X',
        'quantity': 'pcs',
        'totalamount': '₱',
      }, 0),
      isNull,
    );
  });
}
