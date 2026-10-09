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

void main() {
  group('catalog', () {
    test('has 19 materials with unique ids, four per category or more', () {
      expect(allMaterials, hasLength(19));
      expect(allMaterials.map((m) => m.id).toSet(), hasLength(19));
      for (final category in MaterialCategory.values) {
        expect(materialsIn(category), isNotEmpty, reason: category.name);
      }
    });

    test('every material has definitions and a solution', () {
      for (final m in allMaterials) {
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
      }
    });

    test('every material has a price field and only valid initial choices', () {
      for (final m in allMaterials) {
        expect(m.numbers.where((f) => f.isPrice), hasLength(1), reason: m.id);
        for (final c in m.choices) {
          if (c.initial != null) {
            expect(c.option(c.initial), isNotNull, reason: '${m.id}.${c.id}');
          }
        }
      }
    });
  });

  group('CHB', () {
    test(
      '10 m × 3 m wall at ₱25 needs 375 blocks (same as the original app)',
      () {
        final r = run(chb, {'length': 10, 'height': 3, 'price': 25});
        expect(r.area, 30);
        expect(r.quantity, 375);
        expect(r.total, 9375);
        expect(r.unit, QuantityUnit.blocks);
        expect(r.label, 'CHB 4"');
      },
    );

    test('contingency is applied (it was silently ignored before)', () {
      final r = run(
        chb,
        {'length': 10, 'height': 3, 'price': 25},
        {'contingency': '5'},
      );
      expect(r.quantity, 375 + 19); // ⌈375 × 0.05⌉ = 19
      expect(r.total, 394 * 25);
    });

    test('an exact multiple is not rounded up by floating-point noise', () {
      expect(run(chb, {'length': 2.5, 'height': 2.4, 'price': 1}).quantity, 75);
    });
  });

  group('Plywood', () {
    test("20 m² needs 7 4'×8' sheets, 8 with 10% contingency", () {
      final base = run(plywood, {'length': 4, 'width': 5, 'price': 600});
      expect(base.quantity, 7);
      expect(base.total, 4200);
      final extra = run(
        plywood,
        {'length': 4, 'width': 5, 'price': 600},
        {'contingency': '10'},
      );
      expect(extra.quantity, 8);
    });
  });

  group('Insulation', () {
    test('charges whole rolls (the original charged 1.2 rolls)', () {
      final r = run(insulation, {'length': 10, 'width': 6, 'price': 1500});
      expect(r.quantity, 2);
      expect(r.total, 3000);
      expect(r.unit, QuantityUnit.rolls);
    });

    test('describes the chosen thickness and type', () {
      final r = run(
        insulation,
        {'length': 1, 'width': 1, 'price': 1},
        {'thickness': '10', 'type': 'foil1'},
      );
      expect(r.label, 'PE foam insulation, 10 mm, Foil on one side');
    });
  });

  group('Paint', () {
    test('counts coats and charges whole gallons', () {
      // 30 m² × 2 coats ÷ 8 m²/L = 7.5 L = 1.98 gal → 2 gallons.
      final r = run(paint, {
        'length': 10,
        'width': 3,
        'coats': 2,
        'coverage': 8,
        'price': 800,
      });
      expect(r.quantity, 2);
      expect(r.unit, QuantityUnit.gallons);
      expect(r.total, 1600);
      expect(r.label, 'Paint, 2 coats');
      expect(r.details.first.value, '7.5 L');
    });

    test('a small job still needs one gallon', () {
      final r = run(paint, {
        'length': 4,
        'width': 3,
        'coats': 1,
        'coverage': 10,
        'price': 800,
      });
      expect(r.quantity, 1);
      expect(r.label, 'Paint, 1 coat');
    });
  });

  group('Tiles', () {
    test('requires a tile size (the default used to divide by zero)', () {
      expect(
        () => run(tiles, {'length': 4, 'width': 5, 'price': 45}),
        throwsArgumentError,
      );
    });

    test('20 m² of 30×30 floor tiles is 223 tiles, 246 with 10%', () {
      final r = run(
        tiles,
        {'length': 4, 'width': 5, 'price': 45},
        {'size': '30f'},
      );
      expect(r.quantity, 223);
      expect(r.total, 223 * 45);
      final extra = run(
        tiles,
        {'length': 4, 'width': 5, 'price': 45},
        {'size': '30f', 'contingency': '10'},
      );
      expect(extra.quantity, 246);
    });
  });

  group('Roof', () {
    const numbers = {'length': 10.0, 'width': 8.0, 'price': 450.0};
    const sheet = {'sheetWidth': '0.8', 'sheetLength': '8'};

    test('ribbed sheets cover their full width', () {
      final r = run(roof, numbers, {...sheet, 'type': 'ribbed'});
      expect(r.quantity, 42); // 80 ÷ (0.8 × 2.438) = 41.02
      expect(r.total, 42 * 450);
    });

    test('corrugated sheets lose the side lap', () {
      final lap25 = run(roof, numbers, {
        ...sheet,
        'type': 'corrugated',
        'sideLap': '2.5',
      });
      expect(lap25.quantity, 54); // 80 ÷ ((0.8 − 0.1905) × 2.438) = 53.8
      final lap15 = run(roof, numbers, {
        ...sheet,
        'type': 'corrugated',
        'sideLap': '1.5',
      });
      expect(lap15.quantity, 48); // 80 ÷ ((0.8 − 0.1143) × 2.438) = 47.9
    });

    test('side lap is only asked for corrugated roofs', () {
      expect(
        roof.visibleChoices({'type': 'ribbed'}).map((c) => c.id),
        isNot(contains('sideLap')),
      );
      expect(
        roof.visibleChoices({'type': 'corrugated'}).map((c) => c.id),
        contains('sideLap'),
      );
    });

    test('the 1.2 m width and 12 ft length options are usable', () {
      final r = run(roof, numbers, {
        'type': 'ribbed',
        'sheetWidth': '1.2',
        'sheetLength': '12',
      });
      expect(r.quantity, 19); // 80 ÷ (1.2 × 3.658) = 18.2
    });
  });

  group('Carpet and wallpaper', () {
    test('carpet: 20 m² of 1.6 × 2.3 m pieces is 6', () {
      final r = run(
        carpet,
        {'length': 4, 'width': 5, 'price': 2500},
        {'size': '160x230'},
      );
      expect(r.quantity, 6);
      expect(r.total, 15000);
    });

    test('wallpaper: 7.5 m² of 4 × 8 ft rolls is 3', () {
      final r = run(
        wallpaper,
        {'width': 3, 'height': 2.5, 'price': 900},
        {'size': '4x8'},
      );
      expect(r.quantity, 3);
      expect(r.unit, QuantityUnit.rolls);
    });
  });

  group('Fixtures', () {
    test('quantity × price, with an informative label', () {
      final r = run(
        bulb,
        {'quantity': 12, 'price': 150},
        {'type': 'led', 'watts': '9'},
      );
      expect(r.total, 1800);
      expect(r.area, isNull);
      expect(r.label, 'Light bulb, LED, 9 W');
    });

    test('unspecified options are left out of the label', () {
      expect(run(sink, {'quantity': 2, 'price': 3000}).label, 'Sink');
    });

    test('wire is priced per metre and rounded to the centavo', () {
      final r = run(wires, {'quantity': 12.345, 'price': 10.1});
      expect(r.unit, QuantityUnit.metres);
      expect(r.total, 124.68);
    });

    test('every per-piece material multiplies quantity by price', () {
      for (final m in allMaterials.where(
        (m) => m.numbers.any((f) => f.id == 'quantity'),
      )) {
        expect(run(m, {'quantity': 3, 'price': 2.5}).total, 7.5, reason: m.id);
      }
    });
  });
}
