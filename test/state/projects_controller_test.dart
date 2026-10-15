import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/project_repository.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/projects_controller.dart';

var _seq = 0;

Estimate estimate({double total = 100, String itemKey = 'chb_4'}) => Estimate(
  id: 'e${_seq++}',
  materialId: 'chb',
  label: 'CHB 4"',
  quantity: total / 25,
  unit: QuantityUnit.blocks,
  unitPrice: 25,
  total: total,
  createdAt: DateTime(2026, 10, 9),
  itemKey: itemKey,
  companions: const [
    EstimateLine(
      itemKey: 'cement_40kg',
      label: 'Portland cement, 40 kg',
      quantity: 10,
      unit: 'bags',
      unitPrice: 240,
    ),
  ],
);

Future<(ProjectsController, ProjectRepository)> setup([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final repo = ProjectRepository(await SharedPreferences.getInstance());
  return (ProjectsController(repo), repo);
}

void main() {
  test('there is always an active project', () async {
    final (c, repo) = await setup();
    expect(c.projects, hasLength(1));
    expect(c.active.name, 'My project');
    expect(repo.load(), hasLength(1), reason: 'persisted');

    final removed = c.delete(c.active.id)!;
    expect(c.projects, hasLength(1), reason: 'a fresh one replaces it');
    c.restore(removed.index, removed.project);
    expect(c.projects, hasLength(2));
  });

  test('a summary from an earlier version becomes "My project"', () async {
    final old = estimate(total: 9850);
    final (c, _) = await setup({
      'estimates_summary_v2': jsonEncode([old.toJson()]),
    });
    expect(c.active.name, 'My project');
    expect(c.active.items.single.total, 9850);
  });

  test('items are added once and can be removed and restored', () async {
    final (c, repo) = await setup();
    final a = estimate();
    final b = estimate();
    expect(c.add(a), isTrue);
    expect(c.add(a), isFalse);
    c.add(b);
    expect(c.contains(a.id), isTrue);
    expect(c.isInAnyProject(b.id), isTrue);

    final removed = c.removeItem(a.id)!;
    expect(removed.index, 0);
    c.restoreItem(removed.index, removed.estimate);
    expect(c.active.items.map((e) => e.id), [a.id, b.id]);

    final cleared = c.clearItems();
    expect(c.active.items, isEmpty);
    c.restoreItems(cleared);
    expect(c.active.items, hasLength(2));
    expect(repo.load().single.items, hasLength(2), reason: 'persisted');
  });

  test('new projects become active and keep their own items', () async {
    final (c, _) = await setup();
    final first = c.active;
    c.add(estimate());
    final second = c.create(
      '  Santos residence ',
      client: 'Maria Santos',
      costs: CostSettings.contractor,
    );
    expect(c.active.id, second.id);
    expect(c.active.name, 'Santos residence');
    expect(c.active.items, isEmpty);
    expect(c.active.costs.isContractorBid, isTrue);
    c.setActive(first.id);
    expect(c.active.items, hasLength(1));
  });

  test('a duplicate copies items under new ids', () async {
    final (c, _) = await setup();
    final e = estimate();
    c.add(e);
    final copy = c.duplicate(c.active.id);
    expect(copy.name, 'My project (copy)');
    expect(c.active.id, copy.id);
    expect(copy.items.single.id, isNot(e.id));
    expect(copy.items.single.total, e.total);
  });

  test('a price applies to main materials and companions alike', () async {
    final (c, _) = await setup();
    c.add(estimate(total: 100));
    c.add(estimate(total: 200, itemKey: 'cement_40kg'));
    c.setPrice(c.active.id, 'cement_40kg', 250);
    final [blocks, cement] = c.active.items;
    expect(blocks.total, 100, reason: 'blocks keep their price');
    expect(blocks.companions.single.total, 2500);
    expect(cement.unitPrice, 250);
    expect(cement.total, 8 * 250);
    expect(cement.companions.single.unitPrice, 250);
  });

  test('details and costs are saved', () async {
    final (c, repo) = await setup();
    final id = c.active.id;
    c.updateDetails(id, name: 'Garage', location: 'Cebu City');
    c.updateCosts(id, CostSettings.contractor);
    final saved = repo.load().single;
    expect(saved.name, 'Garage');
    expect(saved.location, 'Cebu City');
    expect(saved.costs, CostSettings.contractor);
  });

  test('a backup adds projects that are not already here', () async {
    final (c, _) = await setup();
    final mine = c.active;
    final other = Project.create('Warehouse');
    expect(c.import([mine, other]), 1);
    expect(c.projects, hasLength(2));
  });
}
