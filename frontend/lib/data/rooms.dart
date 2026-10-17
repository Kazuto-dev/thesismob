import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../materials/catalog.dart';
import '../materials/items_finishes.dart';
import 'estimate.dart';

// The room schedule: each room entered once, with its size, openings and
// finishes. Rooms on the same level that share a finish become one
// estimate made with the finish's own calculator, so the bill of
// quantities stays short. See docs/calculations.md, "Room schedule".

double _round(double value, int places) {
  final f = math.pow(10, places).toDouble();
  return (value * f).roundToDouble() / f;
}

double _ceil(double value, int places) {
  final f = math.pow(10, places).toDouble();
  return ((value * f) - 1e-9).ceilToDouble() / f;
}

double? _positive(Object? value) =>
    value is num && value.isFinite && value > 0 ? value.toDouble() : null;

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

/// What covers a room's floor.
enum FloorFinish {
  none('None'),
  tiles('Tiles'),
  spc('SPC or vinyl planks'),
  laminate('Laminated wood planks'),
  topping('Cement topping'),
  carpet('Carpet');

  const FloorFinish(this.label);

  final String label;

  /// Whether a skirting runs round the walls: tile strips cut from the
  /// floor tiles, or trims for planks.
  bool get takesSkirting => this == tiles || this == spc || this == laminate;
}

/// What covers a room's walls.
enum WallFinish {
  none('None'),
  paint('Paint'),
  tiles('Tiles, paint above');

  const WallFinish(this.label);

  final String label;
}

/// The ceiling boards, if any.
enum CeilingFinish {
  none('No boards'),
  fiberCement('Fiber cement board'),
  gypsum('Gypsum board');

  const CeilingFinish(this.label);

  final String label;

  /// The ceiling calculator's board option.
  String get board => this == gypsum ? 'gypsum_board' : 'fiber_cement_board';
}

enum OpeningKind {
  door('Door'),
  window('Window');

  const OpeningKind(this.label);

  final String label;
}

/// Doors or windows of one size in a room's walls, left out of the wall
/// finishes. A door between two rooms is entered in both, since each room
/// finishes its own face of the wall.
@immutable
class RoomOpening {
  const RoomOpening({
    required this.kind,
    required this.width,
    required this.height,
    this.sill = 0,
    this.count = 1,
  });

  /// A usual door, 0.80 × 2.10 m.
  const RoomOpening.door({this.width = 0.8, this.height = 2.1, this.count = 1})
    : kind = OpeningKind.door,
      sill = 0;

  /// A usual window, 1.20 × 1.20 m on a 0.90 m sill.
  const RoomOpening.window({
    this.width = 1.2,
    this.height = 1.2,
    this.sill = 0.9,
    this.count = 1,
  }) : kind = OpeningKind.window;

  factory RoomOpening.fromJson(Map<String, dynamic> json) {
    final kind = _byName(OpeningKind.values, json['kind'], OpeningKind.door);
    final count = json['count'];
    return RoomOpening(
      kind: kind,
      width: _positive(json['width']) ?? 0,
      height: _positive(json['height']) ?? 0,
      sill: kind == OpeningKind.door ? 0 : _positive(json['sill']) ?? 0,
      count: count is num && count.isFinite && count >= 1 ? count.round() : 1,
    );
  }

  final OpeningKind kind;
  final double width;
  final double height;

  /// Height of the bottom of the opening above the floor; 0 for doors.
  final double sill;
  final int count;

  bool get isDoor => kind == OpeningKind.door;

  /// The area of these openings between [from] and [to] metres above the
  /// floor, e.g. the part of a window inside a band of wall tiles.
  double areaBetween(double from, double to) {
    final overlap = math.min(sill + height, to) - math.max(sill, from);
    return overlap <= 0 ? 0 : count * width * overlap;
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'width': width,
    'height': height,
    if (!isDoor) 'sill': sill,
    'count': count,
  };

  @override
  bool operator ==(Object other) =>
      other is RoomOpening &&
      other.kind == kind &&
      other.width == width &&
      other.height == height &&
      other.sill == sill &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, width, height, sill, count);
}

