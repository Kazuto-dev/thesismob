import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/export/project_documents.dart';
import 'package:thesismob/export/project_pdf.dart';
import 'package:thesismob/materials/material_spec.dart';

Estimate item(String materialId, String label, double total) => Estimate(
  id: '$materialId-$total',
  materialId: materialId,
  label: label,
  quantity: 10,
  unit: QuantityUnit.pieces,
  unitPrice: total / 10,
  total: total,
  createdAt: DateTime(2026, 10, 9),
  itemKey: '${materialId}_key',
  companions: const [
    EstimateLine(
      itemKey: 'cement_40kg',
      label: 'Portland cement, 40 kg',
      quantity: 5,
      unit: 'bags',
      unitPrice: 240,
    ),
  ],
);

final project = Project.create('Santos residence, "phase 1"').copyWith(
  client: 'Maria Santos',
  location: 'Antipolo',
  costs: CostSettings.contractor,
  items: [
    item('chb', 'CHB 4"', 9850),
    item('bulb', 'LED bulb', 1150),
    item('paint', 'Latex paint', 2880),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bill of quantities follows trade order with subtotals', () {
    final rows = boqRows(project);
    final headings = [
      for (final r in rows)
        if (r.isHeading) '${r.number} ${r.description}',
    ];
    expect(headings, [
      'A STRUCTURAL WORKS',
      'B ARCHITECTURAL WORKS',
      'C ELECTRICAL WORKS',
    ]);
    expect(rows[1].number, 'A.1');
    expect(rows[1].amount, 9850);
    expect(rows[2].description, 'Portland cement, 40 kg');
    expect(rows[2].amount, 1200);
    expect(rows[3].isSubtotal, isTrue);
    expect(rows[3].amount, 11050);
  });

  test('the cost summary ends with the contract price', () {
    final lines = costLines(project);
    expect(lines.first.$1, 'Materials');
    expect(lines.last.$1, 'Total contract price');
    expect(lines.last.$2, project.breakdown.total);
    expect(lines.map((l) => l.$1), contains('VAT, 12%'));
  });

  test('CSV is Excel friendly', () {
    final csv = projectCsv(project);
    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, contains('"Santos residence, ""phase 1"""'));
    expect(csv, contains('"CHB 4"""'));
    expect(csv, contains('\r\n'));
    expect(csv, contains('MATERIALS LIST'));
  });

  test('plain text lists items, the shopping list and the total', () {
    final text = projectText(project);
    expect(text, contains('Client: Maria Santos'));
    expect(text, contains('Shopping list'));
    expect(text, contains('Total contract price'));
  });

  test('a backup restores what was saved', () {
    final text = backupJson(
      projects: [project],
      prices: {'cement_40kg': 255},
      history: [item('chb', 'CHB 4"', 9850)],
    );
    final back = parseBackup(text);
    expect(back.projects.single.name, project.name);
    expect(back.projects.single.items, hasLength(3));
    expect(back.prices, {'cement_40kg': 255.0});
    expect(back.history.single.total, 9850);
  });

  test('a file that is not a backup is refused clearly', () {
    expect(() => parseBackup('not json'), throwsFormatException);
    expect(
      () => parseBackup(jsonEncode({'app': 'Other'})),
      throwsFormatException,
    );
    // Unknown price keys and negative prices are dropped.
    final b = parseBackup(
      jsonEncode({
        'app': 'BuildQuantify',
        'prices': {'nope': 5, 'sand': -1, 'gravel': 1900},
        'projects': [
          {'broken': true},
        ],
      }),
    );
    expect(b.prices, {'gravel': 1900.0});
    expect(b.projects, isEmpty);
  });

  test('file names are safe', () {
    expect(fileSlug(project, 'boq'), 'santos-residence-phase-1-boq');
    expect(fileSlug(Project.create('!!!'), 'boq'), 'project-boq');
  });

  // The Chrome test runner cannot load bundled assets; the browser smoke
  // test downloads the PDF from the release build instead.
  test('the PDF is made with the bundled fonts', testOn: 'vm', () async {
    final bytes = await projectPdf(project, date: DateTime(2026, 10, 15));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
