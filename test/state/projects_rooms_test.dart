import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project_repository.dart';
import 'package:thesismob/data/rooms.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/projects_controller.dart';

double _price(String key) => itemByKey(key)?.price ?? 0;

const _living = Room(
  id: 'lr',
  name: 'Living',
  level: 'Ground floor',
  length: 4,
  width: 5,
  openings: [RoomOpening.door()],
);

final _manual = Estimate(
  id: 'mine',
  materialId: 'chb',
  label: 'CHB 4"',
  quantity: 100,
  unit: QuantityUnit.blocks,
  unitPrice: 25,
  total: 2500,
  createdAt: DateTime(2026, 10, 1),
);

Future<(ProjectsController, ProjectRepository)> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final repo = ProjectRepository(await SharedPreferences.getInstance());
  return (ProjectsController(repo), repo);
}

void main() {
  test('rooms are saved and fill in an empty floor area', () async {
    final (c, repo) = await _setup();
    final id = c.active.id;
    c.setRooms(id, [_living]);
    expect(c.active.rooms, [_living]);
    expect(c.active.floorArea, 20);
    expect(repo.load().single.rooms, [_living], reason: 'persisted');

    // It follows the rooms while it is still their total…
    c.setRooms(id, [_living, _living.copyWith(id: 'dr', name: 'Dining')]);
    expect(c.active.floorArea, 40);
    // …but not once the user has typed their own.
    c.updateDetails(id, floorArea: 55);
    c.setRooms(id, [_living]);
    expect(c.active.floorArea, 55);
  });

  test('updating finishes keeps the user\'s items and can be undone', () async {
    final (c, _) = await _setup();
    final id = c.active.id;
    c.add(_manual);
    c.setRooms(id, [_living]);

    final first = c.updateRoomFinishes(id, _price);
    expect(first.problems, isEmpty);
    expect(first.before, [_manual]);
    final items = c.active.items;
    expect(items.first, same(_manual));
    expect(items.where((e) => e.fromRooms), isNotEmpty);
    final floorId = items[1].id;

    c.setRooms(id, [_living.copyWith(length: 6)]);
    c.updateRoomFinishes(id, _price);
    expect(c.active.items.first, same(_manual));
    expect(c.active.items[1].id, floorId, reason: 'replaced in place');
    expect(c.active.items[1].area, 30);
    expect(
      roomFinishesUpToDate(c.active.rooms, c.active.items, priceOf: _price),
      isTrue,
    );

    final undo = c.updateRoomFinishes(id, (_) => 0);
    c.restoreItems(undo.before, projectId: id);
    expect(c.active.items, undo.before);
  });

  test('a duplicated finish becomes the user\'s own', () async {
    final (c, _) = await _setup();
    final id = c.active.id;
    c.setRooms(id, [_living]);
    c.updateRoomFinishes(id, _price);
    final generated = c.active.items.first;
    final copy = c.duplicateItem(generated.id)!;
    expect(copy.fromRooms, isFalse);
    expect(generated.fromRooms, isTrue);

    // Updating again leaves the copy alone.
    c.updateRoomFinishes(id, _price);
    expect(c.active.items.where((e) => e.id == copy.id), hasLength(1));
  });

  test('a duplicated project keeps its rooms', () async {
    final (c, _) = await _setup();
    c.setRooms(c.active.id, [_living]);
    final copy = c.duplicate(c.active.id);
    expect(copy.rooms, [_living]);
  });
}
