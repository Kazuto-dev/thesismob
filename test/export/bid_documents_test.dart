import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/quotes.dart';
import 'package:thesismob/data/revisions.dart';
import 'package:thesismob/export/bid_documents.dart';
import 'package:thesismob/export/bid_pdf.dart';
import 'package:thesismob/export/project_documents.dart';
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
);

final project = Project.create('Santos residence').copyWith(
  client: 'Maria Santos',
  location: 'Antipolo',
  costs: CostSettings.contractor.copyWith(
    general: {'mobilization': 15000},
    hauling: 5000,
  ),
  items: [
    item('chb', 'CHB 4"', 9850),
    item('bulb', 'LED bulb', 1150),
    item('outlet', 'Outlets', 2400),
    item('paint', 'Latex paint', 2880),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bill for bidders has quantities and no prices', () {
    final rows = bidBoqRows(project);
    final own = workBoqRows(project);
    expect(
      [for (final r in rows) r.number],
      [for (final r in own) r.number],
      reason: 'numbered as in the project bill',
    );
    expect(
      [for (final r in rows) r.quantity],
      [for (final r in own) r.quantity],
    );
    expect(rows.every((r) => r.unitPrice == null && r.amount == null), isTrue);
    expect(
      [
        for (final r in rows)
          if (r.isHeading) r.description,
      ],
      [
        'STRUCTURAL WORKS',
        'ARCHITECTURAL WORKS',
        'ELECTRICAL WORKS',
        'GENERAL REQUIREMENTS',
      ],
    );
    expect(rows.last.isSubtotal, isTrue);
  });

  test('a bill for one trade has its own section only', () {
    final rows = bidBoqRows(project, scope: 'electrical');
    expect(rows.first.description, 'ELECTRICAL WORKS');
    expect(
      [
        for (final r in rows)
          if (!r.isHeading && !r.isSubtotal) r.number,
      ],
      ['C.1', 'C.2'],
    );
    expect(rows.last.description, 'Subtotal, electrical works');
    expect(
      bidFileSlug(project, 'electrical'),
      'santos-residence-bid-boq-electrical',
    );
    expect(bidFileSlug(project, wholeJob), 'santos-residence-bid-boq');
  });

  test('the CSV has instructions, empty prices and a total to fill in', () {
    final csv = bidCsv(
      project,
      scope: 'electrical',
      date: DateTime(2026, 10, 16),
    );
    final lines = csv.substring(1).split('\r\n');
    expect(lines.first, 'BILL OF QUANTITIES FOR BIDDERS');
    expect(lines, contains('Scope,C. Electrical works'));
    expect(lines, contains('Date,2026-10-16'));
    expect(lines, contains('INSTRUCTIONS TO BIDDERS'));
    expect(lines, contains('6,This bill covers electrical works only.'));
    expect(
      lines,
      contains('Item,Description,Quantity,Unit,Unit price (PHP),Amount (PHP)'),
    );
    expect(lines.where((l) => l.startsWith('C.')), hasLength(2));
    expect(lines.firstWhere((l) => l.startsWith('C.1,')), endsWith(',10,pcs'));
    expect(lines, contains(',TOTAL BID PRICE (PHP)'));
    expect(lines.last, 'Date of bid,');
    expect(csv, isNot(contains('Revision')));
    expect(csv, isNot(contains('1150')), reason: 'no amounts are given away');
  });

  test('exports name the revision of the estimate', () {
    final saved = project.copyWith(revisions: addRevision(project, 'For bid'));
    expect(bidCsv(saved), contains('Revision,Rev 1'));
    expect(projectCsv(saved), contains('Revision,Rev 1'));
    final changed = saved.copyWith(items: saved.items.take(2).toList());
    expect(projectCsv(changed), contains('Revision,Draft after Rev 1'));
    expect(projectCsv(project), isNot(contains('Revision')));
  });

  // The Chrome test runner cannot load bundled assets.
  test('the bill for bidders is made as a PDF', testOn: 'vm', () async {
    for (final scope in [wholeJob, 'electrical']) {
      final bytes = await bidPdf(
        project,
        scope: scope,
        date: DateTime(2026, 10, 16),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));
    }
  });
}
