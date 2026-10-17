import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/revisions.dart';
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

Project base() => Project.create('Santos residence').copyWith(
  items: [
    item('a', 'chb', 10000),
    item('b', 'tiles', 5000),
    item('c', 'bulb', 1000),
  ],
);

/// Saves the current estimate of [p] as a revision.
Project save(Project p, String note, {DateTime? at}) =>
    p.copyWith(revisions: addRevision(p, note, now: at));

void main() {
  test('revisions are numbered and the newest twenty are kept', () {
    var p = base();
    expect(p.revisions, isEmpty);
    p = save(p, 'Rev for the client', at: DateTime(2026, 10, 1));
    expect(p.revisions.single.number, 1);
    expect(p.revisions.single.label, 'Rev 1');
    expect(p.revisions.single.items, hasLength(3));
    for (var i = 0; i < 24; i++) {
      p = save(p, 'Change $i');
    }
    expect(p.revisions, hasLength(maxRevisions));
    expect(p.revisions.first.number, 6, reason: 'the oldest are dropped');
    expect(p.revisions.last.number, 25, reason: 'numbers are never reused');
    expect(nextRevisionNumber(p), 26);
  });

  test('revisions are saved with the project and stay compact', () {
    var p = base();
    p = save(p, 'Rev 1 for the client', at: DateTime(2026, 10, 1, 9, 30));
    p = p.copyWith(
      items: [item('a', 'chb', 12000), ...p.items.skip(1)],
      costs: CostSettings.contractor,
    );
    p = save(p, 'Client added a wall', at: DateTime(2026, 10, 2));

    final json = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
    final saved = json['revisions'] as List;
    expect(saved, hasLength(2));
    // Items unchanged since the revision before are written as their id.
    expect((saved[1] as Map)['items'], [isA<Map<String, dynamic>>(), 'b', 'c']);

    final back = Project.fromJson(json);
    expect(back.revisions.map((r) => r.number), [1, 2]);
    expect(back.revisions.first.note, 'Rev 1 for the client');
    expect(back.revisions.first.date, DateTime(2026, 10, 1, 9, 30));
    expect(back.revisions.first.costs, CostSettings.owner);
    expect(back.revisions.last.costs, CostSettings.contractor);
    expect(back.revisions.last.items.map((e) => e.total), [12000, 5000, 1000]);
    expect(back.revisions.first.items.first.total, 10000);
    expect(back.toJson(), json, reason: 'saves the same way again');
  });

  test('old projects and damaged revisions still open', () {
    final json = base().toJson();
    expect(Project.fromJson(json).revisions, isEmpty);
    final back = Project.fromJson({
      ...json,
      'revisions': [
        'nonsense',
        {'number': 'one', 'date': '2026-10-01'},
        {
          'number': 3,
          'date': '2026-10-01T09:00:00.000',
          'items': [
            'missing',
            {'broken': true},
            item('x', 'chb', 500).toJson(),
          ],
        },
      ],
    });
    final r = back.revisions.single;
    expect(r.number, 3);
    expect(r.items.single.id, 'x');
    expect(r.costs, CostSettings.owner);
  });

  test('documents say which revision the estimate is at', () {
    var p = base();
    expect(revisionLabel(p), isNull);
    p = save(p, 'For the client');
    expect(revisionLabel(p), 'Rev 1');
    p = p.copyWith(items: p.items.take(2).toList());
    expect(revisionLabel(p), 'Draft after Rev 1');
    p = save(p, 'Removed the bulb');
    expect(revisionLabel(p), 'Rev 2');
    final first = p.revisions.first;
    p = p.copyWith(items: first.items, costs: first.costs);
    expect(revisionLabel(p), 'Rev 1', reason: 'a restored revision');
    expect(matchingRevision(p)?.number, 1);
  });

  test('a comparison lists items added, removed and changed', () {
    var p = save(base(), 'For the client');
    p = p.copyWith(
      items: [
        item('a', 'chb', 8000), // changed
        p.items[1], // the same
        item('d', 'pvc', 3000), // added; c is removed
      ],
      costs: const CostSettings(contingencyPct: 5, hauling: 2000),
    );
    final rev = p.revisions.single;
    final c = EstimateComparison.of(rev.applyTo(p), p);

    expect(c.added.single.after!.id, 'd');
    expect(c.added.single.beforeAmount, 0);
    expect(c.added.single.afterAmount, itemDirectCost(p.items[2], p.costs));
    expect(c.removed.single.before!.id, 'c');
    expect(c.removed.single.afterAmount, 0);
    expect(c.changed.single.before!.total, 10000);
    expect(c.changed.single.after!.total, 8000);
    expect(
      c.changed.single.afterAmount,
      lessThan(c.changed.single.beforeAmount),
    );
    expect(c.repriced, 0, reason: 'labour settings are the same');
    expect(c.generalChange, 2000);
    expect(c.totalChange, p.breakdown.total - rev.applyTo(p).breakdown.total);
    expect(
      c.directChange,
      closeTo(
        c.added.single.afterAmount -
            c.removed.single.beforeAmount +
            c.changed.single.afterAmount -
            c.changed.single.beforeAmount +
            c.generalChange,
        0.05,
      ),
      reason: 'the parts add up to the change in direct cost',
    );
    expect(c.settings, [
      (label: 'Hauling and delivery', before: '₱0.00', after: '₱2,000.00'),
      (label: 'Contingency', before: '10%', after: '5%'),
    ]);
    expect(c.isSame, isFalse);
    expect(EstimateComparison.of(p, p).isSame, isTrue);
  });

  test('settings changes include rates, labour and general requirements', () {
    const before = CostSettings();
    final after = before.copyWith(
      labourMethod: LabourMethod.percent,
      labourByTrade: {MaterialCategory.electrical.name: 25},
      rates: {'skilled': 1200},
      general: {'mobilization': 15000},
      monthly: {'security': 9000},
      vatPct: 12,
    );
    final labels = [for (final s in settingChanges(before, after)) s.label];
    expect(labels, [
      'Labour',
      'Labour, electrical works',
      'Daily rate, Skilled worker',
      'Mobilization and demobilization',
      'Watchman or security guard, a month',
      'VAT',
    ]);
    expect(settingChanges(before, after).first, (
      label: 'Labour',
      before: 'By crew output',
      after: '% of materials',
    ));
  });

  test('unchanged items repriced by new daily rates are counted apart', () {
    final spec = Estimate(
      id: 'w',
      materialId: 'chb',
      label: 'CHB 4"',
      quantity: 400,
      unit: QuantityUnit.blocks,
      unitPrice: 25,
      total: 10000,
      createdAt: DateTime(2026, 10, 9),
      works: const [EstimateWork('chb_4', 30)],
    );
    var p = Project.create('x').copyWith(items: [spec]);
    p = save(p, 'Before the new rates');
    p = p.copyWith(costs: p.costs.copyWith(rates: {'skilled': 1500}));
    final c = EstimateComparison.of(p.revisions.single.applyTo(p), p);
    expect(c.changed, isEmpty);
    expect(c.repriced, greaterThan(0));
    expect(c.settings.single.label, 'Daily rate, Skilled worker');
  });
}
