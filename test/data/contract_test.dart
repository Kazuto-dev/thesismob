import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/catalog.dart';

Estimate estimate(String id, Map<String, double> inputs) {
  final spec = materialById(id)!;
  return Estimate.fromResult(
    materialId: id,
    result: spec.calculate(inputs, spec.initialChoices),
    inputs: inputs,
    choices: spec.initialChoices,
  );
}

Project house({ContractData contract = const ContractData()}) =>
    Project.create('House').copyWith(
      costs: CostSettings.contractor.copyWith(
        general: const {'mobilization': 20000},
      ),
      contract: contract,
      items: [
        estimate('footing', {
          'count': 6,
          'length': 1.2,
          'width': 1.2,
          'thickness': 0.25,
          'price': 240,
        }),
        estimate('chb', {'length': 30, 'height': 3, 'price': 25}),
        estimate('paint', {'length': 30, 'height': 3, 'price': 980}),
      ],
    );

void main() {
  test('contract data is saved and read back', () {
    final c = ContractData(
      terms: const QuoteTerms(downpaymentPct: 20, exclusions: 'Permits'),
      startDate: DateTime(2026, 11, 2),
      crews: const {'structural': 2},
      billings: [
        Billing(
          id: 'b1',
          date: DateTime(2026, 11, 30),
          progress: const {'x': 40},
        ),
      ],
      variations: [
        VariationOrder(
          id: 'v1',
          date: DateTime(2026, 11, 20),
          description: 'Extra window',
          amount: 18000,
        ),
      ],
      expenses: [
        Expense(
          id: 'x1',
          date: DateTime(2026, 11, 5),
          description: 'Cement, 50 bags',
          kind: ExpenseKind.materials,
          amount: 12000,
        ),
      ],
    );
    final p = Project.create('A').copyWith(contract: c);
    final back = Project.fromJson(p.toJson()).contract;
    expect(back.terms, c.terms);
    expect(back.startDate, DateTime(2026, 11, 2));
    expect(back.crewsFor('structural'), 2);
    expect(back.crewsFor('plumbing'), 1);
    expect(back.billings.single.progress, {'x': 40});
    expect(back.variations.single.amount, 18000);
    expect(back.expenses.single.kind, ExpenseKind.materials);
    expect(Project.create('B').toJson().containsKey('contract'), isFalse);
  });

  test('contract lines carry the markups and add up to the price', () {
    final p = house();
    final lines = contractLines(p);
    expect(lines.first.number, 'A.1');
    expect(lines.last.key, 'general|mobilization');
    final sum = lines.fold<double>(0, (s, l) => s + l.amount);
    expect(sum, closeTo(p.breakdown.total, 0.001));

    final changed = house(
      contract: ContractData(
        variations: [
          VariationOrder(
            id: 'v1',
            date: DateTime(2026, 12, 1),
            description: 'Extra window',
            amount: 18000,
          ),
        ],
      ),
    );
    expect(contractLines(changed).last.number, 'VO-1');
    expect(contractPrice(changed), closeTo(p.breakdown.total + 18000, 0.001));
  });

  test('billings recoup the downpayment and hold retention', () {
    final base = house();
    final keys = [for (final l in contractLines(base)) l.key];
    Billing at(String id, double pct) => Billing(
      id: id,
      date: DateTime(2026, 12, 1),
      progress: {for (final k in keys) k: pct},
    );
    final p = base.copyWith(
      contract: ContractData(billings: [at('b1', 30), at('b2', 75)]),
    );
    final price = p.breakdown.total;
    final s = billingStatements(p);
    expect(s, hasLength(2));
    expect(s[0].toDate, closeTo(price * 0.30, 0.05));
    expect(s[0].previous, 0);
    expect(s[1].thisPeriod, closeTo(price * 0.45, 0.05));
    // 30% downpayment recouped and 10% retention held from each billing.
    expect(s[1].recoupment, closeTo(s[1].thisPeriod * 0.30, 0.01));
    expect(s[1].retention, closeTo(s[1].thisPeriod * 0.10, 0.01));
    expect(s[1].netDue, closeTo(s[1].thisPeriod * 0.60, 0.02));
    expect(s[1].percentComplete, closeTo(75, 0.01));
    expect(downpayment(p), closeTo(price * 0.30, 0.01));
  });

  test('the schedule follows the building order', () {
    final schedule = Schedule.of(house());
    final phases = [for (final t in schedule.tasks) t.label];
    expect(phases.first, 'Mobilization and layout');
    expect(phases.last, 'Testing, punch list and turnover');
    expect(
      phases.indexOf('Foundations'),
      lessThan(phases.indexOf('Walls and rough-ins')),
    );
    expect(
      phases.indexOf('Walls and rough-ins'),
      lessThan(phases.indexOf('Finishes and openings')),
    );
    for (var i = 1; i < schedule.tasks.length; i++) {
      expect(
        schedule.tasks[i].phase,
        greaterThanOrEqualTo(schedule.tasks[i - 1].phase),
      );
    }
    final curve = schedule.sCurve;
    expect(curve, isNotEmpty);
    expect(curve.last, closeTo(100, 0.001));
    for (var i = 1; i < curve.length; i++) {
      expect(curve[i], greaterThanOrEqualTo(curve[i - 1]));
    }

    // Three masonry crews instead of the one the app picks for so small a
    // wall finish it sooner.
    final faster = Schedule.of(
      house(contract: const ContractData(crews: {'structural': 3})),
    );
    expect(faster.days, lessThan(schedule.days));
  });

  test('working days skip Sundays', () {
    // Saturday 7 November 2026 + 2 working days = Tuesday the 10th.
    expect(
      Schedule.addWorkingDays(DateTime(2026, 11, 7), 2),
      DateTime(2026, 11, 10),
    );
  });

  test('new contract settings are saved, and old saves read', () {
    final c = ContractData(
      terms: const QuoteTerms(client: ClientType.government, paymentDays: 45),
      rainPct: 15,
      targetWeeks: 24,
      finishBy: DateTime(2027, 5, 31),
    );
    final back = ContractData.fromJson(c.toJson());
    expect(back.terms.client, ClientType.government);
    expect(back.terms.paymentDays, 45);
    expect(back.rainPct, 15);
    expect(back.targetWeeks, 24);
    expect(back.finishBy, DateTime(2027, 5, 31));
    expect(back.withTarget().targetWeeks, isNull);
    expect(back.withTarget().finishBy, isNull);

    final old = ContractData.fromJson({
      'terms': {'downpaymentPct': 20},
    });
    expect(old.terms.client, ClientType.individual);
    expect(old.terms.paymentDays, 30);
    expect(old.rainPct, ContractData.defaultRainPct);
    expect(old.targetWeeks, isNull);
    expect(const ContractData().isEmpty, isTrue);
    expect(const ContractData(rainPct: 5).isEmpty, isFalse);
  });
}
