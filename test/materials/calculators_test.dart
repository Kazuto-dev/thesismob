import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/architectural.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/fixtures.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/structural.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

String? companion(CalcResult r, String label) =>
    r.companions.where((c) => c.label.startsWith(label)).firstOrNull?.value;

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

void main() {
  group('catalog', () {
    test('has 19 materials with unique ids in every category', () {
      expect(allMaterials, hasLength(19));
      expect(allMaterials.map((m) => m.id).toSet(), hasLength(19));
      for (final category in MaterialCategory.values) {
        expect(materialsIn(category), isNotEmpty, reason: category.name);
      }
    });

    test('every material has definitions, a solution and search words', () {
      for (final m in allMaterials) {
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
      }
    });

    test('exactly one price field shows for every option', () {
      for (final m in allMaterials) {
        final variants = [
          m.initialChoices,
          for (final c in m.choices)
            for (final o in c.options) {...m.initialChoices, c.id: o.id},
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

    test('initial choices are valid options', () {
      for (final m in allMaterials) {
        for (final c in m.choices) {
          if (c.initial != null) {
            expect(c.option(c.initial), isNotNull, reason: '${m.id}.${c.id}');
          }
        }
      }
    });

    test('every material calculates with plain inputs', () {
      for (final m in allMaterials) {
        final selected = {
          ...m.initialChoices,
          for (final c in m.choices)
            if (c.initial == null) c.id: c.options.first.id,
        };
        final numbers = {
          for (final f in m.visibleNumbers(selected))
            if (!f.optional) f.id: 3.0,
        };
        final r = m.calculate(numbers, selected);
        expect(r.quantity, greaterThan(0), reason: m.id);
        expect(r.total, closeTo(r.quantity * 3, 0.005), reason: m.id);
      }
    });

    test('search matches names, categories and Filipino words', () {
      List<String> find(String q) => [
        for (final m in allMaterials)
          if (m.matches(q)) m.id,
      ];
      expect(find('yero'), ['roof']);
      expect(find('GRIPO'), ['faucet']);
      expect(find('plumbing'), containsAll(['pvc', 'sink', 'toilet']));
      expect(find('zzz'), isEmpty);
    });
  });

  group('CHB', () {
    const wall = {'length': 10.0, 'height': 3.0, 'price': 25.0};

    test('12.5 blocks per m² plus 5% waste by default', () {
      final r = run(chb, wall);
      expect(r.area, 30);
      expect(r.quantity, 394); // 375 + ⌈18.75⌉
      expect(r.total, 9850);
      expect(r.unit, QuantityUnit.blocks);
      expect(r.label, 'CHB 4"');
    });

    test('without waste a 30 m² wall needs exactly 375 blocks', () {
      expect(run(chb, wall, {'waste': 'none'}).quantity, 375);
      // 6 m² must not round up to 76 from floating-point noise.
      expect(
        run(
          chb,
          {'length': 2.5, 'height': 2.4, 'price': 1},
          {'waste': 'none'},
        ).quantity,
        75,
      );
    });

    test('doors and windows are left out', () {
      final r = run(chb, {...wall, 'openings': 3.3});
      expect(r.area, closeTo(26.7, 1e-9));
      expect(r.quantity, 334 + 17);
      expect(() => run(chb, {...wall, 'openings': 30}), throwsArgumentError);
    });

    test('lists Class B mortar, plaster and rebar', () {
      final r = run(chb, wall);
      // 30 × (0.522 + 2 × 0.192) = 27.18 → 28 bags.
      expect(companion(r, 'Cement'), '28 bags');
      // 30 × (0.0435 + 2 × 0.016) = 2.265 m³.
      expect(companion(r, 'Sand'), '2.27 m³');
      // 30 × 4.28 = 128.4 m of bar → 22 bars of 6 m.
      expect(companion(r, 'Rebar'), '22 bars');

      final bare = run(chb, wall, {'size': '6', 'plaster': '0'});
      expect(companion(bare, 'Cement'), '31 bags'); // 30 × 1.018
      expect(companion(bare, 'Sand'), '2.54 m³'); // 30 × 0.0844
    });
  });

  group('Plywood', () {
    test('20 m² takes 7 sheets of 1.22 × 2.44 m, 8 with 10% waste', () {
      const surface = {'length': 4.0, 'width': 5.0, 'price': 600.0};
      expect(run(plywood, surface, {'waste': 'none'}).quantity, 7);
      final r = run(plywood, surface);
      expect(r.quantity, 8);
      expect(r.total, 4800);
      expect(r.label, "Plywood 4' × 8'");
      expect(
        run(plywood, surface, {'thickness': '12'}).label,
        "Plywood 4' × 8', 12 mm (½\")",
      );
    });
  });

  group('Foam insulation', () {
    const roof = {'eave': 10.0, 'rafter': 4.0, 'price': 1600.0};

    test('strips with 5 cm laps on both sides of a gable', () {
      final r = run(insulation, roof);
      // 11 strips × 4.05 m × 2 sides × 1.05 = 93.6 m → 2 rolls of 50 m.
      expect(detail(r, 'Strips per side'), '11 strips');
      expect(detail(r, 'Foam with 5% waste'), '93.6 m');
      expect(r.quantity, 2);
      expect(r.total, 3200);
      expect(r.area, 80);
      expect(companion(r, 'Foil tape'), '81 m');
    });

    test('a plan measurement is converted to the slope', () {
      // 4 m × 1.118 = 4.472 m; 11 × 4.522 × 2 × 1.05 = 104.5 m → 3 rolls.
      expect(run(insulation, roof, {'measured': '6'}).quantity, 3);
    });

    test('describes the thickness and foil', () {
      final r = run(insulation, roof, {'thickness': '10', 'foil': 'double'});
      expect(r.label, 'PE foam insulation, 10 mm, Both sides');
    });
  });

  group('Paint', () {
    const wall = {'length': 10.0, 'height': 3.0, 'price': 980.0};

    test('uses 4-litre gallons and adds 10%', () {
      final r = run(paint, wall);
      // 30 m² × 2 coats ÷ 7.5 m²/L × 1.10 = 8.8 L → 3 gallons of 4 L.
      expect(detail(r, 'Paint for 2 coats'), '8.8 L');
      expect(r.quantity, 3);
      expect(r.unit, QuantityUnit.gallons);
      expect(r.total, 2940);
      expect(r.label, 'Paint, latex, 2 coats');
      // Primer: 30 ÷ 6.25 × 1.10 = 5.28 L → 2 gallons.
      expect(companion(r, 'Primer'), '2 gallons (5.3 L)');
    });

    test('enamel covers less, openings are left out', () {
      // 30 × 2 ÷ 6.25 × 1.1 = 10.56 L → 3 gallons.
      expect(run(paint, wall, {'type': 'enamel'}).quantity, 3);
      final r = run(paint, {...wall, 'openings': 2}, {'primer': 'no'});
      expect(r.area, 28);
      expect(r.companions, isEmpty);
    });

    test('a small job still needs one gallon', () {
      final r = run(paint, {'length': 1, 'height': 1, 'price': 500});
      expect(r.quantity, 1);
    });
  });

  group('Tiles', () {
    test('counts rows of tiles, adds 10% and fills boxes', () {
      final r = run(
        tiles,
        {'length': 5, 'width': 4, 'price': 185},
        {'size': '60x60'},
      );
      // ⌈5 ÷ 0.6⌉ × ⌈4 ÷ 0.6⌉ = 9 × 7 = 63, + 7 waste = 70 tiles.
      expect(detail(r, 'Tiles in rows'), '9 × 7 = 63');
      expect(r.quantity, 70);
      expect(r.total, 12950);
      expect(detail(r, 'Boxes of 4'), '18 boxes');
      expect(companion(r, 'Tile adhesive'), '4 bags'); // 20 m² × 5 kg ÷ 25
      expect(companion(r, 'Tile grout'), '3.2 kg');
    });

    test('lays rectangular tiles the way that needs fewer', () {
      final r = run(
        tiles,
        {'length': 3, 'width': 2, 'price': 1},
        {'size': '30x60', 'layout': 'straight'},
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
      expect(companion(r, 'Tile adhesive'), '2 bags');
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

  group('Roofing', () {
    const roofInputs = {'eave': 10.0, 'rafter': 4.0, 'price': 520.0};

    test('corrugated sheets: columns × rows with a 0.25 m end lap', () {
      final r = run(roof, roofInputs);
      // ⌈10 ÷ 0.70⌉ = 15 across; ⌈3.75 ÷ 2.1884⌉ = 2 up; × 2 sides.
      expect(r.quantity, 60);
      expect(r.unit, QuantityUnit.sheets);
      expect(r.total, 31200);
      expect(r.label, 'Corrugated GI, 8 ft (2.44 m)');
      expect(companion(r, 'Ridge roll'), '10 m');
    });

    test('a short slope takes one sheet, 2½ corrugation laps cover less', () {
      expect(run(roof, {...roofInputs, 'rafter': 2.4}).quantity, 30);
      expect(
        run(roof, {...roofInputs, 'rafter': 2.4}, {'sideLap': '2.5'}).quantity,
        34, // ⌈10 ÷ 0.60⌉ = 17 × 2
      );
    });

    test('long-span sheets are cut to the slope and sold by the metre', () {
      final r = run(
        roof,
        {'eave': 10, 'rafter': 4, 'priceMetre': 450},
        {'type': 'longspan', 'measured': '6'},
      );
      // 10 sheets × 2 sides × (4 × 1.118 + 0.05) m = 90.44 m.
      expect(r.quantity, 90.44);
      expect(r.unit, QuantityUnit.metres);
      expect(r.total, 40698);
    });

    test('long-span hides the corrugated options and the sheet price', () {
      final selected = {...roof.initialChoices, 'type': 'longspan'};
      final ids = roof.visibleChoices(selected).map((c) => c.id);
      expect(ids, isNot(contains('sideLap')));
      expect(ids, contains('cover'));
      final prices = roof.visibleNumbers(selected).where((f) => f.isPrice);
      expect(prices.single.id, 'priceMetre');
    });
  });

  group('Carpet', () {
    test('broadloom drops run the way that needs less carpet', () {
      final r = run(carpet, {'length': 5, 'width': 3.5, 'price': 800});
      // One 4 m drop, 5.10 m long = 20.4 m².
      expect(r.quantity, 20.4);
      expect(r.unit, QuantityUnit.squareMetres);
      expect(r.total, 16320);
      expect(companion(r, 'Gripper'), '17 m');
      expect(companion(r, 'Seam tape'), isNull);

      final wide = run(carpet, {'length': 6, 'width': 5, 'price': 800});
      expect(wide.quantity, 40.8); // 2 drops × 5.10 m × 4 m
      expect(companion(wide, 'Seam tape'), '5.1 m');
    });

    test('carpet tiles come 20 to a box', () {
      final r = run(
        carpet,
        {'length': 5, 'width': 4, 'boxPrice': 2000},
        {'type': 'tiles'},
      );
      // 20 m² × 1.05 ÷ 0.25 = 84 tiles → 5 boxes.
      expect(r.quantity, 5);
      expect(r.unit, QuantityUnit.boxes);
      expect(r.total, 10000);
    });
  });

  group('Wallpaper', () {
    const walls = {'width': 10.0, 'height': 2.6, 'price': 650.0};

    test('counts whole strips per roll', () {
      final r = run(wallpaper, walls);
      // 2.7 m strips, 3 per 10.05 m roll, 19 strips → 7 rolls.
      expect(detail(r, 'Strips per roll'), '3');
      expect(r.quantity, 7);
      expect(r.total, 4550);
    });

    test('pattern repeats, doors and tall walls', () {
      expect(run(wallpaper, walls, {'repeat': '64'}).quantity, 7);
      expect(run(wallpaper, {...walls, 'openings': 1}).quantity, 6);
      expect(run(wallpaper, {...walls, 'height': 4.9}).quantity, 10);
      expect(
        () => run(wallpaper, {...walls, 'height': 10}),
        throwsArgumentError,
      );
    });
  });

  group('Light bulbs', () {
    test('the lumen method sizes a room', () {
      final r = run(bulb, {'length': 5, 'width': 4, 'price': 120});
      // 150 lx × 20 m² = 3,000 lm ÷ (880 lm × 0.5) = 6.8 → 7 bulbs.
      expect(r.quantity, 7);
      expect(r.unit, QuantityUnit.bulbs);
      expect(r.total, 840);
      expect(r.label, 'LED bulb 9 W');
      final bedroom = run(
        bulb,
        {'length': 3, 'width': 4, 'price': 1},
        {'room': 'bedroom', 'watts': '12'},
      );
      expect(bedroom.quantity, 2);
    });

    test('a count can be entered directly', () {
      final r = run(bulb, {'quantity': 4, 'price': 150}, {'mode': 'count'});
      expect(r.quantity, 4);
      expect(r.total, 600);
    });
  });

  group('Outlets', () {
    test('one outlet per 3.6 m of wall, doorways left out', () {
      expect(run(outlet, {'length': 5, 'width': 5, 'price': 1}).quantity, 6);
      final r = run(outlet, {
        'length': 4,
        'width': 3,
        'doors': 0.9,
        'price': 95,
      });
      expect(r.quantity, 4); // 13.1 m ÷ 3.6 = 3.6
      expect(companion(r, 'Utility boxes'), '4 pcs');
    });
  });

  group('Wire', () {
    test('circuit × wires × 1.10, in 150 m boxes', () {
      final r = run(wires, {'run': 30, 'boxPrice': 3800});
      // 30 m × 3 wires × 1.1 = 99 m → 1 box.
      expect(r.quantity, 1);
      expect(r.unit, QuantityUnit.boxes);
      expect(r.label, 'THHN wire 3.5 mm²');
      expect(run(wires, {'run': 60, 'boxPrice': 1}).quantity, 2);
      expect(companion(r, 'PVC conduit'), '11 lengths');
    });

    test('or by the metre', () {
      final r = run(
        wires,
        {'run': 30, 'price': 30},
        {'buy': 'metre', 'conductors': '2'},
      );
      expect(r.quantity, 66);
      expect(r.unit, QuantityUnit.metres);
      expect(r.total, 1980);
    });
  });

  group('PVC pipe', () {
    test('run + 10% in 3 m pipes', () {
      final r = run(pvc, {'run': 24, 'price': 165});
      expect(r.quantity, 9); // 26.4 ÷ 3 = 8.8
      expect(r.total, 1485);
      expect(r.label, 'PVC pipe ½" (20 mm)');
      expect(run(pvc, {'run': 24, 'price': 1}, {'length': '4'}).quantity, 7);
    });
  });

  group('Fixtures', () {
    test('quantity × price, with what each one needs', () {
      final r = run(sink, {'quantity': 3, 'price': 2500}, {'type': 'pedestal'});
      expect(r.total, 7500);
      expect(r.label, 'Sink, Pedestal');
      expect(companion(r, 'Angle valves'), '3 pcs');
      expect(run(toilet, {'quantity': 2, 'price': 1}).label, 'Toilet');
    });

    test('totals are rounded to the centavo', () {
      final r = run(faucet, {'quantity': 3, 'price': 0.1});
      expect(r.total, 0.3);
    });
  });
}
