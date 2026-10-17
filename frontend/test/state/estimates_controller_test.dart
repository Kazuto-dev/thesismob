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

  test('an entry can be replaced in place and moved to the top', () async {
    final (c, repo) = await setup();
    final a = c.record(estimate(inputs: {'length': 1}));
    c.record(estimate(inputs: {'length': 2}));
    final updated = c.replaceInHistory(a.id, estimate(total: 300));
    expect(updated!.id, a.id);
    expect(c.history.first.id, a.id);
    expect(c.history.first.total, 300);
    expect(c.history, hasLength(2));
    expect(repo.loadHistory().first.total, 300);
    expect(c.replaceInHistory('missing', estimate()), isNull);
  });

  test('history is capped', () async {
    final (c, _) = await setup();
    for (var i = 0; i < EstimatesController.historyLimit + 5; i++) {
      c.record(estimate(inputs: {'i': i.toDouble()}));
    }
    expect(c.history, hasLength(EstimatesController.historyLimit));
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
    c.removeFromHistory(e.id);
    expect(calls, 2);
  });

  test('a backup adds only entries that are not already here', () async {
    final (c, _) = await setup();
    final kept = c.record(estimate(inputs: {'a': 1}));
    final added = c.importHistory([
      kept,
      estimate(inputs: {'a': 2}, at: DateTime(2026, 12, 1)),
    ]);
    expect(added, 1);
    expect(c.history, hasLength(2));
    expect(c.history.first.createdAt, DateTime(2026, 12, 1));
  });
}
