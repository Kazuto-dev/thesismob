import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/checks.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/catalog.dart';

Estimate estimate(String id, Map<String, double> inputs, {DateTime? at}) {
  final spec = materialById(id)!;
  return Estimate.fromResult(
    materialId: id,
    result: spec.calculate(inputs, spec.initialChoices),
    inputs: inputs,
    choices: spec.initialChoices,
    createdAt: at ?? DateTime(2026, 10, 1),
  );
}

void main() {
  final today = DateTime(2026, 10, 15);

  test('a quick budget scales with area, storeys and finishes', () {
    final one = parametricBudget(100, 1, FinishLevel.standard);
    expect(one.low, 100 * FinishLevel.standard.low);
    expect(one.high, 100 * FinishLevel.standard.high);
    final two = parametricBudget(100, 2, FinishLevel.standard);
    expect(two.low, closeTo(one.low * 1.05, 0.01));
    expect(
      parametricBudget(100, 1, FinishLevel.premium).low,
      greaterThan(one.high - 1),
    );
    expect(
      parametricSplit.fold<double>(0, (s, p) => s + p.$2),
      closeTo(1, 1e-9),
    );
  });

  test('a footing-only project is flagged as missing walls and wiring', () {
    final p = Project.create('Footings').copyWith(
      items: [
        estimate('footing', {
          'count': 6,
          'length': 1.2,
          'width': 1.2,
          'thickness': 0.25,
          'price': 240,
        }),
      ],
    );
    final checks = checkProject(p, today: today);
    final titles = [for (final c in checks) c.title];
    expect(titles, contains('Concrete but no walls'));
    expect(titles, contains('No electrical work'));
    final steel = checks.firstWhere((c) => c.title.startsWith('Reinforcing'));
    expect(steel.level, CheckLevel.ok, reason: steel.title);
  });

  test('a cost per m² far below a finished house is a warning', () {
    final p = Project.create('Wall').copyWith(
      floorArea: 200,
      items: [
        estimate('chb', {'length': 10, 'height': 3, 'price': 25}),
      ],
    );
    final perM2 = checkProject(
      p,
      today: today,
    ).firstWhere((c) => c.title.startsWith('Cost per m²'));
    expect(perM2.level, CheckLevel.warning);
  });

  test('old prices and missing prices are flagged', () {
    final old = estimate('chb', {
      'length': 10,
      'height': 3,
      'price': 25,
    }, at: DateTime(2026, 1, 10));
    final unpriced = old.copyWith(unitPrice: 0);
    final p = Project.create('Old').copyWith(items: [unpriced]);
    final titles = [for (final c in checkProject(p, today: today)) c.title];
    expect(titles, contains('Some prices are 9 months old'));
    expect(titles.any((t) => t.contains('no price')), isTrue);
  });

  test('price escalation adds to the total before markups', () {
    final items = [
      estimate('chb', {'length': 10, 'height': 3, 'price': 25}),
    ];
    final plain = Project.create('a').copyWith(items: items).breakdown;
    final escalated = Project.create('b')
        .copyWith(items: items, costs: const CostSettings(escalationPct: 5))
        .breakdown;
    expect(escalated.escalation, closeTo(plain.direct * 0.05, 0.01));
    expect(escalated.total, closeTo(plain.total + plain.direct * 0.05, 0.02));
    expect(
      CostSettings.fromJson(const CostSettings(escalationPct: 5).toJson())
          .escalationPct,
      5,
    );
  });
}
