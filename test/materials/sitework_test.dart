import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/sitework.dart';
import 'package:thesismob/materials/work_items.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

double? qty(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

/// The bill of quantities works of [r], main work first.
List<(String, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity),
];

void main() {
  group('every sitework spec', () {
    test('suggests a price book item for every option', () {
      for (final m in siteworkMaterials) {
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
          final ref = m.priceRef?.call(selected);
          expect(itemByKey(ref!.itemKey), isNotNull, reason: '$selected');
        }
      }
    });

    test('new items and work items have unique keys', () {
      final keys = allItems.map((i) => i.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final i in siteworkItems) {
        expect(itemByKey(i.key), same(i), reason: i.key);
        expect(i.price, greaterThan(0), reason: i.key);
      }
      final works = workItems.map((w) => w.key).toList();
      expect(works.toSet(), hasLength(works.length));
      expect(workItemByKey(SiteWork.excavationHard)!.output, 1.5);
      expect(workItemByKey(SiteWork.stairsConcrete)!.reference, '900');
      expect(workItemByKey(SiteWork.steelRailing)!.unit, 'm');
      expect(workItemByKey(SiteWork.steelTruss)!.unit, 'kg');
    });

    test('companions name the works they belong to', () {
      final r = run(railing, {'length': 6, 'price': 400});
      for (final c in r.companions) {
        if (c.work != null) {
          expect(r.works.map((w) => w.key), contains(c.work));
        }
      }
    });
  });

  group('earthworks', () {
    test('six footing pits with working space, a gravel bed and backfill', () {
      final r = run(
        earthworks,
        {
          'count': 6,
          'length': 1.2,
          'width': 1.2,
          'depth': 1.5,
          'structure': 2.835,
          'price': 650,
        },
        {'bedding': '0.1'},
      );
      // Pits 1.8 × 1.8 × 1.5 m: 6 × 4.86 = 29.16 m³ dug. Gravel bed
      // 6 × 1.44 × 0.10 = 0.864 m³. Backfill 29.16 − 2.835 − 0.864 =
      // 25.461 m³. Excess 3.699 m³ × 1.25 = 4.62 m³ loose → 5 m³.
      expect(r.quantity, 5);
      expect(r.unit, QuantityUnit.cubicMetres);
      expect(r.itemKey, 'soil_disposal');
      expect(r.total, 3250);
      expect(detail(r, 'Pit with working space'), '1.8 × 1.8 × 1.5 m');
      expect(detail(r, 'Loose soil to haul'), '4.63 m³');
      expect(detail(r, '6-wheeler loads'), '1 load');
      expect(qty(r, 'gravel_bedding'), 1);
      expect(works(r), [
        (Work.excavation, 29.16),
        (Work.backfill, 25.461),
        (Work.gravelBedding, 0.864),
      ]);
    });

    test('hard soil hauled away entirely, without working space', () {
      final r = run(
        earthworks,
        {'count': 1, 'length': 2, 'width': 1.5, 'depth': 1.2, 'price': 650},
        {'fill': 'haul', 'soil': 'hard', 'space': '0'},
      );
      // 2 × 1.5 × 1.2 = 3.6 m³ × 1.40 = 5.04 m³ loose → 5.5 m³.
      expect(r.quantity, 5.5);
      expect(r.companions, isEmpty);
      expect(works(r), [(SiteWork.excavationHard, 3.6)]);
    });

    test('the structure must fit in the excavation', () {
      expect(
        () => run(earthworks, {
          'count': 1,
          'length': 1,
          'width': 1,
          'depth': 1,
          'structure': 3,
          'price': 650,
        }),
        throwsArgumentError,
      );
    });
  });

  group('stairs', () {
    test('a straight flight 1 m wide rising 3 m', () {
      final r = run(stairs, {'width': 1, 'height': 3, 'price': 240});
      // 18 risers of 16.7 cm, 17 treads of 25 cm: going 4.25 m, slope
      // √(4.25² + 3²) = 5.202 m.
      expect(detail(r, 'Risers of 16.7 cm'), '18');
      expect(detail(r, 'Treads of 25 cm'), '17');
      expect(detail(r, 'Length along the slope'), '5.2 m');
      // Waist 5.202 × 1 × 0.15 = 0.780 m³ + steps ½ × 0.1667 × 0.25 × 17
      // = 0.354 m³ = 1.134 m³; × 1.05 × 9 = 10.7 bags of Class A.
      expect(r.quantity, 11);
      expect(r.itemKey, 'cement_40kg');
      expect(r.unit, QuantityUnit.bags);
      expect(r.total, 2640);
      expect(qty(r, 'sand'), 1); // 0.60 m³
      expect(qty(r, 'gravel'), 1.5); // 1.19 m³
      // 7 main bars of 5.202 + 2 × 0.48 = 6.162 m, spliced with a 0.48 m
      // lap: 7 × 6.642 ÷ 6 = 7.75 → 8 bars of 12 mm.
      expect(qty(r, 'rebar_12'), 8);
      // 21 distribution bars of 0.96 m, 6 per 6 m bar.
      expect(qty(r, 'rebar_10'), 4);
      expect(qty(r, 'tie_wire'), 1); // 147 × 0.30 ÷ 53 = 0.83 kg
      // Forms: soffit 5.202 + risers 3 + sides 2 × 1.134 = 10.47 m².
      expect(qty(r, 'marine_plywood_12'), 4);
      expect(qty(r, 'coco_lumber'), 116); // 4 × 28.8 = 115.2
      expect(qty(r, 'nails'), 3); // 10.47 × 0.20 = 2.09
      // 7 × 6.642 m × 0.8878 + 21 × 0.96 m × 0.6165 = 53.71 kg.
      expect(works(r), [
        (SiteWork.stairsConcrete, 1.134),
        (Work.rebar, 53.71),
        (Work.formwork, 10.47),
      ]);
    });

    test('two flights with a landing, 10 mm bars and Class B', () {
      final r = run(
        stairs,
        {'width': 1.2, 'height': 2.8, 'landing': 1.2, 'price': 240},
        {
          'landings': 'one',
          'riser': '0.18',
          'tread': '0.275',
          'waist': '0.125',
          'class': 'B',
          'bar': '10',
          'spacing': '0.125',
          'waste': '10',
        },
      );
      // 16 risers of 17.5 cm; the landing replaces a tread: 14 treads.
      // Going 3.85 m, slope √(3.85² + 2.8²) = 4.761 m. Concrete: waist
      // 4.761 × 1.2 × 0.125 = 0.714 + steps ½ × 0.175 × 0.275 × 1.2 × 14
      // = 0.404 + landing 1.2 × 1.2 × 0.125 = 0.18 → 1.298 m³.
      expect(detail(r, 'Treads'), '14');
      expect(detail(r, 'Landing'), '1.2 m');
      expect(r.quantity, 11); // 1.298 × 1.10 × 7.5 = 10.7
      expect(qty(r, 'sand'), 1);
      expect(qty(r, 'gravel'), 1.5);
      // 10 main bars of 4.761 + 1.2 + 0.80 = 6.761 m, one 0.40 m lap:
      // 10 × 7.161 ÷ 6 → 12 bars; 24 distribution bars of 1.16 m, 5 per
      // bar → 5 bars; both 10 mm.
      expect(qty(r, 'rebar_10'), 17);
      expect(qty(r, 'rebar_12'), isNull);
      expect(qty(r, 'tie_wire'), 2); // 240 × 0.30 ÷ 53 = 1.36 kg
      // (5.961 × 1.2) + 2.8 × 1.2 + 2 × 1.298 ÷ 1.2 = 12.68 m².
      expect(qty(r, 'marine_plywood_12'), 5);
      expect(works(r), [
        (SiteWork.stairsConcrete, 1.298),
        (Work.rebar, 61.31),
        (Work.formwork, 12.68),
      ]);
    });

    test('a stair must rise at least two steps', () {
      expect(
        () => run(stairs, {'width': 1, 'height': 0.15, 'price': 240}),
        throwsArgumentError,
      );
    });
  });

  group('railing', () {
    test('6 m of balusters in 1" tube on 1½" posts', () {
      final r = run(railing, {'length': 6, 'price': 400});
      // 5 bays of 1.2 m, 6 posts. Each bay is 1.2 − 0.038 = 1.162 m clear:
      // ⌈(1.162 − 0.10) ÷ 0.1254⌉ = 9 balusters of 0.85 m, 45 in all.
      expect(detail(r, 'Posts'), '6');
      expect(detail(r, 'Balusters of 0.85 m'), '45');
      // Rails 12 m + balusters 38.25 m = 50.25 m × 1.05 ÷ 6 = 8.8.
      expect(r.quantity, 9);
      expect(r.unit, QuantityUnit.lengths);
      expect(r.itemKey, 'square_tube_1');
      expect(r.total, 3600);
      expect(qty(r, 'square_tube_1_5'), 2); // 6 posts × 1 m × 1.05
      expect(qty(r, 'base_plate'), 6);
      expect(qty(r, 'anchor_bolt_10'), 24);
      // 6 × 3 + 2 × 45 = 108 joints × 0.02 kg = 2.16 kg.
      expect(detail(r, 'Welded joints'), '108');
      expect(qty(r, 'welding_rod'), 3);
      // 50.25 × 0.1016 + 6 × 0.1524 = 6.02 m²: primer 1.06 L, enamel
      // 2 coats 2.12 L, thinner 0.40 + 0.5 L.
      expect(qty(r, 'red_oxide_primer'), 1);
      expect(qty(r, 'paint_enamel'), 1);
      expect(qty(r, 'paint_thinner'), 1);
      expect(works(r), [(SiteWork.steelRailing, 6.0), (Work.painting, 6.02)]);
      expect(r.works.last.effort, 3);
    });

    test('horizontal rails in 1½" tube share the posts\' tube', () {
      final r = run(
        railing,
        {'length': 4.5, 'price': 600},
        {
          'height': '0.9',
          'posts': '1.5',
          'infill': 'rails',
          'gap': '0.12',
          'tube': '1.5',
        },
      );
      // 3 bays, 4 posts of 0.9 m. ⌈(0.75 − 0.12) ÷ 0.1581⌉ = 4 middle
      // rails: 6 rails × 4.5 m + 3.6 m of posts = 30.6 m × 1.05 ÷ 6 = 5.4.
      expect(detail(r, 'Middle rails'), '4 × 4.5 m');
      expect(r.quantity, 6);
      expect(r.itemKey, 'square_tube_1_5');
      expect(qty(r, 'square_tube_1'), isNull);
      expect(qty(r, 'welding_rod'), 1); // 4 × 7 = 28 joints, 0.56 kg
      expect(works(r), [(SiteWork.steelRailing, 4.5), (Work.painting, 4.66)]);
    });

    test('suggests the price of the chosen tube', () {
      expect(railing.priceRef!({'tube': '1.5'})!.itemKey, 'square_tube_1_5');
    });
  });

  group('trusses', () {
    test('8 m span, 12 m long, 1½" angles at 1.2 m', () {
      final r = run(trusses, {'span': 8, 'length': 12, 'price': 950});
      // ⌊12 ÷ 1.2⌋ + 1 = 11 trusses. Top chords 2 × 4.6 × √(1 + 1/9) =
      // 9.70 m; bottom chord 8 m; Howe webs in 8 panels of 1 m: verticals
      // 5.33 m and diagonals 2 × (1.202 + 1.414 + 1.667) = 8.57 m.
      expect(detail(r, 'Trusses at 1.2 m'), '11 trusses');
      expect(detail(r, 'Top chords'), '9.7 m');
      expect(detail(r, 'Webs, Howe, 8 panels of 1 m'), '13.9 m');
      expect(detail(r, 'Angle bar per truss'), '31.6 m');
      // 11 × 31.596 = 347.56 m × 1.05 ÷ 6 = 60.8 → 61 lengths.
      expect(r.quantity, 61);
      expect(r.unit, QuantityUnit.lengths);
      expect(r.itemKey, 'angle_bar_1_5');
      expect(r.total, 57950);
      // 16 joints per truss.
      expect(qty(r, 'gusset_plate'), 176);
      // 347.56 × 2.68 + 176 × 1.06 = 1,117.98 kg; 2% is 22.4 kg of rod.
      expect(qty(r, 'welding_rod'), 23);
      expect(qty(r, 'anchor_bolt_16'), 44);
      // 347.56 × 0.1524 + 176 × 0.045 = 60.89 m²: 10.7 L of primer and
      // of enamel, thinner 21.4 ÷ 8 + 0.5 = 3.2 L.
      expect(qty(r, 'red_oxide_primer'), 3);
      expect(qty(r, 'paint_enamel'), 3);
      expect(qty(r, 'paint_thinner'), 4);
      expect(works(r), [
        (SiteWork.steelTruss, 1117.98),
        (Work.painting, 60.89),
      ]);
      expect(r.works.last.effort, 2);
    });

    test('steeper roof, no overhang, 2" angles at 1.5 m', () {
      final r = run(
        trusses,
        {'span': 5, 'length': 6, 'price': 1300},
        {'spacing': '1.5', 'pitch': '6', 'overhang': '0', 'angle': '2'},
      );
      // 5 trusses. Top chords 5 × √1.25 = 5.59 m; 6 panels of 0.833 m:
      // verticals 3.75 m, diagonals 5.36 m; 19.70 m per truss, 98.51 m.
      expect(detail(r, 'Angle bar per truss'), '19.7 m');
      expect(r.quantity, 18); // 98.51 × 1.05 ÷ 6 = 17.2
      expect(r.itemKey, 'angle_bar_2');
      expect(qty(r, 'gusset_plate'), 60);
      // 98.51 × 3.63 + 60 × 1.06 = 421.17 kg.
      expect(qty(r, 'welding_rod'), 9);
      expect(works(r), [(SiteWork.steelTruss, 421.17), (Work.painting, 22.72)]);
    });
  });
}
