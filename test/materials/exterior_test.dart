import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/core/i18n_fil_exterior.dart';
import 'package:thesismob/data/checklists.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/exterior.dart';
import 'package:thesismob/materials/home_services.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/work_items.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

/// Every companion line bought from [itemKey].
List<Companion> lines(CalcResult r, String itemKey) => [
  for (final c in r.companions)
    if (c.itemKey == itemKey) c,
];

/// Quantity of the first companion bought from [itemKey], or null if none.
double? qty(CalcResult r, String itemKey) =>
    lines(r, itemKey).firstOrNull?.quantity;

/// Quantity of the companion bought from [itemKey] under [label].
double? labelled(CalcResult r, String itemKey, String label) =>
    lines(r, itemKey).where((c) => c.label == label).firstOrNull?.quantity;

/// The bill of quantities works of [r], main work first.
List<(String, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity),
];

/// The initial choices, and each option of each choice on top of them.
List<Map<String, String>> variants(MaterialSpec m) => [
  m.initialChoices,
  for (final c in m.choices)
    for (final o in c.options) {...m.initialChoices, c.id: o.id},
];

final _specs = [...exteriorMaterials, ...homeServicesMaterials];

void main() {
  group('exterior and house services specs', () {
    test('are in the catalog with icons, sources and search words', () {
      expect(_specs.map((m) => m.id), [
        'fence',
        'gate',
        'fascia',
        'soffit',
        'flashing',
        'service_entrance',
        'water_heater',
        'bath_accessories',
      ]);
      for (final m in _specs) {
        expect(materialById(m.id), same(m));
        expect(m.icon, isNotNull, reason: m.id);
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
        expect(m.references, isNotEmpty, reason: m.id);
        for (final s in [...m.definitions, ...m.solution]) {
          final text = '${s.body} ${s.formula ?? ''}'.toLowerCase();
          expect(text, isNot(contains('not priced')), reason: m.id);
        }
      }
      expect(fence.category, MaterialCategory.structural);
      for (final m in [gate, fascia, soffit, flashing]) {
        expect(m.category, MaterialCategory.architectural, reason: m.id);
      }
      expect(serviceEntrance.category, MaterialCategory.electrical);
      expect(waterHeater.category, MaterialCategory.plumbing);
      expect(bathroomAccessories.category, MaterialCategory.plumbing);
    });

    test('every option shows one price field and prices its own item', () {
      for (final m in _specs) {
        for (final selected in variants(m)) {
          expect(
            m.visibleNumbers(selected).where((f) => f.isPrice),
            hasLength(1),
            reason: '${m.id} $selected',
          );
          final ref = m.priceRef!(selected)!;
          expect(itemByKey(ref.itemKey), isNotNull, reason: '$selected');
          final numbers = {
            for (final f in m.visibleNumbers(selected))
              if (!f.optional) f.id: 3.0,
          };
          final r = m.calculate(numbers, selected);
          expect(r.quantity, greaterThan(0), reason: '${m.id} $selected');
          expect(r.total, closeTo(r.quantity * 3, 0.005));
          expect(r.itemKey, ref.itemKey, reason: '${m.id} $selected');
          expect(r.works, isNotEmpty, reason: m.id);
          for (final w in r.works) {
            expect(workItemByKey(w.key), isNotNull, reason: w.key);
            expect(w.quantity, greaterThan(0), reason: w.key);
          }
          for (final c in r.companions) {
            expect(itemByKey(c.itemKey), isNotNull, reason: c.itemKey);
            expect(c.quantity, greaterThan(0), reason: c.itemKey);
            if (c.work != null) {
              expect(r.works.map((w) => w.key), contains(c.work));
            }
          }
        }
      }
    });

    test('new price book items are estimates with unique keys', () {
      final keys = allItems.map((i) => i.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final i in [...exteriorItems, ...homeServicesItems]) {
        expect(itemByKey(i.key), same(i), reason: i.key);
        expect(i.price, greaterThan(0), reason: i.key);
        expect(i.estimate, isTrue, reason: i.key);
      }
      // 9 accessories in 3 grades.
      expect(
        homeServicesItems.where((i) => i.key.startsWith('bath_')),
        hasLength(27),
      );
      expect(itemByKey('bath_set4_standard')!.unit, 'set');
      expect(itemByKey('rsc_pipe_1')!.price, 1300);
    });

    test('new work items have a crew and a daily output', () {
      final expected = {
        ExteriorWork.steelGate: ('m²', 4.0, 1.0, 1.0),
        ExteriorWork.fasciaBoard: ('m', 15.0, 1.0, 1.0),
        ExteriorWork.eavesSoffit: ('m²', 8.0, 1.0, 1.0),
        ExteriorWork.roofFlashing: ('m', 20.0, 1.0, 0.5),
        HomeServiceWork.serviceEntrance: ('set', 1.0, 1.0, 1.0),
        HomeServiceWork.waterHeater: ('set', 2.0, 1.0, 0.5),
        HomeServiceWork.bathAccessory: ('pc', 8.0, 1.0, 0.0),
      };
      final keys = workItems.map((w) => w.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final MapEntry(:key, value: (unit, output, skilled, helpers))
          in expected.entries) {
        final w = workItemByKey(key)!;
        expect(w.unit, unit, reason: key);
        expect(w.output, output, reason: key);
        expect(w.crew.skilled, skilled, reason: key);
        expect(w.crew.helpers, helpers, reason: key);
      }
      expect(workItemByKey(ExteriorWork.steelGate)!.crew.equipment, {
        DailyRates.welding: 1,
      });
    });

    test('search finds Filipino words', () {
      expect(fence.matches('bakod'), isTrue);
      expect(gate.matches('tarangkahan'), isTrue);
      expect(fascia.matches('sinepa'), isTrue);
      expect(serviceEntrance.matches('kontador'), isTrue);
      expect(waterHeater.matches('pampainit'), isTrue);
      expect(bathroomAccessories.matches('tuwalya'), isTrue);
    });

    test('a house checklist includes them', () {
      expect(houseChecklist.materials, containsAll(_specs.map((m) => m.id)));
      for (final id in houseChecklist.materials) {
        expect(materialById(id), isNotNull, reason: id);
      }
    });

    test('every label is translated into Filipino by its exact English', () {
      final english = <String>{
        for (final m in _specs) ...[
          m.name,
          m.blurb,
          for (final f in m.numbers) ...[f.label, ?f.hint],
          for (final c in m.choices) ...[
            c.label,
            ?c.helper,
            for (final o in c.options) o.label,
          ],
        ],
      };
      final shared = <String>{
        for (final m in allMaterials)
          if (!_specs.contains(m)) ...[
            m.name,
            for (final f in m.numbers) ...[f.label, ?f.hint],
            for (final c in m.choices) ...[
              c.label,
              ?c.helper,
              for (final o in c.options) o.label,
            ],
          ],
      };
      for (final key in filipinoExterior.keys) {
        expect(english.contains(key), isTrue, reason: key);
      }
      for (final text in english) {
        // Labels other calculators share are translated in their tables.
        if (shared.contains(text)) continue;
        expect(filipinoExterior.containsKey(text), isTrue, reason: text);
      }
    });
  });

  group('perimeter fence', () {
    const nine = {'length': 9.0, 'height': 2.0, 'price': 30.0};

    test('9 m of 6" fence, 2 m high, with 4 posts', () {
      final r = run(fence, nine);
      // ⌈9 ÷ 3⌉ = 3 bays, 4 posts of 0.20 m. Blocks run from the wall
      // footing, 0.80 − 0.20 = 0.60 m below the ground: (9 − 0.8) × 2.6.
      expect(r.area, closeTo(21.32, 1e-9));
      // ⌈21.32 × 12.5 = 266.5⌉ = 267 + ⌈13.35⌉ = 281.
      expect(r.quantity, 281);
      expect(r.total, 8430);
      expect(r.itemKey, 'chb_6');
      expect(r.label, 'CHB fence 6", 9 m long, 2 m high');

      // Laying 21.32 × 1.018 = 21.70 → 22 bags, with the wall; plaster
      // 9 × 2 × 2 × 0.192 = 6.91 → 7 bags, with the plaster.
      expect(labelled(r, 'cement_40kg', 'Cement for laying'), 22);
      expect(labelled(r, 'cement_40kg', 'Cement for plaster'), 7);
      // 21.32 × 0.0844 = 1.80 m³ → 2; 36 × 0.016 = 0.58 m³ → 1.
      expect(labelled(r, 'sand', 'Sand for laying'), 2);
      expect(labelled(r, 'sand', 'Sand for plaster'), 1);
      expect(
        r.companions.where((c) => c.label == 'Cement for plaster').single.work,
        Work.plaster,
      );
      // Wall footing (9 − 4 × 0.6) × 0.6 × 0.2 = 0.792 m³, post footings
      // 4 × 0.09 = 0.36: 1.152 × 1.05 = 1.2096 m³ of Class A.
      expect(labelled(r, 'cement_40kg', 'Cement for footings'), 11);
      expect(labelled(r, 'sand', 'Sand for footings'), 1);
      expect(labelled(r, 'gravel', 'Gravel for footings'), 1.5);
      // Posts 4 × 0.2² × (2 + 0.8 − 0.25) = 0.408 × 1.05 = 0.4284 m³.
      expect(labelled(r, 'cement_40kg', 'Cement for posts'), 4);
      expect(labelled(r, 'sand', 'Sand for posts'), 0.5);
      expect(labelled(r, 'gravel', 'Gravel for posts'), 0.5);

      // 10 mm: wall 21.32 × 4.28 = 91.25 m → 16; footing 3 × 9.4 m → 5;
      // 17 cross bars of 0.45 m → 2; 32 pad bars of 0.45 m → 3; 52 ties of
      // 0.69 m → 7. 12 mm: 16 bars of 2.85 m, two to a bar → 8.
      expect(qty(r, 'rebar_10'), 33);
      expect(qty(r, 'rebar_12'), 8);
      // Crossings 59.2 + 51 + 64 + 208 = 382.2 × 0.30 ÷ 53 = 2.16 kg.
      expect(qty(r, 'tie_wire'), 3);
      // Forms 4 × 2 × 0.2 × 2.55 = 4.08 m², used 3 times: 1 sheet.
      expect(qty(r, 'marine_plywood_12'), 1);
      expect(qty(r, 'coco_lumber'), 21);
      expect(qty(r, 'nails'), 1);
      expect(qty(r, 'paint_latex'), isNull);

      // Bars: 10 mm 177.38 m × 0.6165 + 12 mm 45.6 m × 0.8878 = 149.84 kg.
      expect(works(r), [
        ('chb_6', 21.32),
        ('plaster', 36.0),
        ('concrete_footing', 1.152),
        ('concrete_column', 0.408),
        ('rebar', 149.84),
        ('formwork', 4.08),
      ]);
      expect(labelled(r, 'cement_40kg', 'Cement for footings'), isNotNull);
      final footing = lines(
        r,
        'cement_40kg',
      ).firstWhere((c) => c.label == 'Cement for footings');
      expect(footing.work, Work.concreteFooting);
    });

    test('latex paint on the plastered faces', () {
      final r = run(fence, nine, {'paint': 'latex'});
      // 36 m²: 0.42 L neutralizer, primer 6.34 L, latex 10.56 L.
      expect(qty(r, 'neutralizer'), 1);
      expect(qty(r, 'primer'), 2);
      expect(qty(r, 'paint_latex'), 3);
      expect(works(r).last, ('painting', 36.0));
      expect(r.works.last.effort, 3);
    });

    test('4" blocks, 10 mm posts and no plaster', () {
      final r = run(fence, nine, {
        'size': '4',
        'postBar': '10',
        'plaster': '0',
      });
      expect(r.itemKey, 'chb_4');
      expect(qty(r, 'rebar_10'), 41); // 33 + 8 post bars
      expect(qty(r, 'rebar_12'), isNull);
      // 21.32 × 0.522 = 11.13 → 12 bags; 21.32 × 0.0435 = 0.93 → 1 m³.
      expect(labelled(r, 'cement_40kg', 'Cement for laying'), 12);
      expect(labelled(r, 'sand', 'Sand for laying'), 1);
      expect(works(r).first, ('chb_4', 21.32));
      expect(r.works.map((w) => w.key), isNot(contains('plaster')));
      // Paint is offered only on plaster.
      expect(
        fence.visibleChoices({...fence.initialChoices, 'plaster': '0'}),
        isNot(contains(predicate<ChoiceField>((c) => c.id == 'paint'))),
      );
    });

    test('a fence must be longer than its posts', () {
      expect(
        () => run(fence, {'length': 0.3, 'height': 2, 'price': 30}),
        throwsArgumentError,
      );
    });
  });

  group('steel gate', () {
    test('a two-leaf swing gate 3 × 1.8 m by the m², painted on site', () {
      final r = run(gate, {
        'width': 3,
        'height': 1.8,
        'count': 1,
        'price': 4500,
      });
      expect(r.quantity, 5.4);
      expect(r.unit, QuantityUnit.squareMetres);
      expect(r.total, 24300);
      expect(r.itemKey, 'steel_gate_m2');
      expect(r.label, 'Steel swing gate, two leaves, 3 × 1.8 m');
      // Over 1.5 m high: 3 hinges on each of 2 leaves.
      expect(qty(r, 'gate_hinge'), 6);
      expect(qty(r, 'drop_bolt'), 2);
      expect(qty(r, 'gate_latch'), 1);
      // Enamel on both faces: 10.8 × 2 ÷ 6.25 × 1.10 = 3.80 L.
      expect(qty(r, 'paint_enamel'), 1);
      expect(qty(r, 'paint_thinner'), 1); // 3.80 ÷ 8 + 0.5 = 0.98 L
      expect(qty(r, 'primer'), isNull);
      expect(works(r), [('steel_gate', 5.4), ('painting', 10.8)]);
    });

    test('a sliding gate on steel posts, priced by the set', () {
      final r = run(
        gate,
        {'width': 4, 'height': 1.5, 'count': 1, 'priceSet': 30000},
        {'type': 'sliding', 'buy': 'set', 'posts': 'steel', 'paint': 'none'},
      );
      expect(r.quantity, 1);
      expect(r.unit, QuantityUnit.sets);
      expect(r.total, 30000);
      expect(r.itemKey, 'steel_gate_set');
      // The leaf is 4 + 2 × 0.10 = 4.2 m long, over 4 m: 3 wheels.
      expect(r.area, closeTo(6.3, 1e-9));
      expect(qty(r, 'gate_wheel'), 3);
      // Track 8.4 m × 1.05 ÷ 6 → 2 angle bars; anchors ⌈8.4 ÷ 0.6⌉ + 1.
      expect(qty(r, 'angle_bar_1_5'), 2);
      expect(qty(r, 'anchor_bolt_10'), 15);
      expect(qty(r, 'gate_guide'), 1);
      expect(qty(r, 'gate_stopper'), 2);
      expect(qty(r, 'gate_hinge'), isNull);
      // Posts 2 × 2.1 m → 1 length; 2 × 0.128 × 1.05 = 0.2688 m³.
      expect(qty(r, 'square_tube_4'), 1);
      expect(qty(r, 'cement_40kg'), 3);
      expect(qty(r, 'sand'), 0.5);
      expect(qty(r, 'gravel'), 0.5);
      expect(works(r), [('steel_gate', 6.3)]);
    });

    test('a low one-leaf gate takes two hinges', () {
      final r = run(
        gate,
        {'width': 1, 'height': 1.2, 'count': 2, 'price': 4000},
        {'type': 'swing1'},
      );
      expect(r.quantity, 2.4);
      expect(r.label, '2 × Steel swing gate, one leaf, 1 × 1.2 m');
      expect(qty(r, 'gate_hinge'), 4);
      expect(qty(r, 'drop_bolt'), 2);
      expect(qty(r, 'gate_latch'), 2);
    });
  });

  group('fascia', () {
    test('20 m of 8" fiber cement', () {
      final r = run(fascia, {'length': 20, 'price': 950});
      // 21 m ÷ 2.44 → 9 strips, 6 to a sheet → 2 sheets.
      expect(r.quantity, 2);
      expect(r.itemKey, 'fiber_cement_board_9');
      expect(r.total, 1900);
      expect(qty(r, 'metal_furring'), 9); // 2 × 21 ÷ 5 = 8.4
      expect(qty(r, 'board_screws'), 2); // 133 screws
      // 4 m² face: primer 0.70 L, latex 1.17 L.
      expect(qty(r, 'primer'), 1);
      expect(qty(r, 'paint_latex'), 1);
      expect(works(r), [('fascia_board', 20.0), ('painting', 4.0)]);
      expect(
        run(fascia, {'length': 20, 'price': 1}, {'width': '6'}).quantity,
        2,
      ); // 8 strips to a sheet
      expect(
        run(fascia, {'length': 20, 'price': 1}, {'width': '10'}).quantity,
        3,
      ); // 4 strips to a sheet
    });

    test('wood boards and enamel', () {
      final r = run(
        fascia,
        {'length': 20, 'priceBoard': 700},
        {'material': 'wood', 'width': '10'},
      );
      // 21 m ÷ 3.66 m → 6 boards.
      expect(r.quantity, 6);
      expect(r.itemKey, 'lumber_1x10_12ft');
      expect(qty(r, 'nails'), 1);
      // 5 m²: primer 0.88 L, enamel 1.76 L, thinner 0.83 L.
      expect(qty(r, 'primer'), 1);
      expect(qty(r, 'paint_enamel'), 1);
      expect(qty(r, 'paint_thinner'), 1);
      expect(works(r), [('fascia_board', 20.0), ('painting', 5.0)]);
    });

    test('pre-painted metal by the metre needs no paint', () {
      final r = run(
        fascia,
        {'length': 20, 'priceMetre': 280},
        {'material': 'metal'},
      );
      expect(r.quantity, 21);
      expect(r.total, 5880);
      expect(qty(r, 'tek_screw'), 100);
      expect(qty(r, 'metal_furring'), 9);
      expect(qty(r, 'paint_latex'), isNull);
      expect(works(r), [('fascia_board', 20.0)]);
    });
  });

  group('eaves soffit', () {
    const eaves = {'length': 30.0, 'overhang': 0.6, 'price': 560.0};

    test('fiber cement on furring, painted', () {
      final r = run(soffit, eaves);
      expect(r.area, closeTo(18, 1e-9));
      // 18 × 1.10 ÷ 2.977 = 6.65 → 7 sheets.
      expect(r.quantity, 7);
      expect(r.itemKey, 'fiber_cement_board');
      // 3 lines × 30 + 26 cross × 0.6 = 105.6 m × 1.05 ÷ 5 = 22.2 → 23.
      expect(qty(r, 'metal_furring'), 23);
      expect(qty(r, 'wall_angle'), 11);
      expect(qty(r, 'board_screws'), 3); // 252 screws
      expect(qty(r, 'primer'), 1);
      expect(qty(r, 'paint_latex'), 2); // 5.28 L
      expect(works(r), [('eaves_soffit', 18.0), ('painting', 18.0)]);
    });

    test('PVC panels, five strips to a panel', () {
      final r = run(
        soffit,
        {'length': 30, 'overhang': 0.6, 'pricePanel': 180},
        {'material': 'pvc'},
      );
      // 150 strips ÷ 5 = 30 panels + 2 for waste.
      expect(r.quantity, 32);
      expect(r.itemKey, 'pvc_soffit_panel');
      // 2 lines × 30 + 26 × 0.6 = 75.6 × 1.05 ÷ 5 = 15.9 → 16.
      expect(qty(r, 'metal_furring'), 16);
      expect(qty(r, 'pvc_soffit_trim'), 21);
      expect(qty(r, 'board_screws'), 3);
      expect(qty(r, 'paint_latex'), isNull);
      expect(works(r), [('eaves_soffit', 18.0)]);
    });

    test('an overhang longer than a panel joins panels', () {
      final r = run(
        soffit,
        {'length': 1, 'overhang': 4, 'pricePanel': 1},
        {'material': 'pvc'},
      );
      // 5 strips × 2 panels = 10, + 1 for waste.
      expect(r.quantity, 11);
    });
  });

  group('roof flashing', () {
    test('10 m of wall flashing, sealed along the wall', () {
      final r = run(flashing, {'length': 10, 'price': 350});
      expect(r.quantity, 5); // ⌈10 ÷ 2.25⌉
      expect(r.total, 1750);
      expect(r.itemKey, 'flashing_wall');
      // 4 laps × 0.30 + 10 m = 11.2 m of bead → 2 tubes.
      expect(qty(r, 'sealant'), 2);
      expect(qty(r, 'tek_screw'), 26);
      expect(qty(r, 'wall_plug'), 26);
      expect(works(r), [('roof_flashing', 10.0)]);
    });

    test('valley and ridge', () {
      final valley = run(
        flashing,
        {'length': 6, 'price': 650},
        {'type': 'valley'},
      );
      expect(valley.quantity, 3);
      expect(qty(valley, 'sealant'), 1); // 2 × 0.60 m
      expect(qty(valley, 'tek_screw'), 32);
      expect(qty(valley, 'wall_plug'), isNull);

      final ridge = run(
        flashing,
        {'length': 2, 'price': 600},
        {'type': 'ridge'},
      );
      expect(ridge.itemKey, 'ridge_roll');
      expect(ridge.quantity, 1);
      expect(qty(ridge, 'sealant'), isNull);
      expect(qty(ridge, 'tek_screw'), 12);
    });
  });
}
