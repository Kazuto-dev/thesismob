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

  test('three tabs with a frozen heading row', () {
    expect(tabs.map((t) => t.title), [
      'Bill of quantities',
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

  test('the bill of quantities ends with the materials total in bold', () {
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
    expect(boq.rows[boq.headerRow + 2][1], 'CHB 4"');
    expect(boq.rows[boq.headerRow + 3][1], '    Cement');
    expect(boq.rows.last.last, 9850 + 28 * 240);
    expect(boq.boldRows, contains(boq.rows.length - 1));
    expect(boq.boldRows, contains(boq.headerRow + 1), reason: 'trade heading');
  });

  test('materials and budget add up', () {
    final materials = tabs[1];
    expect(materials.rows.last.last, project.breakdown.materials);
    final budget = tabs[2];
    final total = budget.rows.firstWhere(
      (r) => r.isNotEmpty && r.first == 'Total contract price',
    );
    expect(total[1], project.breakdown.total);
    expect(budget.rows, contains(equals(['VAT', '12%'])));
  });
}
