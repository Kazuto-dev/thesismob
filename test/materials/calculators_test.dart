import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/work_items.dart';
import 'package:thesismob/materials/fixtures.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/structural.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

double? companion(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

void main() {
  group('catalog', () {
    test('has 48 materials with unique ids in every category', () {
      expect(allMaterials, hasLength(48));
      expect(allMaterials.map((m) => m.id).toSet(), hasLength(48));
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
        // Every calculator measures its work for the bill of quantities,
        // in work items the costing knows.
        expect(r.works, isNotEmpty, reason: m.id);
        for (final w in r.works) {
          expect(workItemByKey(w.key), isNotNull, reason: '${m.id} ${w.key}');
          expect(w.quantity, greaterThan(0), reason: '${m.id} ${w.key}');
        }
        for (final c in r.companions) {
          if (c.work != null) {
            expect(r.works.map((w) => w.key), contains(c.work), reason: m.id);
          }
        }
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
      expect(companion(r, 'cement_40kg'), 28);
      // 30 × (0.0435 + 2 × 0.016) = 2.265 m³, bought by the half m³.
      expect(companion(r, 'sand'), 2.5);
      // 30 × 4.28 = 128.4 m of bar → 22 bars of 6 m.
      expect(companion(r, 'rebar_10'), 22);

      final bare = run(chb, wall, {'size': '6', 'plaster': '0'});
      expect(companion(bare, 'cement_40kg'), 31); // 30 × 1.018
      expect(companion(bare, 'sand'), 3); // 30 × 0.0844 = 2.53
    });
  });

  group('Plywood', () {
    test('20 m² takes 7 sheets of 1.22 × 2.44 m, 8 with 10% waste', () {
      const surface = {'length': 4.0, 'width': 5.0, 'price': 600.0};
      expect(run(plywood, surface, {'waste': 'none'}).quantity, 7);
      final r = run(plywood, surface);
      expect(r.quantity, 8);
      expect(r.total, 4800);
      expect(r.label, "Plywood 12 mm (½\") 4' × 8'");
      expect(
        run(plywood, surface, {'thickness': '6', 'grade': 'marine'}).label,
        "Marine plywood 6 mm (¼\") 4' × 8'",
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
      expect(companion(r, 'foil_tape'), 2); // 81 m in 50 m rolls
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

  test('totals are rounded to the centavo', () {
    final r = run(faucet, {'quantity': 3, 'price': 0.1});
    expect(r.total, 0.3);
  });
}
