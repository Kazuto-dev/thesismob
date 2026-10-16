import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/core/i18n.dart';
import 'package:thesismob/data/checklists.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/data/unit_prices.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/concrete.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/structural.dart';
import 'package:thesismob/materials/work_items.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

double? qty(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

/// Every line of [itemKey] among [r]'s companions, in order.
List<double> lines(CalcResult r, String itemKey) => [
  for (final c in r.companions)
    if (c.itemKey == itemKey) c.quantity,
];

/// The bill of quantities works of [r], main work first.
List<(String, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity),
];

/// An estimate of [id] priced from the price book, as a project keeps it.
Estimate estimate(
  String id,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) {
  final spec = materialById(id)!;
  final selected = {...spec.initialChoices, ...choices};
  return Estimate.fromResult(
    materialId: id,
    result: spec.calculate(numbers, selected),
    inputs: numbers,
    choices: selected,
    priceOf: (key) => itemByKey(key)?.price ?? 0,
  );
}

// Bars weigh d² ÷ 162.2 kg per metre: 0.6165 for 10 mm, 0.8878 for 12 mm
// and 1.5783 for 16 mm. Concrete is the volume before waste.
void main() {
  group('hollow block mortar and plaster', () {
    test('laying stays with the wall, plaster goes to the plaster', () {
      final r = run(chb, {'length': 10, 'height': 3, 'price': 24});
      final plaster = [
        for (final c in r.companions)
          if (c.work == Work.plaster) (c.itemKey, c.quantity),
      ];
      // 30 m² × 2 faces × 0.192 = 11.52 bags; × 0.016 = 0.96 m³.
      expect(plaster, [('cement_40kg', 12.0), ('sand', 1.0)]);
      final laying = r.companions.where(
        (c) => (c.label ?? '').contains('laying'),
      );
      // 30 × 0.522 = 15.66 bags; 30 × 0.0435 = 1.305 m³.
      expect(
        [for (final c in laying) (c.quantity, c.work)],
        [(16.0, null), (1.5, null)],
      );
    });

    test('an unplastered wall has one cement and one sand line', () {
      final r = run(
        chb,
        {'length': 10, 'height': 3, 'price': 32},
        {'size': '6', 'plaster': '0'},
      );
      expect(lines(r, 'cement_40kg'), [31]); // 30 × 1.018 = 30.54
      expect(lines(r, 'sand'), [3]); // 30 × 0.0844 = 2.53
      expect(r.companions.where((c) => c.work == Work.plaster), isEmpty);
    });

    test('the unit price analyses price the plaster with its own sand', () {
      final e = estimate('chb', {'length': 10, 'height': 3, 'price': 24});
      final analyses = analyseEstimate(e, const CostSettings());
      final byWork = {for (final a in analyses) a.work.key: a};
      expect(byWork[Work.plaster]!.materials.map((m) => m.label), [
        'Cement for plaster',
        'Sand for plaster',
      ]);
      // 12 bags × ₱240 + 1 m³ × ₱1,500.
      expect(byWork[Work.plaster]!.materialCost, 4380);
      expect(
        byWork[Work.chb4]!.materials.map((m) => m.label),
        containsAll(['Cement for laying blocks', 'Sand for laying blocks']),
      );
      expect(
        analyses.fold<double>(0, (s, a) => s + a.materialCost),
        closeTo(e.grandTotal, 0.01),
      );
    });
  });

  group('formwork', () {
    test('slab edges can be entered, or left unformed', () {
      const slabOnFill = {
        'length': 10.0,
        'width': 5.0,
        'thickness': 0.1,
        'price': 240.0,
      };
      final entered = run(slab, {...slabOnFill, 'edge': 12});
      expect(works(entered), contains((Work.formwork, 1.2)));
      final none = run(slab, slabOnFill, {'edges': 'none'});
      expect(works(none).map((w) => w.$1), isNot(contains(Work.formwork)));
      expect(qty(none, 'marine_plywood_12'), isNull);
      // A suspended slab is formed underneath, never at its edges.
      final suspended = run(
        slab,
        {...slabOnFill, 'edge': 12},
        {'type': 'suspended'},
      );
      expect(works(suspended), contains((Work.formwork, 50.0)));
    });

    test('forms can serve 4 pours', () {
      final r = run(
        slab,
        {'length': 6, 'width': 4, 'thickness': 0.12, 'price': 240},
        {'type': 'suspended', 'reuse': '4'},
      );
      expect(qty(r, 'marine_plywood_12'), 3); // 24 ÷ 2.88 ÷ 4 = 2.08
    });

    test('beam sides stop under the slab resting on them', () {
      const beams = {
        'count': 2.0,
        'width': 0.25,
        'depth': 0.4,
        'length': 4.0,
        'price': 240.0,
      };
      double forms(Map<String, String> choices) =>
          works(run(beam, beams, choices))
              .firstWhere((w) => w.$1 == Work.formwork)
              .$2;
      // One side 0.4 − 0.125 = 0.275 m, the other 0.4 m:
      // 2 × (0.275 + 0.4 + 0.25 + 0.10) × 4 = 8.2 m².
      expect(forms({'slab': 'one', 'slabThickness': '0.125'}), 8.2);
      // A roof beam is formed on both full sides: 2 × 1.15 × 4.
      expect(forms({'slab': 'none'}), 9.2);
    });

    test('a suspended slab form costs ₱500–800 per m² with labour', () {
      final e = estimate(
        'slab',
        {'length': 10, 'width': 7, 'thickness': 0.1, 'price': 240},
        {'type': 'suspended'},
      );
      final forms = analyseEstimate(
        e,
        const CostSettings(),
      ).firstWhere((a) => a.work.key == Work.formwork);
      // 9 sheets, 260 bd ft and 14 kg of nails for 70 m² = ₱286.71, plus
      // ₱2,140 a day for 9 m² = ₱237.78.
      expect(forms.unitCost, closeTo(524.49, 0.01));
    });
  });

  group('tie beams', () {
    test('three tie beams in a trench with a gravel bed', () {
      final r = run(
        beam,
        {'count': 3, 'width': 0.2, 'depth': 0.3, 'length': 4, 'price': 240},
        {'type': 'tie'},
      );
      expect(r.label, startsWith('3 tie beams'));
      // 0.72 m³ × 1.05 × 9 = 6.8 bags.
      expect(r.quantity, 7);
      // 12 bars of 4.384 m; 27 stirrups each of 0.89 m, 6 per bar.
      expect(qty(r, 'rebar_16'), 12);
      expect(qty(r, 'rebar_10'), 14);
      // Two sides, no bottom: 3 × (2 × 0.3 + 0.10) × 4 = 8.4 m², ÷ 2.88
      // ÷ 2 uses = 1.46 → 2 sheets with 2 × 18.66 bd ft.
      expect(qty(r, 'marine_plywood_12'), 2);
      expect(qty(r, 'coco_lumber'), 38);
      // Bed 3 × 4 × 0.2 × 0.05 = 0.12 m³, sold by the half m³.
      expect(qty(r, 'gravel_bedding'), 0.5);
      // 12 × 4.384 m × 1.5783 + 81 × 0.89 m × 0.6165 = 127.48 kg. Trench
      // 3 × 4 × 0.8 × 0.35 = 3.36 m³, less 0.72 of beam and 0.12 of bed.
      expect(works(r), [
        (StructureWork.concreteTieBeam, 0.72),
        (Work.rebar, 127.48),
        (Work.formwork, 8.4),
        (Work.gravelBedding, 0.12),
        (Work.excavation, 3.36),
        (Work.backfill, 2.52),
      ]);
    });

    test('without working space nothing is backfilled', () {
      final r = run(
        beam,
        {'count': 1, 'width': 0.2, 'depth': 0.3, 'length': 4, 'price': 240},
        {'type': 'tie', 'space': '0', 'bedding': '0'},
      );
      expect(works(r).map((w) => w.$1), isNot(contains(Work.backfill)));
      expect(works(r), contains((Work.excavation, 0.24)));
    });
  });

  group('wall footings', () {
    const wall = {
      'length': 20.0,
      'width': 0.6,
      'thickness': 0.2,
      'depth': 1.0,
      'price': 240.0,
    };

    test('20 m of 0.60 × 0.20 m footing under a 6" wall', () {
      final r = run(wallFooting, wall);
      // 2.4 m³ × 1.05 = 2.52 m³: 22.7 bags, 1.26 m³ sand, 2.52 m³ gravel.
      expect(r.quantity, 23);
      expect(qty(r, 'sand'), 1.5);
      expect(qty(r, 'gravel'), 3);
      // 100 cross bars of 0.45 m, 13 per 6 m bar.
      expect(qty(r, 'rebar_12'), 8);
      // 4 lengthwise bars of 19.85 m with 3 laps of 0.40 m:
      // 4 × 21.05 ÷ 6 = 14.03.
      expect(qty(r, 'rebar_10'), 15);
      expect(qty(r, 'tie_wire'), 3); // 400 × 0.30 ÷ 53 = 2.26
      expect(qty(r, 'gravel_bedding'), 1.5); // 20 × 0.6 × 0.10 = 1.2
      expect(qty(r, 'marine_plywood_12'), isNull);
      // Rebar 100 × 0.45 × 0.8878 + 84.2 × 0.6165 = 91.86 kg. Trench
      // 20 × 1.2 × 1.0 = 24 m³; backfill 24 − 1.2 bed − 2.4 footing −
      // 20 × 0.15 × 0.7 of wall = 18.3 m³.
      expect(works(r), [
        (Work.concreteFooting, 2.4),
        (Work.rebar, 91.86),
        (Work.gravelBedding, 1.2),
        (Work.excavation, 24.0),
        (Work.backfill, 18.3),
      ]);
    });

    test('side forms line both sides', () {
      final r = run(wallFooting, wall, {'sides': 'plywood'});
      // 2 × 20 × 0.2 = 8 m² ÷ 2.88 ÷ 3 uses → 1 sheet.
      expect(qty(r, 'marine_plywood_12'), 1);
      expect(qty(r, 'coco_lumber'), 21);
      expect(qty(r, 'nails'), 2); // 8 × 0.20 = 1.6
      expect(works(r), contains((Work.formwork, 8.0)));
    });

    test('one bar size is bought as one line', () {
      final r = run(wallFooting, wall, {'longBar': '12'});
      expect(lines(r, 'rebar_12'), [23]); // 8 + 15
    });

    test('the bed must be thinner than the excavation', () {
      expect(
        () => run(wallFooting, {...wall, 'depth': 0.1}),
        throwsArgumentError,
      );
    });
  });

  group('lintels and stiffeners', () {
    const wall = {
      'length': 12.0,
      'height': 2.8,
      'doors': 2.0,
      'doorWidth': 0.9,
      'windows': 3.0,
      'windowWidth': 1.2,
      'price': 240.0,
    };

    test('a 12 m wall of 4" blocks with 2 doors and 3 windows', () {
      final r = run(lintel, wall);
      // Lintels 2 × 1.30 + 3 × 1.60 = 7.4 m × 0.10 × 0.20 = 0.148 m³;
      // sills 3 × 1.60 × 0.10 × 0.10 = 0.048; 4 stiffeners
      // 0.10 × 0.20 × 2.8 = 0.224: 0.42 m³ × 1.05 × 9 = 3.97 bags.
      expect(r.quantity, 4);
      expect(qty(r, 'sand'), 0.5);
      expect(qty(r, 'gravel'), 0.5);
      // 2 bars each: 4 of 1.3 m (1 bar), 6 + 6 of 1.6 m (2 + 2), 8 of
      // 3.2 m (8); 101 ties of 0.61 m, 9 per bar (12). All 10 mm.
      expect(lines(r, 'rebar_10'), [25]);
      expect(qty(r, 'tie_wire'), 2); // 202 × 0.30 ÷ 53 = 1.14
      // Faces 2.96 + soffits 0.54 + sills 0.96 + stiffeners 4.48 =
      // 8.94 m² ÷ 2.88 ÷ 3 = 1.03 → 2 sheets.
      expect(qty(r, 'marine_plywood_12'), 2);
      expect(qty(r, 'coco_lumber'), 41);
      // 50 m of bar and 61.61 m of ties × 0.6165 kg = 68.81 kg.
      expect(works(r), [
        (StructureWork.concreteLintel, 0.42),
        (Work.rebar, 68.81),
        (Work.formwork, 8.94),
      ]);
    });

    test('6" walls take 4 bars per member', () {
      final r = run(lintel, wall, {'size': '6', 'sills': 'none'});
      // 8 + 12 lintel bars and 16 of 3.2 m; 101 ties of 0.71 m, 8 per bar.
      expect(lines(r, 'rebar_10'), [2 + 4 + 16 + 13]);
    });

    test('openings must fit, and something must be measured', () {
      expect(() => run(lintel, {...wall, 'doors': 20}), throwsArgumentError);
      expect(
        () => run(
          lintel,
          {...wall, 'doors': 0, 'windows': 0},
          {'stiffeners': 'none'},
        ),
        throwsArgumentError,
      );
    });
  });

  group('concrete pavement', () {
    const drive = {'length': 8.0, 'width': 3.0, 'price': 240.0};

    test('an 8 × 3 m driveway with bars, joints and curing', () {
      final r = run(pavement, drive);
      // 24 m² × 0.10 × 1.05 = 2.52 m³ of Class A: 22.7 bags.
      expect(r.quantity, 23);
      // 10 runs of 7.92 m with a lap (14 bars) + 27 runs of 2.92 m, 2 per
      // bar (14).
      expect(qty(r, 'rebar_10'), 28);
      expect(qty(r, 'tie_wire'), 2); // 270 × 0.30 ÷ 53 = 1.53
      // Joints every 3 m: 2 across the 3 m width = 6 m × 0.0792 L ÷ 0.6.
      expect(qty(r, 'joint_sealant'), 1);
      expect(qty(r, 'curing_compound'), 2); // 24 × 0.20 ÷ 4 = 1.2
      expect(qty(r, 'gravel_bedding'), 2.5); // 2.4 m³
      // Edges 22 m × 0.10 = 2.2 m² → 1 sheet.
      expect(qty(r, 'marine_plywood_12'), 1);
      // 10 × 8.32 + 27 × 2.92 = 162.04 m × 0.6165 = 99.90 kg.
      expect(works(r), [
        (StructureWork.pavement, 24.0),
        (Work.rebar, 99.9),
        (Work.formwork, 2.2),
        (Work.gravelBedding, 2.4),
      ]);
      expect(r.works.first.effort, 1);
    });

    test('150 mm on mesh, closer joints, no sealant, water cured', () {
      final r = run(pavement, drive, {
        'thickness': '0.15',
        'reinforcement': 'mesh',
        'joints': '2',
        'sealant': 'none',
        'curing': 'water',
        'edges': 'none',
      });
      expect(r.quantity, 35); // 3.6 × 1.05 × 9 = 34.02
      expect(qty(r, 'wire_mesh'), 4); // 24 ÷ 7.9 = 3.04
      expect(qty(r, 'rebar_10'), isNull);
      expect(qty(r, 'joint_sealant'), isNull);
      expect(qty(r, 'curing_compound'), isNull);
      expect(qty(r, 'marine_plywood_12'), isNull);
      // 3 joints across × 3 m + 1 along × 8 m.
      expect(
        r.details.firstWhere((d) => d.label.startsWith('Control')).value,
        '17 m',
      );
      expect(works(r), [
        (StructureWork.pavement, 24.0),
        (Work.gravelBedding, 2.4),
      ]);
      expect(r.works.first.effort, closeTo(1.5, 1e-9));
    });
  });

  group('price book, work items and checklist', () {
    test('new items and work items are known and priced', () {
      for (final i in structureExtrasItems) {
        expect(itemByKey(i.key), same(i), reason: i.key);
        expect(i.price, greaterThan(0), reason: i.key);
        expect(i.estimate, isTrue, reason: i.key);
      }
      for (final w in structureExtrasWorkItems) {
        expect(workItemByKey(w.key), same(w), reason: w.key);
        expect(w.output, greaterThan(0), reason: w.key);
      }
      expect(workItemByKey(StructureWork.concreteTieBeam)!.reference, '900');
      expect(workItemByKey(StructureWork.concreteLintel)!.reference, '900');
      expect(workItemByKey(StructureWork.pavement)!.unit, 'm²');
      expect(workItemByKey(StructureWork.pavement)!.reference, '311');
    });

    test('the house checklist names known calculators, new ones too', () {
      for (final id in houseChecklist.materials) {
        expect(materialById(id), isNotNull, reason: id);
      }
      expect(
        houseChecklist.materials,
        containsAll(['wall_footing', 'lintel', 'pavement']),
      );
    });

    test('the new calculators read in Filipino', () {
      for (final m in structureExtrasMaterials) {
        final texts = [
          m.name,
          m.blurb,
          for (final f in m.numbers) ...[f.label, ?f.hint],
          for (final c in m.choices) ...[c.label, ?c.helper],
        ];
        for (final text in texts) {
          expect(
            translate(text, AppLanguage.filipino),
            isNot(text),
            reason: text,
          );
        }
      }
    });
  });
}
