import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/project_repository.dart';
import 'package:thesismob/data/quotes.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/projects_controller.dart';

Estimate estimate(String id, double total) => Estimate(
  id: id,
  materialId: 'chb',
  label: 'CHB 4"',
  quantity: total / 25,
  unit: QuantityUnit.blocks,
  unitPrice: 25,
  total: total,
  createdAt: DateTime(2026, 10, 9),
);

void main() {
  test('revisions are saved, restored and kept with the project', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = ProjectRepository(await SharedPreferences.getInstance());
    final c = ProjectsController(repo);
    final id = c.active.id;
    c.add(estimate('a', 1000));
    c.add(estimate('b', 2000));
    c.saveRevision(id, '  For the client  ');
    expect(c.active.revisions.single.note, 'For the client');

    c.removeItem('b');
    c.updateCosts(id, CostSettings.contractor);
    c.saveRevision(id, 'Without the second wall');
    expect(c.active.revisions.map((r) => r.number), [1, 2]);

    final first = c.active.revisions.first;
    c.setEstimate(id, items: first.items, costs: first.costs);
    expect(c.active.items.map((e) => e.id), ['a', 'b']);
    expect(c.active.costs, CostSettings.owner);

    c.updateRevisions(id, (list) => list.where((r) => r.number != 1).toList());
    final reloaded = ProjectsController(repo).active;
    expect(reloaded.revisions.single.number, 2);
    expect(reloaded.revisions.single.items.single.id, 'a');
    expect(reloaded.items, hasLength(2));
  });

  test('quotes are recorded and awarded', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = ProjectRepository(await SharedPreferences.getInstance());
    final c = ProjectsController(repo);
    final id = c.active.id;
    final q = BidQuote(
      id: 'q1',
      bidder: 'Reyes Builders',
      amount: 950000,
      date: DateTime(2026, 10, 1),
    );
    c.updateQuotes(id, (list) => [...list, q]);
    c.updateQuotes(id, (list) => awardQuote(list, 'q1'));
    final reloaded = ProjectsController(repo).active.quotes.single;
    expect(reloaded.bidder, 'Reyes Builders');
    expect(reloaded.awarded, isTrue);
  });
}