/// One room of the room schedule: where it is, its size, its doors and
/// windows, and the finishes of its floor, walls and ceiling.
@immutable
class Room {
  const Room({
    required this.id,
    required this.name,
    this.level = '',
    this.length,
    this.width,
    this.area,
    this.perimeter,
    this.height = defaultHeight,
    this.openings = const [],
    this.floor = FloorFinish.tiles,
    this.floorTile = '60x60',
    this.skirting = true,
    this.wall = WallFinish.paint,
    this.wallTile = '30x30',
    this.tileHeight = defaultTileHeight,
    this.ceiling = CeilingFinish.fiberCement,
    this.paintCeiling = true,
    this.lights = 0,
    this.outlets = 0,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) throw FormatException('Room has no id', json);
    String text(String key, String fallback) =>
        json[key] is String ? json[key] as String : fallback;
    int count(String key) {
      final v = json[key];
      return v is num && v.isFinite && v > 0 ? v.round() : 0;
    }

    String tile(String key, String fallback) {
      final size = json[key];
      return tileSizes.any((t) => t.id == size) ? size as String : fallback;
    }

    return Room(
      id: id,
      name: text('name', ''),
      level: text('level', ''),
      length: _positive(json['length']),
      width: _positive(json['width']),
      area: _positive(json['area']),
      perimeter: _positive(json['perimeter']),
      height: _positive(json['height']) ?? defaultHeight,
      openings: List.unmodifiable([
        for (final o in json['openings'] as List? ?? const [])
          if (o is Map<String, dynamic>) RoomOpening.fromJson(o),
      ]),
      floor: _byName(FloorFinish.values, json['floor'], FloorFinish.none),
      floorTile: tile('floorTile', '60x60'),
      skirting: json['skirting'] != false,
      wall: _byName(WallFinish.values, json['wall'], WallFinish.none),
      wallTile: tile('wallTile', '30x30'),
      tileHeight: _positive(json['tileHeight']) ?? defaultTileHeight,
      ceiling: _byName(
        CeilingFinish.values,
        json['ceiling'],
        CeilingFinish.none,
      ),
      paintCeiling: json['paintCeiling'] == true,
      lights: count('lights'),
      outlets: count('outlets'),
    );
  }

  /// The usual floor-to-ceiling height of a Philippine house.
  static const defaultHeight = 2.7;

  /// Wall tiles in a bathroom or kitchen usually go up to here.
  static const defaultTileHeight = 1.5;

  final String id;
  final String name;

  /// The floor or level, such as "Ground floor". Rooms on the same level
  /// share estimates.
  final String level;

  /// Length and width of a rectangular room, in metres.
  final double? length;
  final double? width;

  /// Floor area of a room that is not a rectangle, in m².
  final double? area;

  /// Length of the walls of a room that is not a rectangle, in metres.
  final double? perimeter;

  /// Floor to ceiling, in metres.
  final double height;
  final List<RoomOpening> openings;

  final FloorFinish floor;

  /// Tile size id of the floor tiles, from [tileSizes].
  final String floorTile;

  /// Whether the floor finish runs a skirting round the walls.
  final bool skirting;

  final WallFinish wall;

  /// Tile size id of the wall tiles.
  final String wallTile;

  /// How high the wall tiles go; at or above [height] they cover the wall.
  final double tileHeight;

  final CeilingFinish ceiling;

  /// Whether the ceiling, boards or slab, is painted.
  final bool paintCeiling;

  /// Light points and convenience outlets.
  final int lights;
  final int outlets;

  bool get isRectangle => (length ?? 0) > 0 && (width ?? 0) > 0;

  /// Floor area in m².
  double get floorArea => isRectangle ? length! * width! : (area ?? 0);

  /// Whether the wall length is a guess: a room given by its area alone
  /// is taken as a square.
  bool get perimeterGuessed => !isRectangle && (perimeter ?? 0) <= 0;

  /// Length of the walls round the room, in metres.
  double get wallLength {
    if ((perimeter ?? 0) > 0) return perimeter!;
    if (isRectangle) return 2 * (length! + width!);
    return 4 * math.sqrt(floorArea);
  }

  /// The area of the doors and windows between [from] and [to] metres
  /// above the floor.
  double openingsBetween(double from, double to) =>
      openings.fold(0, (sum, o) => sum + o.areaBetween(from, to));

  /// Total width of the doors, where the skirting stops.
  double get doorWidths => openings
      .where((o) => o.isDoor)
      .fold(0, (sum, o) => sum + o.width * o.count);

  int get doors =>
      openings.where((o) => o.isDoor).fold(0, (sum, o) => sum + o.count);

  /// The walls' area less the doors and windows, whatever covers them.
  double get wallArea =>
      math.max(0, wallLength * height - openingsBetween(0, height));

