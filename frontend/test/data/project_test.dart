import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';

Estimate item(
  String materialId,
  double total, {
  String? itemKey,
  List<EstimateLine> companions = const [],
  double quantity = 10,
}) => Estimate(
  id: '$materialId-$total',
  materialId: materialId,
  label: materialId,
  quantity: quantity,
  unit: QuantityUnit.pieces,
  unitPrice: total / quantity,
  total: total,
  createdAt: DateTime(2026, 10, 9),
  itemKey: itemKey,
  companions: companions,
);

EstimateLine cement(double bags) => EstimateLine(
  itemKey: 'cement_40kg',
  label: 'Portland cement, 40 kg',
  quantity: bags,
  unit: 'bags',
  unitPrice: 240,
);

void main() {
  group('cost breakdown', () {
    final items = [
      item('chb', 10000, companions: [cement(10)]), // 12,400 structural
      item('paint', 5000), // architectural
      item('bulb', 1000), // electrical
    ];

    test('an owner budget adds labour and a contingency', () {
      final b = CostBreakdown.of(items, CostSettings.owner);
      expect(b.materials, 18400);
      expect(b.labour, 7360); // 40%
      expect(b.tools, 0);
      expect(b.direct, 25760);
      expect(b.contingency, 2576); // 10%
      expect(b.overhead + b.profit + b.vat, 0);
      expect(b.total, 28336);
      expect(CostSettings.owner.isContractorBid, isFalse);
    });

    test('a contractor bid adds tools, overhead, profit and VAT', () {
      final b = CostBreakdown.of(items, CostSettings.contractor);
      expect(b.labour, 7360);
      expect(b.tools, 736); // 10% of labour
      expect(b.direct, 26496);
      expect(b.contingency, 1324.8); // 5%
      expect(b.overhead, 2649.6); // 10%
      expect(b.profit, 2649.6); // 10%
      expect(b.subtotal, 33120);
      expect(b.vat, 3974.4); // 12%
      expect(b.total, 37094.4);
    });

    test('labour can differ by trade, and hauling is a lump sum', () {
      final settings = CostSettings.owner.copyWith(
        labourByTrade: {MaterialCategory.electrical.name: 100},
        hauling: 1500,
        contingencyPct: 0,
      );
      final b = CostBreakdown.of(items, settings);
      // 40% of 17,400 plus 100% of 1,000.
      expect(b.labour, 6960 + 1000);
      expect(b.total, 18400 + 7960 + 1500);
      expect(b.materialsByTrade[MaterialCategory.structural], 12400);
    });

    test('DPWH markups follow the size of the job', () {
      expect(CostSettings.dpwhMarkups(1440000), (15, 10));
      expect(CostSettings.dpwhMarkups(20000000), (12, 8));
      expect(CostSettings.dpwhMarkups(100000000), (10, 8));
      expect(CostSettings.dpwhMarkups(200000000), (8, 8));

      // The worked example in the DPWH notes: ₱1M of materials.
      final b = CostBreakdown.of([
        item('chb', 1000000),
      ], CostSettings.dpwh(1440000));
      expect(b.direct, 1440000);
      expect(b.overhead, 216000);
      expect(b.profit, 144000);
      expect(b.vat, 90000);
      expect(b.total, 1890000);
    });

    test('presets keep the job\'s labour and hauling', () {
      final job = CostSettings.owner.copyWith(labourPct: 30, hauling: 800);
      final bid = CostSettings.contractor.keepingJobCosts(job);
      expect(bid.labourPct, 30);
      expect(bid.hauling, 800);
      expect(bid.vatPct, 12);
    });

    test('settings survive a round trip and reject bad values', () {
      final s = CostSettings.contractor.copyWith(
        labourByTrade: {'plumbing': 55},
      );
      expect(CostSettings.fromJson(s.toJson()), s);
      final bad = CostSettings.fromJson({'labourPct': -5, 'vatPct': 'x'});
      expect(bad.labourPct, 40);
      expect(bad.vatPct, 0);
    });
  });

  group('shopping list', () {
    test('merges the same material from different estimates', () {
      final lines = consolidate([
        item('chb', 9850, itemKey: 'chb_4', companions: [cement(28)]),
        item(
          'slab',
          9600,
          itemKey: 'cement_40kg',
          quantity: 40,
          companions: const [
            EstimateLine(
              itemKey: 'sand',
              label: 'Washed sand',
              quantity: 3,
              unit: 'm³',
              unitPrice: 1500,
            ),
          ],
        ),
      ]);
      final cementLine = lines.firstWhere((l) => l.key == 'cement_40kg');
      expect(cementLine.quantity, 68);
      expect(cementLine.amount, 28 * 240 + 9600);
      expect(cementLine.unit, 'bags');
      expect(cementLine.group, ItemGroup.cement);
      // Grouped like a hardware list: cement and sand before blocks.
      expect(lines.map((l) => l.key), ['cement_40kg', 'sand', 'chb_4']);
    });

    test('materials without an item key stay separate lines', () {
      final lines = consolidate([item('legacy', 500), item('legacy', 700)]);
      expect(lines, hasLength(1));
      expect(lines.single.amount, 1200);
      expect(lines.single.group, ItemGroup.other);
    });

    test('the list adds up to the materials total', () {
      final p = Project.create('Test').copyWith(
        items: [
          item('chb', 9850, itemKey: 'chb_4', companions: [cement(28)]),
          item('paint', 2880, itemKey: 'paint_latex'),
        ],
      );
      final listed = p.materials.fold<double>(0, (s, l) => s + l.amount);
      expect(listed, p.materialsTotal);
      expect(p.breakdown.materials, p.materialsTotal);
    });
  });

  test('a project survives a round trip', () {
    final p = Project.create('Santos residence').copyWith(
      client: 'Maria',
      location: 'Antipolo',
      costs: CostSettings.contractor,
      items: [
        item('chb', 9850, itemKey: 'chb_4', companions: [cement(28)]),
      ],
    );
    final back = Project.fromJson(p.toJson());
    expect(back.name, p.name);
    expect(back.client, 'Maria');
    expect(back.costs, CostSettings.contractor);
    expect(back.items.single.companions.single.quantity, 28);
    expect(back.breakdown.total, p.breakdown.total);
    expect(() => Project.fromJson({'name': 'x'}), throwsFormatException);
  });

  test('a checklist and what is not needed are saved', () {
    final p = Project.create('House').copyWith(
      checklist: const ['footing', 'column', 'chb'],
      notNeeded: const {'column'},
    );
    final back = Project.fromJson(p.toJson());
    expect(back.checklist, ['footing', 'column', 'chb']);
    expect(back.notNeeded, {'column'});
    expect(back.checklistToDo, ['footing', 'chb']);
    expect(Project.fromJson(Project.create('x').toJson()).checklist, isEmpty);
  });
}
