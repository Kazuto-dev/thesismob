import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/boq.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/custom_items.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/unit_prices.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  final at = DateTime(2026, 10, 16);
  final hood = customItem(
    description: 'Kitchen range hood',
    kind: CustomKind.supply,
    trade: MaterialCategory.architectural,
    unit: QuantityUnit.sets,
    quantity: 2,
    price: 8000,
    labour: 1500,
    now: at,
  );
  final solar = customItem(
    description: 'Solar panels, 3 kW',
    kind: CustomKind.subcontract,
    trade: MaterialCategory.electrical,
    unit: QuantityUnit.lots,
    quantity: 1,
    price: 180000,
    labour: 5000, // ignored: a subcontract is all-in
    now: at,
  );
  final allowance = customItem(
    description: 'Landscaping allowance',
    kind: CustomKind.provisional,
    trade: null,
    unit: QuantityUnit.lots,
    quantity: 1,
    price: 50000,
    now: at,
  );

  test('a custom item keeps its kind, trade and labour through JSON', () {
    final back = Estimate.fromJson(hood.toJson());
    expect(back.isCustom, isTrue);
    expect(back.customKind, CustomKind.supply);
    expect(tradeOf(back), MaterialCategory.architectural);
    expect(back.labourRate, 1500);
    expect(back.total, 16000);
    expect(back.unit, QuantityUnit.sets);
    expect(Estimate.fromJson(solar.toJson()).labourRate, 0);
    expect(tradeOf(allowance), isNull);
  });

  test('changing a custom item keeps its id, date and mark', () {
    final named = hood.copyWith(mark: 'K1');
    final changed = customItem(
      description: 'Kitchen range hood, 90 cm',
      kind: CustomKind.supply,
      trade: MaterialCategory.architectural,
      unit: QuantityUnit.sets,
      quantity: 1,
      price: 12000,
      from: named,
    );
    expect(changed.id, hood.id);
    expect(changed.createdAt, at);
    expect(changed.mark, 'K1');
    expect(changed.total, 12000);
  });

  test('supply items are materials and labour; subcontracts are all-in', () {
    const s = CostSettings(toolsPct: 10, contingencyPct: 0);
    final b = CostBreakdown.of([hood, solar, allowance], s);
    expect(b.materials, 16000);
    expect(b.labour, 3000);
    expect(b.tools, 300);
    expect(b.subcontracts, 230000);
    expect(b.direct, 16000 + 3000 + 300 + 230000);
    // Only the supply item is bought as a material.
    final shopping = consolidate([hood, solar, allowance]);
    expect([for (final l in shopping) l.label], ['Kitchen range hood']);
  });

  test('a custom item is one unit price analysis in its own section', () {
    const s = CostSettings(toolsPct: 10, contingencyPct: 0);
    final a = analyseEstimate(hood, s).single;
    expect(a.item, isNull);
    expect(a.unit, 'sets');
    expect(a.materialCost, 16000);
    expect(a.labourCost, 3000);
    expect(a.unitCost, 9650); // (16,000 + 3,000 + 300) ÷ 2
    final project = Project.create('House')
        .copyWith(items: [hood, solar, allowance]);
    final sections = workSections(project);
    expect([for (final s in sections) s.letter], ['B', 'C', 'E']);
    expect(
      workDescription(sections[1].entries.single.analysis),
      'Solar panels, 3 kW',
    );
  });

  test('contract lines with custom items add up to the contract price', () {
    final project = Project.create(
      'House',
    ).copyWith(items: [hood, solar, allowance], costs: CostSettings.contractor);
    final sum = contractLines(project).fold<double>(0, (s, l) => s + l.amount);
    expect(sum, closeTo(project.breakdown.total, 0.001));
  });
}