  /// How high the wall tiles go, up to the ceiling; 0 without them.
  double get tiledHeight =>
      wall == WallFinish.tiles ? math.min(tileHeight, height) : 0;

  /// Whether the tiles cover the walls up to the ceiling.
  bool get tiledFullHeight => wall == WallFinish.tiles && tileHeight >= height;

  /// Wall tiles, less the openings within their height.
  double get wallTileArea => wall == WallFinish.tiles
      ? math.max(0, wallLength * tiledHeight - openingsBetween(0, tiledHeight))
      : 0;

  /// How much of the wall's height is painted: all of it, the part above
  /// the tiles, or none.
  double get paintedHeight => switch (wall) {
    WallFinish.none => 0,
    WallFinish.paint => height,
    WallFinish.tiles => math.max(0, height - tiledHeight),
  };

  /// The painted band of the walls, openings included.
  double get grossPaintArea => wallLength * paintedHeight;

  /// The doors and windows within the painted band.
  double get paintOpenings =>
      paintedHeight <= 0 ? 0 : openingsBetween(height - paintedHeight, height);

  /// Wall paint, less the openings within the painted band.
  double get wallPaintArea => math.max(0, grossPaintArea - paintOpenings);

  /// Ceiling to board or paint, in m².
  double get ceilingArea =>
      ceiling != CeilingFinish.none || paintCeiling ? floorArea : 0;

  /// Whether a skirting is needed: the floor takes one and the walls are
  /// not tiled from the floor.
  bool get hasSkirting =>
      skirting && floor.takesSkirting && wall != WallFinish.tiles;

  /// Skirting length: round the walls, less the doors.
  double get skirtingLength =>
      hasSkirting ? math.max(0, wallLength - doorWidths) : 0;

  /// A copy with changes. Pass 0 as [length], [width], [area] or
  /// [perimeter] to clear it.
  Room copyWith({
    String? id,
    String? name,
    String? level,
    double? length,
    double? width,
    double? area,
    double? perimeter,
    double? height,
    List<RoomOpening>? openings,
    FloorFinish? floor,
    String? floorTile,
    bool? skirting,
    WallFinish? wall,
    String? wallTile,
    double? tileHeight,
    CeilingFinish? ceiling,
    bool? paintCeiling,
    int? lights,
    int? outlets,
  }) {
    double? keep(double? value, double? current) =>
        value == null ? current : (value > 0 ? value : null);
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      length: keep(length, this.length),
      width: keep(width, this.width),
      area: keep(area, this.area),
      perimeter: keep(perimeter, this.perimeter),
      height: height ?? this.height,
      openings: openings ?? this.openings,
      floor: floor ?? this.floor,
      floorTile: floorTile ?? this.floorTile,
      skirting: skirting ?? this.skirting,
      wall: wall ?? this.wall,
      wallTile: wallTile ?? this.wallTile,
      tileHeight: tileHeight ?? this.tileHeight,
      ceiling: ceiling ?? this.ceiling,
      paintCeiling: paintCeiling ?? this.paintCeiling,
      lights: lights ?? this.lights,
      outlets: outlets ?? this.outlets,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (level.isNotEmpty) 'level': level,
    if (length != null) 'length': length,
    if (width != null) 'width': width,
    if (area != null) 'area': area,
    if (perimeter != null) 'perimeter': perimeter,
    'height': height,
    if (openings.isNotEmpty) 'openings': [for (final o in openings) o.toJson()],
    'floor': floor.name,
    'floorTile': floorTile,
    'skirting': skirting,
    'wall': wall.name,
    'wallTile': wallTile,
    'tileHeight': tileHeight,
    'ceiling': ceiling.name,
    'paintCeiling': paintCeiling,
    if (lights > 0) 'lights': lights,
    if (outlets > 0) 'outlets': outlets,
  };

  @override
  bool operator ==(Object other) =>
      other is Room &&
      other.id == id &&
      other.name == name &&
      other.level == level &&
      other.length == length &&
      other.width == width &&
      other.area == area &&
      other.perimeter == perimeter &&
      other.height == height &&
      listEquals(other.openings, openings) &&
      other.floor == floor &&
      other.floorTile == floorTile &&
      other.skirting == skirting &&
      other.wall == wall &&
      other.wallTile == wallTile &&
      other.tileHeight == tileHeight &&
      other.ceiling == ceiling &&
      other.paintCeiling == paintCeiling &&
      other.lights == lights &&
      other.outlets == outlets;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    level,
    length,
    width,
    area,
    perimeter,
    height,
    Object.hashAll(openings),
    floor,
    floorTile,
    skirting,
    wall,
    wallTile,
    tileHeight,
    ceiling,
    paintCeiling,
    lights,
    outlets,
  ]);
}

