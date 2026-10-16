import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/boq.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/quotes.dart';
import 'package:thesismob/materials/material_spec.dart';

Estimate item(String id, String materialId, double total) => Estimate(
  id: id,
  materialId: materialId,
  label: '$materialId $id',
  quantity: total / 25,
  unit: QuantityUnit.pieces,
  unitPrice: 25,
  total: total,
  createdAt: DateTime(2026, 10, 9),
);

BidQuote quote(
  String id,
  double amount, {
  String scope = wholeJob,
  bool awarded = false,
}) => BidQuote(
  id: id,
  bidder: 'Bidder $id',
  amount: amount,
  date: DateTime(2026, 10, 1),
  scope: scope,
  awarded: awarded,
);

final job = Project.create('Santos residence').copyWith(
  costs: CostSettings.contractor.copyWith(general: {'mobilization': 10000}),
  items: [item('a', 'chb', 100000), item('b', 'bulb', 20000)],
);

void main() {
  test('quotes are saved compactly and damaged ones are skipped', () {
    final q = BidQuote(
      id: 'q1',
      bidder: 'Reyes Builders',
      amount: 1250000,
      date: DateTime(2026, 10, 3),
      scope: 'electrical',
      validityDays: 45,
      inclusions: 'Labour and materials',
      exclusions: 'Fixtures',
      awarded: true,
    );
    final p = job.copyWith(quotes: [q, quote('q2', 900000)]);
    final json = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
    expect((json['quotes'] as List).last, {
      'id': 'q2',
      'bidder': 'Bidder q2',
      'amount': 900000,
      'date': '2026-10-01',
    });
    final back = Project.fromJson(json).quotes;
    expect(back.first.toJson(), q.toJson());
    expect(back.last.scope, wholeJob);
    expect(back.last.validityDays, 30);

    expect(Project.fromJson(job.toJson()).quotes, isEmpty);
    final damaged = quotesFromJson([
      'x',
      {'id': 'q', 'amount': 'lots'},
      {'id': 'ok', 'amount': 5, 'scope': 'roofing', 'validityDays': -3},
    ]);
    expect(damaged.single.id, 'ok');
    expect(damaged.single.validityDays, 30);
    expect(bidScope(damaged.single.scope).key, wholeJob);
  });

  test('a quote is valid for its days from its date', () {
    final q = quote('q', 1).copyWith(validityDays: 30);
    expect(q.validUntil, DateTime(2026, 10, 31));
    expect(q.isExpiredOn(DateTime(2026, 10, 31, 18)), isFalse);
    expect(q.isExpiredOn(DateTime(2026, 11, 1)), isTrue);
  });

  test('the estimate for a scope is its share of the total', () {
    final b = job.breakdown;
    expect(scopeEstimate(job, wholeJob), b.total);
    expect(scopeEstimate(job, wholeJob, withMarkups: false), b.direct);

    final sections = workSections(job);
    final structural = sections.first.entries.fold<double>(
      0,
      (s, e) => s + e.analysis.directCost,
    );
    expect(scopeEstimate(job, 'structural', withMarkups: false), structural);
    expect(
      scopeEstimate(job, 'structural'),
      closeTo(structural * b.total / b.direct, 0.01),
    );
    expect(scopeEstimate(job, generalScope, withMarkups: false), 10000);
    expect(scopeEstimate(job, 'plumbing'), 0);
    expect(
      [for (final s in scopesOf(job)) s.key],
      [wholeJob, 'structural', 'electrical', generalScope],
    );
  });

  test('quotes are compared with the estimate for their scope', () {
    final total = job.breakdown.total;
    final electrical = scopeEstimate(job, 'electrical');
    final p = job.copyWith(
      quotes: [
        quote('high', total * 1.1),
        quote('low', total * 0.7),
        quote('fair', total * 0.95),
        quote('sub', electrical * 0.9, scope: 'electrical'),
      ],
    );
    final groups = compareQuotes(p);
    expect([for (final g in groups) g.scope.key], [wholeJob, 'electrical']);

    final whole = groups.first;
    expect(whole.estimate, total);
    expect([for (final c in whole.quotes) c.quote.id], ['low', 'fair', 'high']);
    final low = whole.quotes.first;
    expect(low.lowest, isTrue);
    expect(low.percent, -30);
    expect(low.difference, closeTo(-total * 0.3, 0.01));
    expect(low.farBelow, isTrue, reason: 'more than 20% below');
    expect(whole.quotes[1].farBelow, isFalse);
    expect(whole.quotes[1].lowest, isFalse);
    expect(whole.quotes[2].percent, 10);

    final sub = groups.last.quotes.single;
    expect(sub.lowest, isTrue);
    expect(sub.percent, -10);

    final direct = compareQuotes(p, withMarkups: false);
    expect(direct.first.estimate, job.breakdown.direct);
  });

  test('one quote is awarded in each scope', () {
    var quotes = <BidQuote>[
      quote('a', 1),
      quote('b', 2),
      quote('c', 3, scope: 'electrical', awarded: true),
    ];
    quotes = awardQuote(quotes, 'a');
    expect([for (final q in quotes) q.awarded], [true, false, true]);
    quotes = awardQuote(quotes, 'b');
    expect(
      [for (final q in quotes) q.awarded],
      [false, true, true],
      reason: 'the electrical award stays',
    );
    quotes = awardQuote(quotes, 'b');
    expect([for (final q in quotes) q.awarded], [false, false, true]);
    expect(awardQuote(quotes, 'missing'), same(quotes));
  });
}
