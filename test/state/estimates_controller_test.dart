import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/estimate_repository.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/estimates_controller.dart';

var _seq = 0;

Estimate estimate({
  double total = 100,
  Map<String, double>? inputs,
  DateTime? at,
}) => Estimate(
  id: 'e${_seq++}',
  materialId: 'chb',
  label: 'CHB 4"',
  quantity: 4,
  unit: QuantityUnit.blocks,
  unitPrice: total / 4,
  total: total,
  createdAt: at ?? DateTime(2026, 10, 9),
  inputs: inputs ?? {'length': total},
);

Future<(EstimatesController, EstimateRepository)> setup() async {
  SharedPreferences.setMockInitialValues({});
  final repo = EstimateRepository(await SharedPreferences.getInstance());
  return (EstimatesController(repo), repo);
}

void main() {
  test(
    'recording the same calculation twice keeps one history entry',
    () async {
      final (c, _) = await setup();
      final first = c.record(estimate(inputs: {'length': 10}));
      final again = c.record(estimate(inputs: {'length': 10}));
      expect(again.id, first.id);
      expect(c.history, hasLength(1));
      c.record(estimate(inputs: {'length': 11}));
      expect(c.history, hasLength(2));
      expect(c.history.first.inputs['length'], 11, reason: 'newest first');
    },
  );

  test('history is capped', () async {
    final (c, _) = await setup();
    for (var i = 0; i < EstimatesController.historyLimit + 5; i++) {
      c.record(estimate(inputs: {'i': i.toDouble()}));
    }
    expect(c.history, hasLength(EstimatesController.historyLimit));
  });

  test('summary only grows on purpose and never duplicates', () async {
    final (c, repo) = await setup();
    final e = c.record(estimate(total: 9375));
    expect(
      c.summary,
      isEmpty,
      reason: 'calculating must not add to the summary',
    );
    expect(c.addToSummary(e), isTrue);
    expect(c.addToSummary(e), isFalse);
    expect(c.summary, hasLength(1));
    expect(c.isInSummary(e.id), isTrue);
    expect(repo.loadSummary(), hasLength(1), reason: 'persisted');
  });

  test(
    'total is summed from numbers, including large and decimal values',
    () async {
      final (c, _) = await setup();
      c.addToSummary(estimate(total: 1000));
      c.addToSummary(estimate(total: 15000000));
      c.addToSummary(estimate(total: 1250.5));
      expect(c.summaryTotal, 15002250.5);

      // Removing any item, in any order, keeps the total right.
      c.removeFromSummary(c.summary[2].id);
      c.removeFromSummary(c.summary[1].id);
      expect(c.summaryTotal, 1000);

      c.addToSummary(estimate(total: 0.1));
      c.addToSummary(estimate(total: 0.2));
      expect(c.summaryTotal, 1000.3);
    },
  );

  test('removed items can be restored in place', () async {
    final (c, _) = await setup();
    final items = [estimate(), estimate(), estimate()];
    items.forEach(c.addToSummary);
    final removed = c.removeFromSummary(items[1].id)!;
    expect(removed.index, 1);
    c.restoreToSummary(removed.index, removed.estimate);
    expect(c.summary.map((e) => e.id), items.map((e) => e.id));
  });

  test('clearing can be undone', () async {
    final (c, _) = await setup();
    c.record(estimate(inputs: {'a': 1}));
    c.record(estimate(inputs: {'a': 2}));
    final cleared = c.clearHistory();
    expect(c.history, isEmpty);
    c.restoreHistory(cleared);
    expect(c.history, hasLength(2));
  });

  test('loads saved history newest first', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = EstimateRepository(await SharedPreferences.getInstance());
    await repo.saveHistory([
      estimate(at: DateTime(2026, 1, 1)),
      estimate(at: DateTime(2026, 3, 1)),
    ]);
    final c = EstimatesController(repo);
    expect(c.history.first.createdAt, DateTime(2026, 3, 1));
  });

  test('notifies listeners on change', () async {
    final (c, _) = await setup();
    var calls = 0;
    c.addListener(() => calls++);
    final e = c.record(estimate());
    c.addToSummary(e);
    c.removeFromSummary(e.id);
    expect(calls, 3);
  });
}
