import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/export/project_sheets.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  final project = Project.create('Santos residence').copyWith(
    client: 'Maria Santos',
    costs: CostSettings.contractor,
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
        companions: const [
          EstimateLine(
            itemKey: 'cement_40kg',
            label: 'Cement',
            quantity: 28,
            unit: 'bags',
            unitPrice: 240,
          ),
        ],
      ),
    ],
  );
  final tabs = projectSheetTabs(project, date: DateTime(2026, 10, 15));

  test('four tabs with a frozen heading row', () {
    expect(tabs.map((t) => t.title), [
      'Bill of quantities',
      'Unit price analysis',
      'Materials',
      'Budget',
    ]);
    for (final t in tabs) {
      expect(t.rows.first, ['Santos residence']);
      expect(t.rows[1].single, contains('Client: Maria Santos'));
      expect(t.rows[1].single, contains('Date: 2026-10-15'));
      expect(t.rows[t.headerRow].first, isNot(isEmpty));
    }
    expect(projectSheetTitle(project), 'BuildQuantify – Santos residence');
  });

  test('the bill of quantities lists work at direct cost', () {
    final boq = tabs[0];
    expect(boq.rows[boq.headerRow], [
      'Item',
      'Description',
      'Quantity',
      'Unit',
      'Unit cost (₱)',
      'Amount (₱)',
    ]);
    expect(boq.rows[boq.headerRow + 1].take(2), ['A', 'STRUCTURAL WORKS']);
    // An estimate saved without its inputs: one line, labour at 40% of
    // its materials and tools at 10% of labour.
    const materials = 9850 + 28 * 240;
    const direct = materials * 1.4 + materials * 0.4 * 0.1;
    final line = boq.rows[boq.headerRow + 2];
    expect(line.take(4), ['A.1', 'CHB 4"', 394.0, 'blocks']);
    expect(line[5], closeTo(direct, 0.01));
    expect(boq.rows.last.last, project.breakdown.direct);
    expect(boq.boldRows, contains(boq.rows.length - 1));
    expect(boq.boldRows, contains(boq.headerRow + 1), reason: 'trade heading');
  });

  test('the unit price analysis builds up each line', () {
    final dupa = tabs[1];
    final rows = dupa.rows.skip(dupa.headerRow + 1).toList();
    expect(rows.first.take(2), ['A.1', 'CHB 4"']);
    expect(rows[1], ['', 'Materials', null, '', null, 16570.0]);
    expect(rows.map((r) => r[1]), contains('Direct cost'));
    expect(rows.map((r) => r[1]), contains('Unit price per blocks'));
  });

  test('materials and budget add up', () {
    final materials = tabs[2];
    expect(materials.rows.last.last, project.breakdown.materials);
    final budget = tabs[3];
    final total = budget.rows.firstWhere(
      (r) => r.isNotEmpty && r.first == 'Total contract price',
    );
    expect(total[1], project.breakdown.total);
    expect(budget.rows, contains(equals(['VAT', '12%'])));
  });
}