/// Parses a project's saved rooms, skipping any that are damaged.
List<Room> roomsFromJson(Object? json) {
  final rooms = <Room>[];
  for (final raw in json is List ? json : const []) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      rooms.add(Room.fromJson(raw));
    } on FormatException {
      // Skip a damaged room rather than losing the project.
    }
  }
  return List.unmodifiable(rooms);
}

/// The rooms' totals, in m² and metres.
typedef RoomTotals = ({
  double floor,
  double walls,
  double ceilings,
  double skirting,
});

RoomTotals roomTotals(List<Room> rooms) {
  double sum(double Function(Room) of) =>
      _round(rooms.fold(0, (s, r) => s + of(r)), 2);
  return (
    floor: sum((r) => r.floorArea),
    walls: sum((r) => r.wallArea),
    ceilings: sum((r) => r.ceilingArea),
    skirting: sum((r) => r.skirtingLength),
  );
}

/// Which part of the rooms a finish covers.
enum FinishPart {
  floor('floors'),
  wallTiles('walls'),
  wallPaint('walls'),
  ceiling('ceilings'),
  ceilingPaint('ceilings'),
  lights('lights'),
  outlets('outlets');

  const FinishPart(this.place);

  /// Where it goes, for the estimate's name.
  final String place;
}

/// Marks the [Estimate.source] of an estimate made from the rooms.
const roomSourcePrefix = 'rooms:';

extension RoomEstimate on Estimate {
  /// Whether the room schedule made this estimate and keeps it up to date.
  bool get fromRooms => source?.startsWith(roomSourcePrefix) ?? false;
}

/// One finish shared by rooms on one level, which becomes one estimate:
/// e.g. the 60 × 60 cm floor tiles of the living room, dining room and
/// kitchen on the ground floor.
@immutable
class FinishGroup {
  const FinishGroup({
    required this.level,
    required this.part,
    required this.variant,
    required this.rooms,
  });

  /// The level as the first room spells it; empty when not given.
  final String level;
  final FinishPart part;

  /// The kind of finish, e.g. a tile size or a board; empty when there is
  /// only one kind.
  final String variant;
  final List<Room> rooms;

  /// The [Estimate.source] of this group's estimate.
  String get source =>
      '$roomSourcePrefix${level.trim().toLowerCase()}|${part.name}'
      '${variant.isEmpty ? '' : ':$variant'}';

  /// The calculator that estimates this finish.
  String get materialId => switch (part) {
    FinishPart.floor => switch (variant) {
      'carpet' => 'carpet',
      'spc' || 'laminate' || 'topping' => 'flooring',
      _ => 'tiles',
    },
    FinishPart.wallTiles => 'tiles',
    FinishPart.wallPaint || FinishPart.ceilingPaint => 'paint',
    FinishPart.ceiling => 'ceiling',
    FinishPart.lights => 'bulb',
    FinishPart.outlets => 'outlet',
  };

  /// The estimate's mark, e.g. "Ground floor, walls".
  String get mark {
    final place = part.place;
    return level.isEmpty
        ? '${place[0].toUpperCase()}${place.substring(1)}'
        : '$level, $place';
  }

  /// The estimate's note: the rooms it covers.
  String get note {
    String name(Room r) => r.name.trim().isEmpty ? 'Unnamed room' : r.name;
    String detail(Room r) => switch (part) {
      FinishPart.wallTiles =>
        r.tiledFullHeight
            ? '${name(r)} (full height)'
            : '${name(r)} (to ${_round(r.tiledHeight, 2)} m)',
      FinishPart.lights => '${name(r)} (${r.lights})',
      FinishPart.outlets => '${name(r)} (${r.outlets})',
      _ => name(r),
    };
    return 'Rooms: ${rooms.map(detail).join(', ')}.';
  }

  double _sum(double Function(Room) of) => rooms.fold(0, (s, r) => s + of(r));

