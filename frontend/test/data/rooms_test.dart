import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/rooms.dart';
import 'package:thesismob/materials/architectural.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';

double _price(String key) => itemByKey(key)?.price ?? 0;

/// A 2 × 1.5 m toilet tiled to 1.5 m with paint above, a door and a
/// small window high up.
const toilet = Room(
  id: 'tb',
  name: 'T&B',
  level: 'Ground floor',
  length: 2,
  width: 1.5,
  openings: [
    RoomOpening.door(width: 0.7),
    RoomOpening.window(width: 0.6, height: 0.6, sill: 1.5),
  ],
  floorTile: '30x30',
  wall: WallFinish.tiles,
  wallTile: '20x30',
);

/// A 4 × 5 m living room: painted walls, a door and two windows.
const living = Room(
  id: 'lr',
  name: 'Living',
  level: 'Ground floor',
  length: 4,
  width: 5,
  openings: [RoomOpening.door(width: 0.9), RoomOpening.window(count: 2)],
  lights: 3,
  outlets: 4,
);

void main() {
  group('room geometry', () {
    test('a painted room leaves its doors and windows out', () {
      expect(living.floorArea, 20);
      expect(living.wallLength, 18);
      // 18 × 2.7 = 48.6, less a 0.9 × 2.1 door and two 1.2 × 1.2 windows.
      expect(living.wallArea, closeTo(48.6 - 1.89 - 2.88, 1e-9));
      expect(living.wallPaintArea, closeTo(living.wallArea, 1e-9));
      expect(living.wallTileArea, 0);
      expect(living.skirtingLength, closeTo(18 - 0.9, 1e-9));
    });

    test('wall tiles to a height take only the openings below it', () {
      // 7 m of wall. Tiles to 1.5 m: 10.5 m² less the door's 0.7 × 1.5;
      // the window starts at 1.5 m.
      expect(toilet.tiledHeight, 1.5);
      expect(toilet.wallTileArea, closeTo(10.5 - 1.05, 1e-9));
      // Paint from 1.5 to 2.7 m: 8.4 m² less the top 0.6 m of the door
      // and the whole window.
      expect(toilet.grossPaintArea, closeTo(8.4, 1e-9));
      expect(toilet.paintOpenings, closeTo(0.42 + 0.36, 1e-9));
      expect(toilet.wallPaintArea, closeTo(8.4 - 0.78, 1e-9));
      expect(
        toilet.wallTileArea + toilet.wallPaintArea,
        closeTo(toilet.wallArea, 1e-9),
      );
      expect(toilet.skirtingLength, 0, reason: 'the wall tiles reach down');
    });

    test('a window straddling the tile line is split between finishes', () {
      const kitchen = Room(
        id: 'k',
        name: 'Kitchen',
        length: 3,
        width: 3,
        height: 2.4,
        openings: [RoomOpening.window(width: 1, height: 1, sill: 1)],
        wall: WallFinish.tiles,
        tileHeight: 1.2,
      );
      // 0.2 m of the window is below 1.2 m, 0.8 m above.
      expect(kitchen.wallTileArea, closeTo(12 * 1.2 - 0.2, 1e-9));
      expect(kitchen.wallPaintArea, closeTo(12 * 1.2 - 0.8, 1e-9));
    });

    test('tiles at the ceiling height or above cover the whole wall', () {
      final full = toilet.copyWith(tileHeight: 3, openings: const []);
      expect(full.tiledFullHeight, isTrue);
      expect(full.tiledHeight, 2.7);
      expect(full.wallTileArea, closeTo(7 * 2.7, 1e-9));
      expect(full.wallPaintArea, 0);
    });

    test('a room given by its area uses its wall length, or a square', () {
      const odd = Room(id: 'o', name: 'Hall', area: 16, perimeter: 20);
      expect(odd.isRectangle, isFalse);
      expect(odd.floorArea, 16);
      expect(odd.wallLength, 20);
      expect(odd.perimeterGuessed, isFalse);
      const guessed = Room(id: 'g', name: 'Hall', area: 16);
      expect(guessed.wallLength, 16, reason: 'a 4 × 4 m square');
      expect(guessed.perimeterGuessed, isTrue);
    });

    test('totals add up the rooms', () {
      final t = roomTotals([living, toilet]);
      expect(t.floor, 23);
      expect(t.walls, closeTo(living.wallArea + toilet.wallArea, 0.01));
      expect(t.ceilings, 23);
      expect(t.skirting, closeTo(17.1, 1e-9));
    });
  });

  group('grouping', () {
    test('rooms sharing a finish on a level share one group', () {
      final dining = living.copyWith(id: 'dr', name: 'Dining');
      final bedroom = living.copyWith(
        id: 'br',
        name: 'Bedroom',
        level: 'Second floor',
        floor: FloorFinish.spc,
        lights: 0,
        outlets: 0,
      );
      final groups = finishGroups([living, toilet, dining, bedroom]);
      String describe(FinishGroup g) =>
          '${g.mark} ${g.part.name}${g.variant.isEmpty ? '' : ' ${g.variant}'}'
          ': ${g.rooms.map((r) => r.name).join(', ')}';
      expect(groups.map(describe), [
        'Ground floor, floors floor 60x60: Living, Dining',
        'Ground floor, floors floor 30x30: T&B',
        'Ground floor, walls wallTiles 20x30: T&B',
        'Ground floor, walls wallPaint: Living, T&B, Dining',
        'Ground floor, ceilings ceiling fiber_cement_board: Living, T&B, Dining',
        'Ground floor, ceilings ceilingPaint: Living, T&B, Dining',
        'Ground floor, lights lights: Living, Dining',
        'Ground floor, outlets outlets: Living, Dining',
        'Second floor, floors floor spc: Bedroom',
        'Second floor, walls wallPaint: Bedroom',
        'Second floor, ceilings ceiling fiber_cement_board: Bedroom',
        'Second floor, ceilings ceilingPaint: Bedroom',
      ]);
      expect(groups.first.note, 'Rooms: Living, Dining.');
      expect(groups[2].note, 'Rooms: T&B (to 1.5 m).');
      expect(groups[6].note, 'Rooms: Living (3), Dining (3).');
    });

    test('levels match whatever their case and spacing', () {
      final other = living.copyWith(id: 'x', level: ' ground FLOOR ');
      final groups = finishGroups([living, other]);
      expect(groups.first.rooms, hasLength(2));
      expect(groups.first.mark, 'Ground floor, floors');
    });

    test('rooms without a level are named by the part alone', () {
      final g = finishGroups([living.copyWith(level: '')]).first;
      expect(g.mark, 'Floors');
    });
  });

  group('estimates from rooms', () {
    test('a single room gives its calculator its own size', () {
      final made = roomFinishes([living], priceOf: _price);
      expect(made.problems, isEmpty);
      final floor = made.estimates.first;
      expect(floor.materialId, 'tiles');
      expect(floor.fromRooms, isTrue);
      expect(floor.inputs, {
        'length': 4,
        'width': 5,
        'skirting': 17.1,
        'price': _price('tile_60x60'),
      });
      expect(floor.choices['size'], '60x60');
      expect(floor.title, 'Ground floor, floors – Tiles 60 × 60 cm');
      expect(floor.note, 'Rooms: Living.');
      // The same as working it out in the tiles calculator.
      final direct = tiles.calculate(floor.inputs, floor.choices);
      expect(floor.quantity, direct.quantity);
      expect(floor.unitPrice, _price('tile_60x60'));
      expect(floor.companions, isNotEmpty);
    });

    test('grouped rooms are measured as one area', () {
      final dining = living.copyWith(id: 'dr', name: 'Dining', width: 3);
      final made = roomFinishes([living, dining], priceOf: _price);
      final floor = made.estimates.first;
      final l = floor.inputs['length']!;
      final w = floor.inputs['width']!;
      expect(l * w, closeTo(32, 0.01));
      expect(floor.area, closeTo(32, 0.01));
      expect(floor.inputs['skirting'], closeTo(17.1 + 13.1, 1e-9));

      final paint = made.estimates.firstWhere(
        (e) => e.source!.endsWith('wallPaint'),
      );
      expect(paint.inputs['height'], 2.7);
      expect(paint.inputs['length'], closeTo(18 + 14, 1e-6));
      expect(paint.inputs['openings'], closeTo(2 * (1.89 + 2.88), 0.01));
      expect(
        paint.area,
        closeTo(living.wallPaintArea + dining.wallPaintArea, 0.01),
      );

      final lights = made.estimates.firstWhere((e) => e.materialId == 'bulb');
      expect(lights.quantity, 6);
      expect(lights.choices['mode'], 'count');
      final outlets = made.estimates.firstWhere(
        (e) => e.materialId == 'outlet',
      );
      expect(outlets.quantity, 8);
    });

    test('wall tiles and paint above follow the tile height', () {
      final made = roomFinishes([toilet], priceOf: _price);
      final walls = made.estimates.firstWhere(
        (e) => e.source!.contains('wallTiles'),
      );
      expect(walls.inputs['width'], 1.5);
      expect(walls.area, closeTo(9.45, 0.01));
      expect(walls.choices['size'], '20x30');
      final paint = made.estimates.firstWhere(
        (e) => e.source!.endsWith('wallPaint'),
      );
      expect(paint.inputs['height'], closeTo(1.2, 1e-9));
      expect(paint.area, closeTo(7.62, 0.01));
    });

    test('plank floors get trims and a doorway each', () {
      final made = roomFinishes([
        living.copyWith(floor: FloorFinish.spc),
      ], priceOf: _price);
      final floor = made.estimates.first;
      expect(floor.materialId, 'flooring');
      expect(floor.choices['type'], 'spc');
      expect(floor.inputs['skirting'], closeTo(17.1, 1e-9));
      expect(floor.inputs['doorways'], 1);
    });
  });

  group('updating from rooms', () {
    final manual = Estimate.fromResult(
      materialId: 'paint',
      result: paint.calculate({
        'length': 10,
        'height': 3,
        'price': 900,
      }, paint.initialChoices),
      inputs: const {'length': 10, 'height': 3, 'price': 900},
      choices: paint.initialChoices,
    ).copyWith(mark: 'Fence');

    test('the first update adds the finishes after the user\'s items', () {
      final made = roomFinishes([living], priceOf: _price).estimates;
      final items = withRoomFinishes([manual], made);
      expect(items.first, same(manual));
      expect(items.skip(1).map((e) => e.id), made.map((e) => e.id));
    });

    test('updating replaces only the estimates made from rooms', () {
      final first = roomFinishes([living], priceOf: _price).estimates;
      final items = withRoomFinishes(
        [first.first, manual, ...first.skip(1)],
        [...first],
      );
      // The living room grows and loses its outlets.
      final bigger = living.copyWith(length: 6, outlets: 0);
      final again = roomFinishes(
        [bigger],
        priceOf: _price,
        previous: items,
      ).estimates;
      final updated = withRoomFinishes(items, again);

      expect(updated[1], same(manual), reason: 'left where it was');
      expect(updated.first.id, first.first.id, reason: 'keeps its id');
      expect(updated.first.area, 30);
      expect(
        updated.where((e) => e.materialId == 'outlet'),
        isEmpty,
        reason: 'no longer made',
      );
      expect(updated.where((e) => e.fromRooms), hasLength(again.length));
      expect(roomFinishesUpToDate([bigger], updated, priceOf: _price), isTrue);
      expect(roomFinishesUpToDate([living], updated, priceOf: _price), isFalse);
    });

    test('options and prices set in the calculator are kept', () {
      final first = roomFinishes([living], priceOf: _price).estimates.first;
      // The user opens the floor tiles and lays them diagonally at ₱200.
      final choices = {...first.choices, 'layout': 'diagonal'};
      final inputs = {...first.inputs, 'price': 200.0};
      final edited =
          Estimate.fromResult(
            materialId: 'tiles',
            result: tiles.calculate(inputs, choices),
            inputs: inputs,
            choices: choices,
          ).copyWith(
            id: first.id,
            mark: first.mark,
            note: first.note,
            source: first.source,
          );
      final again = roomFinishes(
        [living.copyWith(width: 6)],
        priceOf: _price,
        previous: [edited],
      ).estimates.first;
      expect(again.id, first.id);
      expect(again.choices['layout'], 'diagonal');
      expect(again.unitPrice, 200);
      expect(again.inputs['width'], 6);
    });

    test('with no rooms left, their estimates go', () {
      final made = roomFinishes([living], priceOf: _price).estimates;
      final items = withRoomFinishes([manual, ...made], const []);
      expect(items, [manual]);
      expect(roomFinishesUpToDate(const [], items, priceOf: _price), isTrue);
    });
  });

  group('saving', () {
    test('a room survives a round trip through JSON', () {
      final room = toilet.copyWith(lights: 1, outlets: 2, paintCeiling: false);
      final back = Room.fromJson(
        jsonDecode(jsonEncode(room.toJson())) as Map<String, dynamic>,
      );
      expect(back, room);
      const shaped = Room(id: 's', name: 'Hall', area: 12.5, perimeter: 15);
      expect(Room.fromJson(shaped.toJson()), shaped);
    });

    test('damaged rooms and values are skipped', () {
      final rooms = roomsFromJson([
        {'name': 'No id'},
        'nonsense',
        {
          'id': 'r',
          'name': 'Odd',
          'length': -3,
          'height': 'tall',
          'floor': 'marble',
          'floorTile': '99x99',
          'openings': [
            {'kind': 'window', 'width': 1, 'height': 1, 'count': 0},
          ],
        },
      ]);
      expect(rooms, hasLength(1));
      final r = rooms.single;
      expect(r.length, isNull);
      expect(r.height, Room.defaultHeight);
      expect(r.floor, FloorFinish.none);
      expect(r.floorTile, '60x60');
      expect(r.openings.single.count, 1);
    });

    test('a project keeps its rooms, and older projects have none', () {
      final project = Project.create(
        'House',
        now: DateTime(2026, 10, 1),
      ).copyWith(rooms: [living, toilet]);
      final back = Project.fromJson(
        jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
      );
      expect(back.rooms, [living, toilet]);
      final old = project.toJson()..remove('rooms');
      expect(Project.fromJson(old).rooms, isEmpty);
    });

    test('an estimate keeps where it came from', () {
      final made = roomFinishes([living], priceOf: _price).estimates.first;
      final back = Estimate.fromJson(
        jsonDecode(jsonEncode(made.toJson())) as Map<String, dynamic>,
      );
      expect(back.source, made.source);
      expect(back.fromRooms, isTrue);
      expect(Estimate.fromJson(made.toJson()..remove('source')).source, null);
      expect(made.copyWith(source: '').fromRooms, isFalse);
      expect(made.withId('x').source, made.source);
    });

    test('estimates made by hand are never from rooms', () {
      final e = Estimate(
        id: 'e',
        materialId: 'chb',
        label: 'CHB 4"',
        quantity: 10,
        unit: QuantityUnit.blocks,
        unitPrice: 25,
        total: 250,
        createdAt: DateTime(2026, 10, 1),
      );
      expect(e.fromRooms, isFalse);
      expect(e.toJson().containsKey('source'), isFalse);
    });
  });
}
