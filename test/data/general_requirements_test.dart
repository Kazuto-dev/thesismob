import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/checks.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/export/project_documents.dart';
import 'package:thesismob/materials/catalog.dart';

Estimate estimate(String id, Map<String, double> inputs) {
  final spec = materialById(id)!;
  return Estimate.fromResult(
    materialId: id,
    result: spec.calculate(inputs, spec.initialChoices),
    inputs: inputs,
    choices: spec.initialChoices,
    createdAt: DateTime(2026, 10, 1),
  );
}

void main() {
  final wall = estimate('chb', {'length': 40, 'height': 3, 'price': 25});

  test('monthly costs run for the months of the schedule', () {
    final project = Project.create('Wall').copyWith(
      items: [wall],
      costs: const CostSettings(
        general: {'mobilization': 5000},
        monthly: {'supervision': 10000, 'security': 8000},
        hauling: 2000,
      ),
    );
    final months = project.months;
    expect(months, greaterThan(0));
    expect(months, closeTo(Schedule.of(project).days / 26, 0.005));
    final b = project.breakdown;
    expect(b.months, months);
    expect(b.timeRelated, closeTo(18000 * months, 0.01));
    expect(b.general, closeTo(5000 + 18000 * months, 0.01));

    // The lines of section F add up to the general requirements and
    // hauling, each monthly line as months × the monthly cost.
    final lines = generalLines(project);
    expect(
      [for (final l in lines) l.key],
      ['mobilization', 'supervision', 'security', 'hauling'],
    );
    final supervision = lines[1];
    expect(supervision.unit, 'month');
    expect(supervision.quantity, months);
    expect(supervision.amount, closeTo(10000 * months, 0.005));
    expect(
      lines.fold<double>(0, (s, l) => s + l.amount),
      closeTo(b.general + b.hauling, 0.01),
    );
    final rows = workBoqRows(project);
    expect(
      rows.any((r) => r.description == 'Site engineer and supervision'),
      isTrue,
    );
  });

  test('more crews shorten the job and cut the monthly costs', () {
    final base = Project.create('Wall').copyWith(
      items: [wall],
      costs: const CostSettings(monthly: {'supervision': 30000}),
    );
    final faster = base.copyWith(
      contract: base.contract.copyWith(crews: {'structural': 3}),
    );
    expect(faster.months, lessThan(base.months));
    expect(faster.breakdown.general, lessThan(base.breakdown.general));
  });

  test('monthly costs are saved and suggested by the size of the job', () {
    const costs = CostSettings(monthly: {'utilities': 2500});
    expect(CostSettings.fromJson(costs.toJson()), costs);
    expect(CostSettings.fromJson(const {}).monthly, isEmpty);
    final small = suggestMonthlyRequirements(800000);
    expect(small.containsKey('security'), isFalse);
    final house = suggestMonthlyRequirements(2600000);
    expect(house['supervision'], 8000);
    expect(house['security'], 8000);
    final large = suggestMonthlyRequirements(20000000);
    expect(large['supervision'], greaterThan(house['supervision']!));
    expect(
      suggestGeneralRequirements(2600000).containsKey('professional'),
      isFalse,
    );
  });

  test('a house below the economy range is flagged, far below warned', () {
    ProjectCheck perM2(Project p) => checkProject(
      p,
      today: DateTime(2026, 10, 16),
    ).firstWhere((c) => c.title.startsWith('Cost per m²'));
    final total = Project.create('x')
        .copyWith(items: [wall], costs: CostSettings.contractor)
        .breakdown
        .total;
    Project at(double perM2, {bool contractor = true}) =>
        Project.create('x').copyWith(
          items: [wall],
          costs: contractor ? CostSettings.contractor : CostSettings.owner,
          floorArea: total / perM2,
        );
    expect(perM2(at(26000)).level, CheckLevel.info);
    expect(perM2(at(26000)).detail, contains('Below the usual'));
    expect(perM2(at(12000)).level, CheckLevel.warning);
    expect(perM2(at(42000)).level, CheckLevel.ok);
    expect(perM2(at(42000)).detail, contains('standard range'));
    expect(perM2(at(90000)).level, CheckLevel.info);
  });

  test('an owner\'s own build is compared with lower ranges', () {
    final owner = Project.create('x').copyWith(items: [wall]);
    final area = owner.breakdown.total / 25000;
    final check = checkProject(
      owner.copyWith(floorArea: area),
      today: DateTime(2026, 10, 16),
    ).firstWhere((c) => c.title.startsWith('Cost per m²'));
    // ₱25,000 is above ₱21,000, the low end for an owner's own build.
    expect(check.level, CheckLevel.ok);
    expect(check.detail, contains('owner\'s own build'));
  });
}
