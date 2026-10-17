import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/price_quote.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/export/project_documents.dart';
import 'package:thesismob/export/project_sheets.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  final project = Project.create('Santos residence').copyWith(
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
        companions: const [
          EstimateLine(
            itemKey: 'cement_40kg',
            label: 'Portland cement, 40 kg',
            quantity: 5,
            unit: 'bags',
            unitPrice: 240,
          ),
        ],
      ),
    ],
  );
  const suppliers = {'cement_40kg': 'Wilcon Depot'};

  test('the CSV materials list names the supplier', () {
    expect(projectCsv(project), isNot(contains('Supplier')));
    final csv = projectCsv(project, suppliers: suppliers);
    expect(csv, contains('Amount (PHP),Supplier'));
    expect(csv, contains(',Wilcon Depot'));
  });

  test('the Materials tab has a supplier column when there is one', () {
    List<Object?> header(Map<String, String> s) {
      final tab = projectSheetTabs(project, suppliers: s)[2];
      return tab.rows[tab.headerRow];
    }

    expect(header(const {}), isNot(contains('Supplier')));
    expect(header(suppliers).last, 'Supplier');
    final tab = projectSheetTabs(project, suppliers: suppliers)[2];
    expect(
      tab.rows.any((r) => r.isNotEmpty && r.last == 'Wilcon Depot'),
      isTrue,
    );
  });

  test('a backup keeps suppliers and quote dates', () {
    final quote = PriceQuote(
      supplier: 'Wilcon Depot',
      date: DateTime(2026, 9, 3),
    );
    final back = parseBackup(
      backupJson(
        projects: const [],
        prices: const {'cement_40kg': 255},
        quotes: {'cement_40kg': quote},
        history: const [],
      ),
    );
    expect(back.quotes, {'cement_40kg': quote});
    expect(
      parseBackup(
        backupJson(projects: const [], prices: const {}, history: const []),
      ).quotes,
      isEmpty,
    );
  });
}
