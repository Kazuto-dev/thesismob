import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/calc_helpers.dart';
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

final _specs = [chb, plywood, insulation, ceiling, slab, footing, column, beam];

void main() {
  group('every structural spec', () {
    test('lists only known items', () {
      for (final spec in _specs) {
        final selected = spec.initialChoices;
        final ref = spec.priceRef?.call(selected);
        expect(ref, isNotNull, reason: spec.id);
        expect(itemByKey(ref!.itemKey), isNotNull, reason: spec.id);
      }
    });

    test('shows one price field for every option', () {
      for (final m in _specs) {
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
  });

  group('hollow blocks', () {
    test('10 × 3 m wall of 4" blocks with the usual bars', () {
      final r = run(chb, {'length': 10, 'height': 3, 'price': 24});
      expect(r.quantity, 394);
      expect(r.itemKey, 'chb_4');
      // Laying 30 × 0.522 = 15.66 bags, then plaster 30 × 2 × 0.192 =
      // 11.52 bags, each rounded up on its own.
      expect(lines(r, 'cement_40kg'), [16, 12]);
      // Laying 30 × 0.0435 = 1.305 m³, plaster 30 × 2 × 0.016 = 0.96 m³,
      // each sold by the half m³.
      expect(lines(r, 'sand'), [1.5, 1]);
      // 30 × (2.13 + 2.15) = 128.4 m of 10 mm bar.
      expect(qty(r, 'rebar_10'), 22);
      expect(qty(r, 'tie_wire'), 1);
    });

    test('closer bars and 12 mm bars need more steel', () {
      final r = run(
        chb,
        {'length': 10, 'height': 3, 'price': 24},
        {'bar': '12', 'vertical': '0.4', 'horizontal': '2'},
      );
      // 30 × (2.93 + 3.30) = 186.9 m.
      expect(qty(r, 'rebar_12'), 32);
      expect(qty(r, 'rebar_10'), isNull);
    });

    test('suggests the price of the chosen block', () {
      expect(chb.priceRef!({'size': '6'})!.itemKey, 'chb_6');
    });
  });

  test('plywood grade and thickness pick the price book item', () {
    final r = run(
      plywood,
      {'length': 4, 'width': 3, 'price': 1000},
      {'thickness': '18', 'grade': 'marine'},
    );
    expect(r.itemKey, 'marine_plywood_18');
    expect(r.quantity, 6); // 12 ÷ 2.977 = 4.03 → 5, +10% → 6
  });

  test('insulation buys foil tape by the roll', () {
    final r = run(insulation, {'eave': 10, 'rafter': 4, 'price': 1800});
    expect(r.itemKey, 'foam_roll_50');
    // 10 laps × 4.05 m × 2 sides = 81 m of tape.
    expect(qty(r, 'foil_tape'), 2);
  });

  group('ceiling', () {
    test('20 m² of fiber cement on metal framing', () {
      final r = run(ceiling, {'length': 5, 'width': 4, 'price': 560});
      expect(r.quantity, 8);
      expect(r.itemKey, 'fiber_cement_board');
      expect(qty(r, 'metal_furring'), 11);
      expect(qty(r, 'carrying_channel'), 4);
      expect(qty(r, 'wall_angle'), 6);
      expect(qty(r, 'hanger_wire'), 1);
      expect(qty(r, 'board_screws'), 3);
    });

    test('wood framing buys lumber instead of metal', () {
      final r = run(
        ceiling,
        {'length': 5, 'width': 4, 'price': 500},
        {'frame': 'wood', 'board': 'gypsum_board'},
      );
      expect(r.itemKey, 'gypsum_board');
      expect(qty(r, 'metal_furring'), isNull);
      // (20 × 4.56 + 14 × 1.094) × 1.05 = 111.84 bd ft.
      expect(qty(r, 'good_lumber'), 112);
    });
  });

  group('stock bars', () {
    test('cuts several short bars from one 6 m bar', () {
      expect(stockBars(10, 1.09, 0), 2);
      expect(stockBars(3, 3, 0), 2);
    });

    test('splices bars longer than 6 m', () {
      // 13 runs of 9.92 m with one 0.40 m lap each.
      expect(stockBars(13, 9.92, 0.4), 23);
    });
  });

  group('slab', () {
    test('10 × 5 m slab on fill uses Class B and 40 cm bars', () {
      final r = run(slab, {
        'length': 10,
        'width': 5,
        'thickness': 0.1,
        'price': 240,
      });
      expect(r.itemKey, 'cement_40kg');
      expect(r.unit, QuantityUnit.bags);
      // 5 m³ × 1.05 × 7.5 = 39.4 bags.
      expect(r.quantity, 40);
      expect(qty(r, 'sand'), 3);
      expect(qty(r, 'gravel'), 5.5);
      expect(qty(r, 'gravel_bedding'), 5);
      // 13 runs of 9.92 m (spliced) + 25 runs of 4.92 m.
      expect(qty(r, 'rebar_10'), 48);
      expect(qty(r, 'tie_wire'), 2);
      // Edge forms: 30 m × 0.10 = 3 m² ÷ 2.88 ÷ 3 uses = 0.35 → 1 sheet,
      // with 20.33 bd ft of lumber and 3 × 0.20 = 0.6 kg of nails.
      expect(qty(r, 'marine_plywood_12'), 1);
      expect(qty(r, 'coco_lumber'), 21);
      expect(qty(r, 'nails'), 1);
    });

    test('a suspended slab needs forms and Class A', () {
      final r = run(
        slab,
        {'length': 6, 'width': 4, 'thickness': 0.12, 'price': 240},
        {'type': 'suspended'},
      );
      // 2.88 m³ × 1.05 × 9 = 27.2 bags.
      expect(r.quantity, 28);
      expect(r.label, contains('Class A'));
      // 24 m² ÷ 2.88 = 8.3 sheets, shared by 3 uses: 2.8 → 3.
      expect(qty(r, 'marine_plywood_12'), 3);
      expect(qty(r, 'coco_lumber'), 87); // 3 × 28.8 = 86.4
      expect(qty(r, 'nails'), 5); // 24 × 0.20 = 4.8
      expect(qty(r, 'gravel_bedding'), isNull);
    });

    test('an unreinforced slab buys no bars', () {
      final r = run(
        slab,
        {'length': 3, 'width': 3, 'thickness': 0.1, 'price': 240},
        {'spacing': 'none'},
      );
      expect(qty(r, 'rebar_10'), isNull);
      expect(qty(r, 'tie_wire'), isNull);
    });
  });

  test('footings', () {
    final r = run(footing, {
      'count': 6,
      'length': 1.2,
      'width': 1.2,
      'thickness': 0.25,
      'price': 240,
    });
    // 6 × 0.36 m³ × 1.05 × 9 = 20.4 bags.
    expect(r.quantity, 21);
    // 8 bars each way of 1.05 m: 96 pieces, 5 per 6 m bar.
    expect(qty(r, 'rebar_12'), 20);
    expect(qty(r, 'marine_plywood_12'), isNull);
  });

  test('columns', () {
    final r = run(column, {
      'count': 4,
      'width': 0.3,
      'depth': 0.3,
      'height': 3,
      'price': 240,
    });
    expect(r.quantity, 11); // 1.08 m³ × 1.05 × 9 = 10.2
    expect(qty(r, 'sand'), 1);
    expect(qty(r, 'gravel'), 1.5);
    expect(qty(r, 'rebar_16'), 16); // 3.64 m bars, one per stock bar
    expect(qty(r, 'rebar_10'), 17); // 84 ties of 1.09 m, 5 per bar
    // 84 ties × 4 bars × 0.40 m for 16 mm bars ÷ 53 m per kg = 2.5 kg.
    expect(qty(r, 'tie_wire'), 3);
    expect(qty(r, 'marine_plywood_12'), 2); // 16.8 m² ÷ 2.88 ÷ 3 uses
    expect(qty(r, 'coco_lumber'), 41); // 2 × 20.33
    expect(qty(r, 'nails'), 4); // 16.8 × 0.20
  });

  test('beams', () {
    final r = run(beam, {
      'count': 2,
      'width': 0.25,
      'depth': 0.4,
      'length': 4,
      'price': 240,
    });
    expect(r.quantity, 8); // 0.8 m³ × 1.05 × 9 = 7.56
    // 4.384 m bars, one per stock bar.
    expect(qty(r, 'rebar_16'), 8);
    // 27 stirrups per beam of 1.19 m, 5 per bar.
    expect(qty(r, 'rebar_10'), 11);
    expect(qty(r, 'marine_plywood_12'), 2); // 7.6 m² ÷ 2.88 ÷ 2 uses
  });

  test('companion names come from the price book', () {
    final r = run(column, {
      'count': 1,
      'width': 0.3,
      'depth': 0.3,
      'height': 3,
      'price': 240,
    });
    expect(r.companions.first.name, 'Washed sand');
    expect(r.companions.first.amount, '0.5 m³');
  });

  // Bars weigh d² ÷ 162.2 kg per metre: 0.6165 for 10 mm, 0.8878 for 12 mm
  // and 1.5783 for 16 mm. Concrete is the volume before waste.
  group('bill of quantities works', () {
    test('a plastered 4" wall: blocks, plaster and bars', () {
      final r = run(chb, {'length': 10, 'height': 3, 'price': 24});
      // 30 m² × (2.13 + 2.15) m = 128.4 m × 0.6165 kg = 79.16 kg.
      expect(works(r), [
        (Work.chb4, 30.0),
        (Work.plaster, 60.0),
        (Work.rebar, 79.16),
      ]);
    });

    test('an unplastered 8" wall with openings has no plaster', () {
      final r = run(
        chb,
        {'length': 10, 'height': 3, 'openings': 4, 'price': 45},
        {'size': '8', 'plaster': '0'},
      );
      // 26 m² × 4.28 m = 111.28 m × 0.6165 kg = 68.61 kg.
      expect(works(r), [(Work.chb8, 26.0), (Work.rebar, 68.61)]);
    });

    test('one plastered face of a 6" wall', () {
      final r = run(
        chb,
        {'length': 5, 'height': 2, 'price': 32},
        {'size': '6', 'plaster': '1', 'vertical': '0.4', 'horizontal': '2'},
      );
      // 10 m² × (2.93 + 3.30) m = 62.3 m × 0.6165 kg = 38.41 kg.
      expect(works(r), [
        (Work.chb6, 10.0),
        (Work.plaster, 10.0),
        (Work.rebar, 38.41),
      ]);
    });

    test('a slab on fill: concrete, bars and gravel bed', () {
      final r = run(slab, {
        'length': 10,
        'width': 5,
        'thickness': 0.1,
        'price': 240,
      });
      // 13 runs of 9.92 m with a 0.40 m lap each + 25 runs of 4.92 m =
      // 257.16 m × 0.6165 kg = 158.55 kg. Edge forms 2 × (10 + 5) × 0.10.
      // Bed: 50 m² × 0.10 m.
      expect(works(r), [
        (Work.concreteSlabOnFill, 5.0),
        (Work.rebar, 158.55),
        (Work.formwork, 3.0),
        (Work.gravelBedding, 5.0),
      ]);
    });

    test('a suspended slab: concrete, bars and soffit forms', () {
      final r = run(
        slab,
        {'length': 6, 'width': 4, 'thickness': 0.12, 'price': 240},
        {'type': 'suspended'},
      );
      // 20 runs of 5.96 m + 30 runs of 3.96 m = 238 m × 0.6165 kg.
      expect(works(r), [
        (Work.concreteSlabSuspended, 2.88),
        (Work.rebar, 146.73),
        (Work.formwork, 24.0),
      ]);
    });

    test('an unreinforced slab has no rebar work', () {
      final r = run(
        slab,
        {'length': 3, 'width': 3, 'thickness': 0.1, 'price': 240},
        {'spacing': 'none'},
      );
      // Edge forms 2 × (3 + 3) × 0.10 = 1.2 m².
      expect(works(r), [
        (Work.concreteSlabOnFill, 0.9),
        (Work.formwork, 1.2),
        (Work.gravelBedding, 0.9),
      ]);
    });

    test('footings with side forms', () {
      final r = run(
        footing,
        {
          'count': 6,
          'length': 1.2,
          'width': 1.2,
          'thickness': 0.25,
          'price': 240,
        },
        {'sides': 'plywood'},
      );
      // 96 bars of 1.05 m = 100.8 m × 0.8878 kg = 89.49 kg.
      // Forms: 6 × 2 × (1.2 + 1.2) × 0.25 = 7.2 m².
      expect(works(r), [
        (Work.concreteFooting, 2.16),
        (Work.rebar, 89.49),
        (Work.formwork, 7.2),
      ]);
    });

    test('footings cast against the soil have no formwork', () {
      final r = run(footing, {
        'count': 6,
        'length': 1.2,
        'width': 1.2,
        'thickness': 0.25,
        'price': 240,
      });
      expect(works(r), [(Work.concreteFooting, 2.16), (Work.rebar, 89.49)]);
    });

    test('columns: main bars and ties', () {
      final r = run(column, {
        'count': 4,
        'width': 0.3,
        'depth': 0.3,
        'height': 3,
        'price': 240,
      });
      // 16 bars of 3.64 m × 1.5783 kg = 91.92 kg, plus 84 ties of 1.09 m
      // × 0.6165 kg = 56.45 kg. Forms: 4 × (1.2 + 0.2) × 3 = 16.8 m².
      expect(works(r), [
        (Work.concreteColumn, 1.08),
        (Work.rebar, 148.37),
        (Work.formwork, 16.8),
      ]);
    });

    test('beams: main bars and stirrups', () {
      final r = run(beam, {
        'count': 2,
        'width': 0.25,
        'depth': 0.4,
        'length': 4,
        'price': 240,
      });
      // 8 bars of 4.384 m × 1.5783 kg = 55.35 kg, plus 54 stirrups of
      // 1.19 m × 0.6165 kg = 39.62 kg. Forms: a 100 mm slab on both
      // sides leaves 0.30 m sides: 2 × (2 × 0.3 + 0.25 + 0.1) × 4.
      expect(works(r), [
        (Work.concreteBeam, 0.8),
        (Work.rebar, 94.97),
        (Work.formwork, 7.6),
      ]);
    });

    test('boards and insulation measure the area covered', () {
      expect(works(run(plywood, {'length': 4, 'width': 3, 'price': 700})), [
        (Work.plywood, 12.0),
      ]);
      expect(works(run(ceiling, {'length': 5, 'width': 4, 'price': 560})), [
        (Work.ceiling, 20.0),
      ]);
      // 10 m of eaves × 4 m rafters × 2 sides.
      expect(works(run(insulation, {'eave': 10, 'rafter': 4, 'price': 1800})), [
        (Work.insulation, 80.0),
      ]);
    });
  });
}
