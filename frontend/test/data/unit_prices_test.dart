import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/unit_prices.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/work_items.dart';

Estimate wall() => Estimate.fromResult(
  materialId: 'chb',
  result: materialById('chb')!.calculate(
    {'length': 10, 'height': 3, 'price': 25},
    {
      'size': '4',
      'waste': '5',
      'plaster': '2',
      'bar': '10',
      'vertical': '0.6',
      'horizontal': '3',
    },
  ),
  inputs: const {'length': 10, 'height': 3, 'price': 25},
  choices: const {'size': '4', 'waste': '5', 'plaster': '2'},
);

void main() {
  test('an estimate keeps the work it measures', () {
    final e = wall();
    expect(
      [for (final w in e.works) w.key],
      [Work.chb4, Work.plaster, Work.rebar],
    );
    expect(e.works[0].quantity, 30);
    expect(e.works[1].quantity, 60);
    final back = Estimate.fromJson(e.toJson());
    expect(back.works, e.works);
  });

  test('crews price labour and equipment from daily output', () {
    final e = wall();
    final r = DailyRates.defaults;
    final rebarKg = e.works[2].quantity;
    final expected =
        30 / 11 * (r['skilled']! + r['helper']!) +
        60 / 14 * (r['skilled']! + r['helper']!) +
        rebarKg / 175 * (0.1 * r['foreman']! + r['skilled']! + r['helper']!);
    final cost = labourOf(e, const CostSettings());
    expect(cost.labour, closeTo(expected, 0.01));
    expect(cost.equipment, closeTo(60 / 14 * 0.5 * r['scaffold']!, 0.01));
    expect(cost.crewDays, closeTo(30 / 11 + 60 / 14 + rebarKg / 175, 1e-9));

    // Slower crews take longer; the percentage method ignores crews.
    final slow = labourOf(e, const CostSettings(productivityPct: 50));
    expect(slow.labour, closeTo(expected * 2, 0.01));
    final share = labourOf(
      e,
      const CostSettings(labourMethod: LabourMethod.percent, labourPct: 40),
    );
    expect(share.labour, closeTo(e.grandTotal * 0.4, 0.001));
    expect(share.equipment, 0);
  });

  test('your own daily rates are used', () {
    final e = wall();
    final base = labourOf(e, const CostSettings()).labour;
    final dearer = labourOf(
      e,
      const CostSettings(rates: {'skilled': 1900, 'helper': 1500}),
    ).labour;
    expect(dearer, greaterThan(base * 1.6));
  });

  test('materials go to their work items, and the analyses add up', () {
    final e = wall();
    final analyses = analyseEstimate(e, const CostSettings());
    expect(
      [for (final a in analyses) a.work.key],
      [Work.chb4, Work.plaster, Work.rebar],
    );
    final rebar = analyses[2];
    expect(
      rebar.materials.map((m) => m.label),
      everyElement(anyOf(contains('Deformed bar'), contains('Tie wire'))),
    );
    expect(
      analyses.fold<double>(0, (s, a) => s + a.materialCost),
      closeTo(e.grandTotal, 0.01),
    );
    final project = Project.create('Test').copyWith(items: [e]);
    final b = project.breakdown;
    expect(
      analyses.fold<double>(0, (s, a) => s + a.directCost),
      closeTo(b.materials + b.labour + b.tools + b.equipment, 0.05),
    );
    expect(
      analyses.first.unitCost,
      closeTo(analyses.first.directCost / 30, 0.01),
    );
  });

  test('estimates saved before work items are measured again', () {
    final json = wall().toJson()..remove('works');
    final old = Estimate.fromJson(json);
    expect(old.works, isEmpty);
    expect(
      [for (final w in worksOf(old)) w.key],
      [Work.chb4, Work.plaster, Work.rebar],
    );
  });

  test('general requirements are part of the direct cost', () {
    final e = wall();
    final plain = Project.create('a').copyWith(items: [e]).breakdown;
    final general = suggestGeneralRequirements(plain.direct);
    expect(general['signboard'], 5000);
    final withGeneral = Project.create('b')
        .copyWith(
          items: [e],
          costs: CostSettings(general: general),
        )
        .breakdown;
    final sum = general.values.fold<double>(0, (s, v) => s + v);
    expect(withGeneral.general, sum);
    expect(withGeneral.direct, closeTo(plain.direct + sum, 0.01));
  });

  test('labour settings are saved; older projects keep percentages', () {
    const c = CostSettings(
      rates: {'skilled': 1000},
      productivityPct: 80,
      general: {'permits': 15000},
    );
    final back = CostSettings.fromJson(c.toJson());
    expect(back, c);
    expect(back.labourMethod, LabourMethod.crews);
    expect(back.dailyRates['skilled'], 1000);
    expect(back.dailyRates['helper'], DailyRates.defaults['helper']);
    final legacy = CostSettings.fromJson({'labourPct': 35});
    expect(legacy.labourMethod, LabourMethod.percent);
  });
}