  /// A length and width for the rooms' floor: the room's own when there is
  /// one rectangular room, otherwise a square of the same area. Tiles and
  /// boards are counted from the area, with the calculator's waste
  /// allowance for the cuts.
  (double, double) get _floorSize {
    if (rooms.length == 1 && rooms.single.isRectangle) {
      return (rooms.single.length!, rooms.single.width!);
    }
    final area = _sum((r) => r.floorArea);
    final side = math.max(_round(math.sqrt(area), 3), 0.001);
    return (_ceil(area / side, 3), side);
  }

  /// The measurements this group gives its calculator, by field id.
  /// Fields the calculator leaves optional are left out at 0.
  Map<String, double> get inputs {
    final (length, width) = _floorSize;
    switch (part) {
      case FinishPart.floor:
        final skirting = _round(_sum((r) => r.skirtingLength), 2);
        final planks = variant == 'spc' || variant == 'laminate';
        final doorways = rooms.fold(0, (s, r) => s + r.doors);
        return {
          'length': length,
          'width': width,
          if ((materialId == 'tiles' || planks) && skirting > 0)
            'skirting': skirting,
          if (planks && doorways > 0) 'doorways': doorways.toDouble(),
        };
      case FinishPart.wallTiles:
        final height = _round(
          rooms.fold(0.0, (h, r) => math.max(h, r.tiledHeight)),
          3,
        );
        return {
          'length': _ceil(_sum((r) => r.wallTileArea) / height, 3),
          'width': height,
        };
      case FinishPart.wallPaint:
        final height = _round(
          rooms.fold(0.0, (h, r) => math.max(h, r.paintedHeight)),
          3,
        );
        final openings = _round(_sum((r) => r.paintOpenings), 2);
        return {
          'length': _ceil(_sum((r) => r.grossPaintArea) / height, 3),
          'height': height,
          if (openings > 0) 'openings': openings,
        };
      case FinishPart.ceiling:
        return {'length': length, 'width': width};
      case FinishPart.ceilingPaint:
        return {'length': length, 'height': width};
      case FinishPart.lights:
        return {'quantity': rooms.fold(0, (s, r) => s + r.lights).toDouble()};
      case FinishPart.outlets:
        return {'quantity': rooms.fold(0, (s, r) => s + r.outlets).toDouble()};
    }
  }

  /// Calculator fields the rooms measure, which an estimate made earlier
  /// does not keep.
  static const measured = {
    'length',
    'width',
    'height',
    'skirting',
    'doorways',
    'openings',
    'quantity',
  };

  /// The options the rooms set, by choice id. Other options keep what the
  /// user chose in the calculator, or the calculator's own.
  Map<String, String> get choices => switch (part) {
    FinishPart.floor => switch (materialId) {
      'flooring' => {'type': variant},
      'carpet' => const {},
      _ => {'size': variant},
    },
    FinishPart.wallTiles => {'size': variant},
    FinishPart.ceiling => {'board': variant},
    FinishPart.lights || FinishPart.outlets => const {'mode': 'count'},
    FinishPart.wallPaint || FinishPart.ceilingPaint => const {},
  };
}

/// The finishes of [rooms], grouped by level and finish, in the order the
/// levels first appear: floors, walls, ceilings, then lights and outlets.
List<FinishGroup> finishGroups(List<Room> rooms) {
  final levels = <String, String>{};
  for (final r in rooms) {
    levels.putIfAbsent(r.level.trim().toLowerCase(), () => r.level.trim());
  }
  final groups = <FinishGroup>[];
  for (final MapEntry(key: levelKey, value: level) in levels.entries) {
    final onLevel = [
      for (final r in rooms)
        if (r.level.trim().toLowerCase() == levelKey && r.floorArea > 0) r,
    ];
    final byKey = <(FinishPart, String), List<Room>>{};
    void add(FinishPart part, String variant, Room r) =>
        (byKey[(part, variant)] ??= []).add(r);
    for (final r in onLevel) {
      if (r.floor != FloorFinish.none) {
        add(
          FinishPart.floor,
          r.floor == FloorFinish.tiles ? r.floorTile : r.floor.name,
          r,
        );
      }
      if (r.wallTileArea > 0) add(FinishPart.wallTiles, r.wallTile, r);
      if (r.wallPaintArea > 0) add(FinishPart.wallPaint, '', r);
      if (r.ceiling != CeilingFinish.none) {
        add(FinishPart.ceiling, r.ceiling.board, r);
      }
      if (r.paintCeiling) add(FinishPart.ceilingPaint, '', r);
      if (r.lights > 0) add(FinishPart.lights, '', r);
      if (r.outlets > 0) add(FinishPart.outlets, '', r);
    }
    final keys = byKey.keys.toList()
      ..sort((a, b) => a.$1.index.compareTo(b.$1.index));
    for (final (part, variant) in keys) {
      groups.add(
        FinishGroup(
          level: level,
          part: part,
          variant: variant,
          rooms: List.unmodifiable(byKey[(part, variant)]!),
        ),
      );
    }
  }
  return groups;
}

