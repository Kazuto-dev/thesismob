import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/architectural.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/openings.dart';
import 'package:thesismob/materials/work_items.dart';

final specs = [paint, tiles, roof, carpet, wallpaper, doors, windows];

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

/// Quantity of the companion bought from [itemKey], or null.
double? bought(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

/// Key, quantity and effort of each work a result measures, in order.
List<(String, double, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity, w.effort),
];

/// The work each companion goes into, by item key; null is the main work.
Map<String, String?> companionWorks(CalcResult r) => {
  for (final c in r.companions) c.itemKey: c.work,
};

/// Every combination of the choices that are visible for it.
List<Map<String, String>> combinations(MaterialSpec spec) {
  List<Map<String, String>> expand(Map<String, String> selected, int i) {
    if (i == spec.choices.length) return [selected];
    final field = spec.choices[i];
    if (!field.isVisible(selected)) return expand(selected, i + 1);
    return [
      for (final o in field.options)
        ...expand({...selected, field.id: o.id}, i + 1),
    ];
  }

  return expand({}, 0);
}

void main() {
  group('architectural specs', () {
    test('have definitions, a solution, references and search words', () {
      for (final m in specs) {
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.references, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
        expect(m.category, MaterialCategory.architectural, reason: m.id);
        expect(m.priceRef, isNotNull, reason: m.id);
      }
    });

    test('initial choices are valid options', () {
      for (final m in specs) {
        for (final c in m.choices) {
          if (c.initial != null) {
            expect(c.option(c.initial), isNotNull, reason: '${m.id}.${c.id}');
          }
        }
      }
    });

    test('exactly one price field shows for every option', () {
      for (final m in specs) {
        final variants = [
          m.initialChoices,
          for (final c in m.choices)
            for (final o in c.options) {...m.initialChoices, c.id: o.id},
          ...combinations(m),
        ];
        for (final selected in variants) {
          expect(
            m.visibleNumbers(selected).where((f) => f.isPrice),
            hasLength(1),
            reason: '${m.id} $selected',
          );
        }
      }
    });

    test('every combination calculates and is priced from its own item', () {
      for (final m in specs) {
        for (final selected in combinations(m)) {
          final numbers = {
            for (final f in m.visibleNumbers(selected))
              if (!f.optional) f.id: 3.0,
          };
          final r = m.calculate(numbers, selected);
          final reason = '${m.id} $selected';
          expect(r.quantity, greaterThan(0), reason: reason);
          expect(r.total, closeTo(r.quantity * 3, 0.005), reason: reason);
          expect(itemByKey(r.itemKey ?? ''), isNotNull, reason: reason);
          expect(m.priceRef!(selected)?.itemKey, r.itemKey, reason: reason);
          for (final c in r.companions) {
            expect(c.quantity, greaterThan(0), reason: '$reason ${c.itemKey}');
            expect(itemByKey(c.itemKey), isNotNull, reason: reason);
          }
        }
      }
    });
  });

  group('Paint', () {
    const wall = {'length': 10.0, 'height': 3.0, 'price': 720.0};

    test('new masonry: paint, primer, neutralizer, putty and sandpaper', () {
      final r = run(paint, wall);
      // 30 m² × 2 coats ÷ 7.5 m²/L × 1.10 = 8.8 L → 3 gallons of 4 L.
      expect(detail(r, 'Paint for 2 coats'), '8.8 L');
      expect(r.quantity, 3);
      expect(r.unit, QuantityUnit.gallons);
      expect(r.itemKey, 'paint_latex');
      expect(r.total, 2160);
      expect(r.label, 'Paint, latex flat, 2 coats');
      // Primer 30 ÷ 6.25 × 1.10 = 5.28 L → 2 gallons.
      expect(bought(r, 'primer'), 2);
      expect(bought(r, 'neutralizer'), 1); // 30 ÷ 85 = 0.35 L
      expect(bought(r, 'putty'), 2); // 30 ÷ 25 = 1.2 gallons
      expect(bought(r, 'sandpaper'), 4); // 30 × 1 pass ÷ 8 = 3.75
      expect(bought(r, 'skim_coat'), isNull);
      expect(bought(r, 'paint_thinner'), isNull);
    });

    test('both faces double the area; skim coats add bags and passes', () {
      final r = run(paint, wall, {'faces': '2', 'skim': '2'});
      expect(r.area, 60);
      expect(r.quantity, 5); // 17.6 L
      expect(bought(r, 'primer'), 3); // 10.56 L
      expect(bought(r, 'neutralizer'), 1); // 0.71 L
      expect(bought(r, 'putty'), 3); // 2.4 gallons
      expect(bought(r, 'skim_coat'), 7); // 60 × 2 ÷ 18 = 6.67
      expect(bought(r, 'sandpaper'), 23); // 60 × 3 passes ÷ 8 = 22.5
    });

    test('openings come off each face', () {
      final r = run(paint, {...wall, 'openings': 2}, {'faces': '2'});
      expect(r.area, 56);
      expect(detail(r, 'Area of one face'), '28 m²');
      expect(() => run(paint, {...wall, 'openings': 30}), throwsArgumentError);
    });

    test('enamel on wood adds thinner, no neutralizer or putty', () {
      final r = run(paint, wall, {'type': 'enamel', 'prep': 'wood'});
      // 30 × 2 ÷ 6.25 × 1.1 = 10.56 L → 3 gallons.
      expect(r.quantity, 3);
      expect(r.itemKey, 'paint_enamel');
      expect(bought(r, 'primer'), 2);
      expect(bought(r, 'neutralizer'), isNull);
      expect(bought(r, 'putty'), isNull);
      expect(bought(r, 'sandpaper'), 4);
      // (10.56 + 5.28) ÷ 8 + 0.5 = 2.48 L → 3 L.
      expect(bought(r, 'paint_thinner'), 3);
    });

    test('a repaint without primer needs only paint', () {
      final r = run(paint, wall, {
        'type': 'gloss',
        'prep': 'repaint',
        'primer': 'no',
        'skim': '2',
      });
      expect(r.itemKey, 'paint_latex_gloss');
      expect(r.companions, isEmpty);
      expect(paint.priceRef!({'type': 'gloss'})?.itemKey, 'paint_latex_gloss');
      expect(paint.priceRef!({'type': 'enamel'})?.itemKey, 'paint_enamel');
    });

    test('a small job still needs one gallon', () {
      expect(run(paint, {'length': 1, 'height': 1, 'price': 500}).quantity, 1);
    });
  });

  group('Tiles', () {
    const floor = {'length': 5.0, 'width': 4.0, 'price': 185.0};

    test('by the piece: rows of tiles, 10% waste, adhesive and grout', () {
      final r = run(tiles, floor, {'size': '60x60'});
      // ⌈5 ÷ 0.6⌉ × ⌈4 ÷ 0.6⌉ = 9 × 7 = 63, + 7 waste = 70 tiles.
      expect(detail(r, 'Tiles in rows'), '9 × 7 = 63');
      expect(r.quantity, 70);
      expect(r.unit, QuantityUnit.pieces);
      expect(r.itemKey, 'tile_60x60');
      expect(r.total, 12950);
      expect(detail(r, 'Boxes of 4'), '18 boxes');
      expect(bought(r, 'tile_adhesive'), 4); // 20 m² × 5 kg ÷ 25
      // 20 × 1200 ÷ 360000 × 3 × 10 × 1.6 = 3.2 kg → 2 packs of 2 kg.
      expect(bought(r, 'tile_grout'), 2);
      expect(bought(r, 'tile_spacers'), 2); // 70 × 1.5 = 105
      expect(bought(r, 'cement_40kg'), isNull);
      expect(
        tiles.priceRef!({'size': '60x60', 'buy': 'piece'})?.itemKey,
        'tile_60x60',
      );
    });

    test('by the box: boxes are the quantity and are priced per box', () {
      final r = run(
        tiles,
        {'length': 5, 'width': 4, 'boxPrice': 740},
        {'size': '60x60', 'buy': 'box'},
      );
      expect(r.quantity, 18);
      expect(r.unit, QuantityUnit.boxes);
      expect(r.itemKey, 'tile_60x60_box');
      expect(r.total, 13320);
      expect(r.label, 'Tiles 60 × 60 cm, box of 4');
      expect(detail(r, 'Tiles to buy'), '70 pcs');
      expect(
        tiles.priceRef!({'size': '60x60', 'buy': 'box'})?.itemKey,
        'tile_60x60_box',
      );
      expect(tiles.priceRef!({'buy': 'box'}), isNull);
      final priceField = tiles
          .visibleNumbers({'buy': 'box'})
          .singleWhere((f) => f.isPrice);
      expect(priceField.label, 'Price per box');
    });

    test('skirting is cut from the same tiles', () {
      expect(skirtingPerTile(0.6, 0.6), closeTo(3.6, 1e-9));
      expect(skirtingPerTile(0.3, 0.3), closeTo(0.9, 1e-9));
      expect(skirtingPerTile(0.3, 0.6), closeTo(1.8, 1e-9));
      expect(skirtingPerTile(0.2, 0.3), closeTo(0.6, 1e-9));
      final r = run(tiles, {...floor, 'skirting': 18}, {'size': '60x60'});
      // 18 m ÷ 3.6 m per tile = 5 tiles; (63 + 5) + 7 waste = 75.
      expect(detail(r, 'Skirting 18 m'), '+5 pcs');
      expect(r.quantity, 75);
      // Bed area 20 + 18 × 0.10 = 21.8 m² → 4.36 bags → 5.
      expect(bought(r, 'tile_adhesive'), 5);
      expect(bought(r, 'tile_spacers'), 2); // 112.5
    });

    test('a mortar bed takes cement and sand instead of adhesive', () {
      final r = run(tiles, floor, {'size': '60x60', 'bed': 'mortar'});
      // 20 × (0.025 × 12 + 0.025) × 1.05 = 6.83 bags → 7.
      expect(bought(r, 'cement_40kg'), 7);
      // 20 × 0.025 × 1.05 = 0.525 m³ → 1 m³ in half cubic metres.
      expect(bought(r, 'sand'), 1);
      expect(bought(r, 'tile_adhesive'), isNull);
      expect(bought(r, 'tile_grout'), 2);
    });

    test('lays rectangular tiles the way that needs fewer', () {
      final r = run(
        tiles,
        {'length': 3, 'width': 2, 'price': 1},
        {'size': '30x60'},
      );
      expect(detail(r, 'Tiles in rows'), '5 × 7 = 35');
    });

    test('diagonal layouts waste 15%; tiles per box can be entered', () {
      final r = run(
        tiles,
        {'length': 3, 'width': 3, 'price': 1, 'perBox': 10},
        {'size': '30x30', 'layout': 'diagonal'},
      );
      expect(r.quantity, 115);
      expect(detail(r, 'Boxes of 10'), '12 boxes');
      expect(bought(r, 'tile_adhesive'), 2); // 9 × 3 ÷ 25 = 1.08
    });

    test('a tile size must be chosen', () {
      expect(
        () => tiles.calculate({
          'length': 2,
          'width': 2,
          'price': 1,
        }, tiles.initialChoices),
        throwsArgumentError,
      );
    });
  });

  group('Roof', () {
    const gable = {'eave': 10.0, 'rafter': 4.0, 'price': 624.0};

    test('gable, corrugated: sheets, screws and ridge roll', () {
      final r = run(roof, gable);
      // ⌈10 ÷ 0.70⌉ = 15 across; ⌈3.75 ÷ 2.188⌉ = 2 up; × 2 sides.
      expect(r.quantity, 60);
      expect(r.unit, QuantityUnit.sheets);
      expect(r.itemKey, 'gi_corrugated_8ft');
      expect(r.area, 80);
      expect(r.total, 37440);
      expect(bought(r, 'tek_screw'), 640); // 80 m² × 8
      expect(bought(r, 'ridge_roll'), 5); // 10 ÷ 2.25 = 4.4
      expect(bought(r, 'c_purlin'), isNull);
      expect(bought(r, 'gutter'), isNull);
      expect(
        roof.priceRef!({'type': 'corrugated', 'sheetLength': '10'})?.itemKey,
        'gi_corrugated_10ft',
      );
    });

    test('purlins and gutters', () {
      final r = run(roof, gable, {'purlins': 'yes', 'gutter': 'eaves'});
      // ⌈4 ÷ 0.60⌉ + 1 = 8 lines × ⌈10 ÷ 5.8⌉ = 2 × 2 sides.
      expect(bought(r, 'c_purlin'), 32);
      expect(bought(r, 'gutter'), 20); // both eaves
      expect(bought(r, 'downspout'), 6); // 2 downspouts × 3 m
      final tall = run(
        roof,
        {...gable, 'downspout': 4},
        {'gutter': 'eaves', 'purlins': 'yes', 'spacing': '1.00'},
      );
      expect(bought(tall, 'downspout'), 8);
      expect(bought(tall, 'c_purlin'), 20); // (4 + 1) × 2 × 2
    });

    test('shed, long-span: metres, screws, one gutter, no ridge', () {
      final r = run(
        roof,
        {'eave': 6, 'rafter': 3, 'priceMetre': 380},
        {'type': 'longspan', 'shape': 'shed', 'gutter': 'eaves'},
      );
      // 6 sheets × (3 + 0.05) m = 18.3 m.
      expect(r.quantity, closeTo(18.3, 1e-9));
      expect(r.unit, QuantityUnit.metres);
      expect(r.itemKey, 'longspan_m');
      expect(r.total, 6954);
      expect(bought(r, 'tek_screw'), 126); // 18 m² × 7
      expect(bought(r, 'ridge_roll'), isNull);
      expect(bought(r, 'gutter'), 6);
      expect(bought(r, 'downspout'), 3);
      expect(roof.priceRef!({'type': 'longspan'})?.itemKey, 'longspan_m');
    });

    test('hip: plan area × slope factor, 4 hips and 10% more sheets', () {
      final r = run(
        roof,
        {'eave': 10, 'width': 8, 'price': 624},
        {'shape': 'hip', 'pitch': '6', 'purlins': 'yes', 'gutter': 'eaves'},
      );
      // Slope factor √1.25 = 1.118; area 80 × 1.118 = 89.44 m².
      expect(r.area, closeTo(89.4427, 1e-4));
      // Rafter 4 × 1.118 = 4.47 m: 15 across × 2 up × 2 = 60, + 6 = 66.
      expect(r.quantity, 66);
      expect(detail(r, 'Hip cutting waste'), '+6 sheets');
      // Ridge 10 − 8 = 2 m; hips 4 × 4 × √2.25 = 24 m → 26 ÷ 2.25 = 11.6.
      expect(detail(r, 'Ridge'), '2 m');
      expect(detail(r, '4 hips of 6 m'), '24 m');
      expect(bought(r, 'ridge_roll'), 12);
      expect(bought(r, 'tek_screw'), 716); // 89.44 × 8 = 715.5
      expect(bought(r, 'c_purlin'), 36); // (⌈7.45⌉ + 1) × 2 × 2
      expect(bought(r, 'gutter'), 36); // perimeter 2 × (10 + 8)
      expect(bought(r, 'downspout'), 12); // 4 × 3 m
      // Length and width may be entered either way round.
      final swapped = run(
        roof,
        {'eave': 8, 'width': 10, 'price': 624},
        {'shape': 'hip', 'pitch': '6'},
      );
      expect(swapped.quantity, 66);
    });

    test('hip, long-span: metres plus 10%', () {
      final r = run(
        roof,
        {'eave': 10, 'width': 8, 'priceMetre': 380},
        {'type': 'longspan', 'shape': 'hip', 'pitch': '6'},
      );
      // 10 × 2 sheets × (4.472 + 0.05) m = 90.44 m × 1.10 = 99.49 m.
      expect(r.quantity, closeTo(99.49, 1e-9));
    });

    test('a square hip roof has no ridge, only hips', () {
      final r = run(
        roof,
        {'eave': 8, 'width': 8, 'price': 1},
        {'shape': 'hip', 'pitch': '4'},
      );
      // 4 × 4 × √(2 + 1/9) = 23.25 m ÷ 2.25 = 10.3 → 11.
      expect(bought(r, 'ridge_roll'), 11);
    });

    test('hip asks for the plan width and pitch, not the rafter', () {
      final ids = roof.visibleNumbers({'shape': 'hip'}).map((f) => f.id);
      expect(ids, containsAll(['eave', 'width']));
      expect(ids, isNot(contains('rafter')));
      final choices = roof
          .visibleChoices({...roof.initialChoices, 'shape': 'hip'})
          .map((c) => c.id);
      expect(choices, contains('pitch'));
      expect(choices, isNot(contains('measured')));
    });
  });

  group('Carpet', () {
    test('broadloom from one drop, with underlay and gripper', () {
      final r = run(carpet, {'length': 5, 'width': 3.5, 'price': 800});
      expect(r.quantity, closeTo(20.4, 1e-9)); // 1 × 5.1 m × 4 m
      expect(r.itemKey, 'carpet_m2');
      expect(bought(r, 'underlay_m2'), closeTo(18.4, 1e-9)); // 18.375
      expect(bought(r, 'gripper_m'), 17);
      expect(bought(r, 'seam_tape_m'), isNull);
    });

    test('two drops need seam tape', () {
      final r = run(carpet, {'length': 6, 'width': 5, 'price': 800});
      expect(r.quantity, closeTo(40.8, 1e-9)); // 2 × 5.1 m × 4 m
      expect(bought(r, 'seam_tape_m'), 6); // 5.1 m
    });

    test('carpet tiles are bought by the box', () {
      final r = run(
        carpet,
        {'length': 4, 'width': 5, 'boxPrice': 4000},
        {'type': 'tiles'},
      );
      expect(r.quantity, 5); // 84 tiles
      expect(r.itemKey, 'carpet_tile_box');
      expect(carpet.priceRef!({'type': 'tiles'})?.itemKey, 'carpet_tile_box');
      expect(carpet.priceRef!({'type': 'roll'})?.itemKey, 'carpet_m2');
    });
  });

  group('Wallpaper', () {
    const wall = {'width': 10.0, 'height': 2.6, 'price': 800.0};

    test('counts strips per roll and paste', () {
      final r = run(wallpaper, wall);
      // 2.7 m strips, 3 per roll, 19 strips → 7 rolls; 7 ÷ 5 → 2 packs.
      expect(r.quantity, 7);
      expect(r.itemKey, 'wallpaper_std');
      expect(bought(r, 'wallpaper_paste'), 2);
      expect(
        bought(run(wallpaper, {...wall, 'width': 7}), 'wallpaper_paste'),
        1, // exactly 5 rolls
      );
    });

    test('jumbo rolls count as about 3 standard rolls of paste', () {
      final r = run(wallpaper, wall, {'roll': 'jumbo'});
      expect(r.quantity, 2); // 10 strips, 5 per roll
      expect(r.itemKey, 'wallpaper_jumbo');
      expect(bought(r, 'wallpaper_paste'), 2); // 2 × 3.1 ÷ 5 = 1.24
      expect(
        wallpaper.priceRef!({'roll': 'narrow'})?.itemKey,
        'wallpaper_narrow',
      );
    });

    test('self-adhesive rolls need no paste', () {
      final r = run(wallpaper, wall, {'backing': 'self'});
      expect(r.companions, isEmpty);
    });
  });

  group('Doors', () {
    test('interior doors take 3 hinges and a lockset each', () {
      final r = run(doors, {'quantity': 5, 'price': 3800});
      expect(r.quantity, 5);
      expect(r.unit, QuantityUnit.sets);
      expect(r.itemKey, 'door_set');
      expect(r.total, 19000);
      expect(bought(r, 'hinge'), 15);
      expect(bought(r, 'lockset'), 5);
    });

    test('the main door takes 4 heavy hinges and an entrance lockset', () {
      final r = run(doors, {'quantity': 1, 'price': 9500}, {'type': 'main'});
      expect(r.itemKey, 'door_main');
      expect(bought(r, 'hinge_heavy'), 4);
      expect(bought(r, 'lockset_entrance'), 1);
      expect(doors.priceRef!({'type': 'main'})?.itemKey, 'door_main');
    });

    test('PVC door sets come with hinges', () {
      final r = run(doors, {'quantity': 2, 'price': 2800}, {'type': 'pvc'});
      expect(r.itemKey, 'door_pvc');
      expect(bought(r, 'hinge'), isNull);
      expect(bought(r, 'lockset'), 2);
      expect(doors.priceRef!({'type': 'pvc'})?.itemKey, 'door_pvc');
    });

    test('is found by its Filipino name', () {
      expect(doors.matches('pinto'), isTrue);
      expect(windows.matches('bintana'), isTrue);
      expect(doors.icon, isNotNull);
      expect(windows.icon, isNotNull);
    });
  });

  group('Windows', () {
    test('priced per m², with sealant on both sides', () {
      final r = run(windows, {
        'width': 1.2,
        'height': 1.2,
        'quantity': 3,
        'price': 4850,
      });
      expect(r.quantity, closeTo(4.32, 1e-9));
      expect(r.unit, QuantityUnit.squareMetres);
      expect(r.itemKey, 'window_m2');
      expect(r.total, 20952);
      expect(detail(r, 'In square feet'), '46.5 ft²');
      // 3 × 4.8 m × 2 sides = 28.8 m ÷ 7 m = 4.1 → 5 tubes.
      expect(bought(r, 'sealant'), 5);
      expect(windows.priceRef!(const {})?.itemKey, 'window_m2');
    });
  });

  group('Works', () {
    test('every combination measures its main work first', () {
      const main = {
        'paint': Work.painting,
        'tiles': Work.tiling,
        'roof': Work.roofing,
        'carpet': Work.carpet,
        'wallpaper': Work.wallpaper,
        'doors': Work.doors,
        'windows': Work.windows,
      };
      for (final m in specs) {
        for (final selected in combinations(m)) {
          final numbers = {
            for (final f in m.visibleNumbers(selected))
              if (!f.optional) f.id: 3.0,
          };
          final r = m.calculate(numbers, selected);
          final reason = '${m.id} $selected';
          expect(r.works.first.key, main[m.id], reason: reason);
          for (final w in r.works) {
            expect(workItemByKey(w.key), isNotNull, reason: reason);
            expect(w.quantity, greaterThan(0), reason: '$reason ${w.key}');
          }
          for (final c in r.companions) {
            if (c.work != null) {
              expect(r.works.map((w) => w.key), contains(c.work));
            }
          }
        }
      }
    });

    test('paint counts every coat over the painted area', () {
      // 30 m², 2 finish coats + 1 primer.
      expect(works(run(paint, {'length': 10, 'height': 3, 'price': 1})), [
        (Work.painting, 30.0, 3.0),
      ]);
      // (30 − 2) × 2 faces = 56 m²; 2 coats + primer + 1.5 for a skim coat.
      final r = run(
        paint,
        {'length': 10, 'height': 3, 'openings': 2, 'price': 1},
        {'faces': '2', 'skim': '1'},
      );
      expect(works(r), [(Work.painting, 56.0, 4.5)]);
      expect(companionWorks(r).values, everyElement(isNull));
      // One coat, no primer, no skim coat on a repaint.
      final repaint = run(
        paint,
        {'length': 10, 'height': 3, 'price': 1},
        {'coats': '1', 'prep': 'repaint', 'primer': 'no', 'skim': '2'},
      );
      expect(works(repaint), [(Work.painting, 30.0, 1.0)]);
    });

    test('tiles measure the floor, and the skirting in metres', () {
      const floor = {'length': 5.0, 'width': 4.0, 'price': 185.0};
      expect(works(run(tiles, floor, {'size': '60x60'})), [
        (Work.tiling, 20.0, 1.0),
      ]);
      final r = run(tiles, {...floor, 'skirting': 18}, {'size': '60x60'});
      expect(works(r), [
        (Work.tiling, 20.0, 1.0),
        (Work.tileSkirting, 18.0, 1.0),
      ]);
      // The skirting is cut from the floor tiles and set in the same bed.
      expect(companionWorks(r).values, everyElement(isNull));
    });

    test('roof: sheets, purlins and gutters each have their work', () {
      final r = run(
        roof,
        {'eave': 10, 'rafter': 4, 'price': 624},
        {'purlins': 'yes', 'gutter': 'eaves'},
      );
      // 80 m² of roof; 8 purlin lines × 10 m × 2 sides = 160 m; 20 m of
      // gutter + 2 downspouts × 3 m = 26 m.
      expect(works(r), [
        (Work.roofing, 80.0, 1.0),
        (Work.purlins, 160.0, 1.0),
        (Work.gutter, 26.0, 1.0),
      ]);
      expect(companionWorks(r), {
        'c_purlin': Work.purlins,
        'tek_screw': null,
        'ridge_roll': null,
        'gutter': Work.gutter,
        'downspout': Work.gutter,
      });
      // Hip: 89.44 m²; 9 lines × 10 m × 2 = 180 m; 36 m + 4 × 3 m = 48 m.
      final hip = run(
        roof,
        {'eave': 10, 'width': 8, 'priceMetre': 380},
        {
          'type': 'longspan',
          'shape': 'hip',
          'pitch': '6',
          'purlins': 'yes',
          'gutter': 'eaves',
        },
      );
      expect(works(hip), [
        (Work.roofing, 89.44, 1.0),
        (Work.purlins, 180.0, 1.0),
        (Work.gutter, 48.0, 1.0),
      ]);
      // Without purlins or gutters, only the sheets.
      expect(works(run(roof, {'eave': 6, 'rafter': 3, 'price': 1})), [
        (Work.roofing, 36.0, 1.0),
      ]);
    });

    test('carpet and wallpaper measure the area covered', () {
      expect(works(run(carpet, {'length': 5, 'width': 3.5, 'price': 800})), [
        (Work.carpet, 17.5, 1.0),
      ]);
      expect(
        works(
          run(
            carpet,
            {'length': 4, 'width': 5, 'boxPrice': 4000},
            {'type': 'tiles'},
          ),
        ),
        [(Work.carpet, 20.0, 1.0)],
      );
      // (10 − 1.5) m × 2.6 m = 22.1 m².
      expect(
        works(
          run(wallpaper, {
            'width': 10,
            'height': 2.6,
            'openings': 1.5,
            'price': 800,
          }),
        ),
        [(Work.wallpaper, 22.1, 1.0)],
      );
    });

    test('doors count sets; windows measure their area', () {
      expect(works(run(doors, {'quantity': 5, 'price': 3800})), [
        (Work.doors, 5.0, 1.0),
      ]);
      final r = run(windows, {
        'width': 1.2,
        'height': 1.2,
        'quantity': 3,
        'price': 4850,
      });
      expect(works(r), [(Work.windows, 4.32, 1.0)]);
    });
  });
}