/// The estimates the rooms make, with any finish that could not be worked
/// out and why.
typedef RoomFinishes = ({List<Estimate> estimates, List<String> problems});

/// Works out each finish group of [rooms] with its calculator, as the
/// calculator screen would. Each takes the place of the estimate made
/// earlier for the same group in [previous], keeping its id, the options
/// and prices the user set in the calculator, and its companions' prices;
/// only the measurements come from the rooms. New ones are priced with
/// [priceOf], the price book.
RoomFinishes roomFinishes(
  List<Room> rooms, {
  required double Function(String itemKey) priceOf,
  List<Estimate> previous = const [],
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final estimates = <Estimate>[];
  final problems = <String>[];
  for (final g in finishGroups(rooms)) {
    final spec = materialById(g.materialId);
    if (spec == null) continue;
    final before = previous.where((e) => e.source == g.source).firstOrNull;
    final wanted = {...spec.initialChoices, ...?before?.choices, ...g.choices};
    final choices = {
      for (final c in spec.visibleChoices(wanted))
        if (wanted[c.id] case final id? when c.option(id) != null) c.id: id,
    };
    final measured = g.inputs;
    final inputs = <String, double>{};
    for (final f in spec.visibleNumbers(choices)) {
      final value = FinishGroup.measured.contains(f.id)
          ? measured[f.id]
          : before?.inputs[f.id];
      if (value != null && value > 0) {
        inputs[f.id] = value;
      } else if (f.isPrice) {
        final ref = spec.priceRef?.call(choices);
        inputs[f.id] = ref == null
            ? 0
            : _round(priceOf(ref.itemKey) * ref.factor, 2);
      } else if (!f.optional && f.initial != null) {
        inputs[f.id] = double.parse(f.initial!);
      }
    }
    final linePrices = {
      for (final l in before?.companions ?? const <EstimateLine>[])
        l.itemKey: l.unitPrice,
    };
    try {
      final result = spec.calculate(inputs, choices);
      estimates.add(
        Estimate.fromResult(
          materialId: spec.id,
          result: result,
          inputs: inputs,
          choices: choices,
          priceOf: (key) => linePrices[key] ?? priceOf(key),
          createdAt: before?.createdAt ?? at,
        ).copyWith(
          id: before?.id,
          mark: g.mark,
          note: g.note,
          source: g.source,
        ),
      );
    } on ArgumentError catch (e) {
      problems.add('${g.mark}, ${spec.name}: ${e.message}');
    }
  }
  return (estimates: estimates, problems: problems);
}

/// [items] with the estimates made from the rooms replaced by [generated]:
/// each takes the place of the one it replaces, new ones go at the end,
/// ones no longer made are dropped, and the user's own items stay as
/// they are.
List<Estimate> withRoomFinishes(
  List<Estimate> items,
  List<Estimate> generated,
) {
  final bySource = {for (final e in generated) e.source: e};
  final placed = <String?>{};
  final result = <Estimate>[];
  for (final e in items) {
    if (!e.fromRooms) {
      result.add(e);
    } else if (bySource[e.source] case final g? when placed.add(e.source)) {
      result.add(g);
    }
  }
  result.addAll(generated.where((g) => !placed.contains(g.source)));
  return List.unmodifiable(result);
}

/// Whether [items] already hold exactly the estimates [rooms] make, with
/// the same measurements and options.
bool roomFinishesUpToDate(
  List<Room> rooms,
  List<Estimate> items, {
  required double Function(String itemKey) priceOf,
}) {
  final current = items.where((e) => e.fromRooms).toList();
  final fresh = roomFinishes(rooms, priceOf: priceOf, previous: items);
  if (fresh.estimates.length != current.length) return false;
  for (final e in fresh.estimates) {
    final old = current.where((c) => c.source == e.source).firstOrNull;
    if (old == null ||
        !old.sameCalculationAs(e) ||
        old.note != e.note ||
        old.mark != e.mark) {
      return false;
    }
  }
  return true;
}
