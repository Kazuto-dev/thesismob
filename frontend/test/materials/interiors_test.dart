import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/interiors.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/work_items.dart';

final _specs = [waterproofing, flooring, cabinets];

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

/// Quantity of the companion bought from [itemKey], or null.
double? qty(CalcResult r, String itemKey) =>
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
  group('interiors specs', () {
    test('are architectural, documented and searchable', () {
      for (final m in _specs) {
        expect(m.category, MaterialCategory.architectural, reason: m.id);
        expect(m.icon, isNotNull, reason: m.id);
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.references, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
      }
      expect(waterproofing.matches('tagas'), isTrue);
      expect(flooring.matches('sahig'), isTrue);
      expect(cabinets.matches('lababo'), isTrue);
    });

    test('new items and work items have unique, known keys', () {
      final keys = {for (final i in allItems) i.key};
      for (final i in interiorsItems) {
        expect(i.price, greaterThan(0), reason: i.key);
        expect(i.estimate, isTrue, reason: i.key);
      }
      expect(keys, hasLength(allItems.length));
      for (final w in interiorsWorkItems) {
        expect(workItemByKey(w.key), same(w), reason: w.key);
        expect(w.output, greaterThan(0), reason: w.key);
        expect(w.trade, MaterialCategory.architectural, reason: w.key);
      }
    });

    test('every combination shows one price field and is priced from its '
        'own item', () {
      for (final m in _specs) {
        for (final selected in combinations(m)) {
          final reason = '${m.id} $selected';
          final prices = m.visibleNumbers(selected).where((f) => f.isPrice);
          expect(prices, hasLength(1), reason: reason);
          final numbers = {
            for (final f in m.visibleNumbers(selected))
              if (!f.optional) f.id: 3.0,
          };
          final r = m.calculate(numbers, selected);
          expect(r.quantity, greaterThan(0), reason: reason);
          expect(r.total, closeTo(r.quantity * 3, 0.005), reason: reason);
          expect(itemByKey(r.itemKey ?? ''), isNotNull, reason: reason);
          expect(m.priceRef!(selected)?.itemKey, r.itemKey, reason: reason);
          expect(r.works, isNotEmpty, reason: reason);
          for (final w in r.works) {
            expect(workItemByKey(w.key), isNotNull, reason: reason);
            expect(w.quantity, greaterThan(0), reason: reason);
          }
          for (final c in r.companions) {
            expect(c.quantity, greaterThan(0), reason: '$reason ${c.itemKey}');
            expect(itemByKey(c.itemKey), isNotNull, reason: reason);
            if (c.work != null) {
              expect(r.works.map((w) => w.key), contains(c.work));
            }
          }
        }
      }
    });
  });

  group('Waterproofing', () {
    // A 6 × 4 m roof deck: 24 m² of floor and a 20 m perimeter.
    const deck = {'length': 6.0, 'width': 4.0};

    test('cementitious coating, 2 coats, with 0.30 m upturns', () {
      final r = run(waterproofing, {...deck, 'joints': 5, 'setPrice': 3200});
      // 24 + 20 × 0.30 = 30 m².
      expect(detail(r, 'Upturn'), '+6 m²');
      expect(detail(r, 'Area to waterproof'), '30 m²');
      expect(r.area, 30);
      // 30 × 2 kg × 2 coats × 1.10 = 132 kg → 5.28 sets of 25 kg.
      expect(detail(r, '2 coats at 2 kg/m²'), '132 kg');
      expect(r.quantity, 6);
      expect(r.unit, QuantityUnit.sets);
      expect(r.itemKey, 'wp_cementitious_set');
      expect(r.total, 19200);
      // (20 + 5) m × 0.20 m × 1.10 = 5.5 m of 1 m wide mesh.
      expect(qty(r, 'wp_mesh'), 6);
      expect(qty(r, 'wp_primer'), isNull);
      expect(r.companions, hasLength(1));
      expect(works(r), [(InteriorsWork.waterproofing, 30.0, 1.0)]);
    });

    test('no upturn and no waste: the floor only', () {
      final r = run(
        waterproofing,
        {'length': 3, 'width': 3, 'setPrice': 3200},
        {'upturn': '0', 'waste': 'none'},
      );
      expect(detail(r, 'Upturn'), isNull);
      // 9 × 2 × 2 = 36 kg → 2 sets; mesh 12 × 0.20 = 2.4 m.
      expect(r.quantity, 2);
      expect(qty(r, 'wp_mesh'), 3);
      expect(works(r), [(InteriorsWork.waterproofing, 9.0, 1.0)]);
    });

    test('liquid membrane, 3 coats, in pails or gallons', () {
      final r = run(
        waterproofing,
        {...deck, 'pailPrice': 5200},
        {'system': 'liquid', 'coats': '3', 'pack': 'pail', 'upturn': '0.15'},
      );
      // 24 + 20 × 0.15 = 27 m²; 27 × 0.5 × 3 × 1.10 = 44.55 L.
      expect(detail(r, '3 coats at 0.5 L/m²'), '44.6 L');
      expect(r.quantity, 3); // 2.78 pails of 16 L
      expect(r.itemKey, 'wp_liquid_pail');
      expect(r.unit, QuantityUnit.pails);
      expect(r.total, 15600);
      // Primer 27 × 0.2 × 1.10 = 5.94 L = 1.49 gallons.
      expect(qty(r, 'wp_primer'), 2);
      expect(qty(r, 'wp_mesh'), 5); // 20 × 0.20 × 1.10 = 4.4 m
      // The crew output is for 2 coats; 3 coats take 1.5 times as long.
      expect(works(r), [(InteriorsWork.waterproofing, 27.0, 1.5)]);

      final gallons = run(
        waterproofing,
        {...deck, 'gallonPrice': 1400},
        {'system': 'liquid', 'coats': '3', 'upturn': '0.15'},
      );
      expect(gallons.quantity, 12); // 44.55 ÷ 4 = 11.14
      expect(gallons.unit, QuantityUnit.gallons);
      expect(gallons.itemKey, 'wp_liquid_gallon');
    });

    test('torch-on membrane: rolls, primer and LPG', () {
      final r = run(
        waterproofing,
        {...deck, 'rollPrice': 3600},
        {'system': 'torch'},
      );
      // 30 m² + 20 m × 0.25 m of corner strips = 35 m², × 1.10 = 38.5 m².
      expect(detail(r, 'Strips 0.25 m wide'), '+5 m²');
      expect(detail(r, 'Membrane'), '38.5 m²');
      // 38.5 ÷ 8.91 = 4.32 rolls.
      expect(r.quantity, 5);
      expect(r.unit, QuantityUnit.rolls);
      expect(r.itemKey, 'wp_torch_roll');
      expect(r.total, 18000);
      // 30 × 0.3 × 1.10 = 9.9 L = 2.48 gallons.
      expect(qty(r, 'wp_bitumen_primer'), 3);
      expect(qty(r, 'wp_lpg_11kg'), 1); // 5 × 2 kg = 10 kg
      expect(qty(r, 'wp_mesh'), isNull);
      expect(works(r), [(InteriorsWork.waterproofingTorch, 30.0, 1.0)]);
    });

    test('suggests the price of the chosen system', () {
      String? key(Map<String, String> s) => waterproofing.priceRef!(s)?.itemKey;
      expect(key(waterproofing.initialChoices), 'wp_cementitious_set');
      expect(key({'system': 'liquid', 'pack': 'gallon'}), 'wp_liquid_gallon');
      expect(key({'system': 'liquid', 'pack': 'pail'}), 'wp_liquid_pail');
      expect(key({'system': 'torch'}), 'wp_torch_roll');
    });
  });

  group('Floor finishes', () {
    test('SPC planks with underlay, skirting and a doorway trim', () {
      final r = run(flooring, {
        'length': 4,
        'width': 3.5,
        'skirting': 13,
        'doorways': 1,
        'spcPrice': 1700,
      });
      // 14 m² × 1.10 = 15.4 m² ÷ 2.2 m² = 7 boxes, not 8 from rounding.
      expect(detail(r, 'With 10% waste'), '15.4 m²');
      expect(r.quantity, 7);
      expect(r.unit, QuantityUnit.boxes);
      expect(r.itemKey, 'floor_spc_box');
      expect(r.label, 'SPC plank flooring, box of 2.2 m²');
      expect(r.total, 11900);
      expect(qty(r, 'floor_underlay_roll'), 1); // 14 × 1.05 ÷ 20
      expect(qty(r, 'floor_skirting'), 6); // 13 × 1.10 ÷ 2.4 = 5.96
      expect(qty(r, 'floor_trim'), 1); // 0.90 ÷ 2.4
      expect(companionWorks(r).values, everyElement(isNull));
      expect(works(r), [(InteriorsWork.plankFlooring, 14.0, 1.0)]);
    });

    test('laminate with a pad attached and the coverage on the box', () {
      const room = {'length': 5.0, 'width': 4.0, 'laminatePrice': 1300.0};
      const choices = {
        'type': 'laminate',
        'waste': '7',
        'underlay': 'attached',
      };
      final r = run(flooring, room, choices);
      // 20 × 1.07 = 21.4 m² ÷ 2.0 m² = 10.7 boxes.
      expect(r.quantity, 11);
      expect(r.itemKey, 'floor_laminate_box');
      expect(r.companions, isEmpty);
      final own = run(flooring, {...room, 'coverage': 1.9}, choices);
      expect(own.quantity, 12); // 21.4 ÷ 1.9 = 11.26
      expect(own.label, 'Laminated wood flooring, box of 1.9 m²');
    });

    test('25 mm topping, 1:2, with hardener', () {
      final r = run(
        flooring,
        {'length': 5, 'width': 4, 'cementPrice': 240},
        {'type': 'topping', 'hardener': 'dry'},
      );
      // 20 m² × 0.025 m × 1.10 = 0.55 m³ of mortar.
      expect(detail(r, 'Mortar 25 mm thick'), '0.55 m³');
      // 0.55 × 18 = 9.9 bags + 20 × 0.025 = 0.5 bags of bond coat.
      expect(r.quantity, 11);
      expect(r.unit, QuantityUnit.bags);
      expect(r.itemKey, 'cement_40kg');
      expect(r.total, 2640);
      expect(qty(r, 'sand'), 1); // 0.55 m³, by the half m³
      expect(qty(r, 'floor_hardener'), 3); // 20 × 3 kg ÷ 25 = 2.4
      expect(works(r), [(InteriorsWork.floorTopping, 20.0, 1.0)]);
    });

    test('a 50 mm 1:3 screed counts twice the work', () {
      final r = run(
        flooring,
        {'length': 5, 'width': 4, 'cementPrice': 240},
        {'type': 'topping', 'thickness': '50', 'mix': '3', 'waste': '5'},
      );
      // 20 × 0.05 × 1.05 = 1.05 m³; 1.05 × 12 + 0.5 = 13.1 bags.
      expect(r.quantity, 14);
      expect(qty(r, 'sand'), 1.5);
      expect(qty(r, 'floor_hardener'), isNull);
      expect(works(r), [(InteriorsWork.floorTopping, 20.0, 2.0)]);
    });

    test('suggests the price of the chosen finish', () {
      String? key(String type) => flooring.priceRef!({'type': type})?.itemKey;
      expect(key('spc'), 'floor_spc_box');
      expect(key('laminate'), 'floor_laminate_box');
      expect(key('topping'), 'cement_40kg');
    });
  });

  group('Cabinets and countertops', () {
    test('made to order: base and wall cabinets with a granite top', () {
      final r = run(cabinets, {'base': 3, 'upper': 2.4, 'lmPrice': 14000});
      expect(r.quantity, 3);
      expect(r.unit, QuantityUnit.metres);
      expect(r.itemKey, 'cabinet_base_lm');
      expect(r.total, 42000);
      expect(qty(r, 'cabinet_upper_lm'), 2.4);
      // 3 m × (0.60 m deep + 0.10 m backsplash) = 2.1 m².
      expect(detail(r, 'Countertop to order'), '2.1 m²');
      expect(qty(r, 'counter_granite_m2'), closeTo(2.1, 1e-9));
      expect(companionWorks(r), {
        'cabinet_upper_lm': null,
        'counter_granite_m2': InteriorsWork.countertop,
      });
      expect(works(r), [
        (InteriorsWork.cabinets, 5.4, 1.0),
        (InteriorsWork.countertop, 3.0, 1.0),
      ]);
    });

    test('a vanity with a quartz top and no backsplash', () {
      final r = run(
        cabinets,
        {'base': 0.8, 'lmPrice': 12000},
        {'top': 'quartz', 'depth': '0.50', 'backsplash': '0'},
      );
      expect(r.quantity, 0.8);
      expect(qty(r, 'counter_quartz_m2'), closeTo(0.4, 1e-9));
      expect(qty(r, 'cabinet_upper_lm'), isNull);
      expect(works(r), [
        (InteriorsWork.cabinets, 0.8, 1.0),
        (InteriorsWork.countertop, 0.8, 1.0),
      ]);
    });

    test('no countertop: cabinets only', () {
      final r = run(cabinets, {'base': 2, 'lmPrice': 14000}, {'top': 'none'});
      expect(r.companions, isEmpty);
      expect(works(r), [(InteriorsWork.cabinets, 2.0, 1.0)]);
    });

    test('built on site with a laminated top', () {
      final r = run(
        cabinets,
        {'base': 3, 'upper': 2.4, 'sheetPrice': 1400},
        {'build': 'site', 'top': 'laminate'},
      );
      // 3 × 3.5 + 2.4 × 2.2 + 2.1 m² top = 17.88 m² × 1.15 ÷ 2.977 = 6.91.
      expect(detail(r, '18 mm panels'), '17.88 m²');
      expect(r.quantity, 7);
      expect(r.unit, QuantityUnit.sheets);
      expect(r.itemKey, 'marine_plywood_18');
      expect(r.total, 9800);
      // Backs: 5.4 × 0.75 × 1.15 ÷ 2.977 = 1.56 sheets.
      expect(qty(r, 'marine_plywood_6'), 2);
      // Laminate: (5.4 + 2.1) × 1.15 ÷ 2.977 = 2.9; glue 7.5 × 0.4 = 3 L.
      expect(qty(r, 'hpl_laminate'), 3);
      expect(qty(r, 'contact_cement'), 3);
      // Edge band: (5.4 × 9 + 3) × 1.10 = 56.76 m in 50 m rolls.
      expect(qty(r, 'edge_band'), 2);
      // Doors: 6 base + 5 wall; drawers: 3.
      expect(detail(r, 'Doors'), '11');
      expect(qty(r, 'cabinet_hinge'), 22);
      expect(qty(r, 'drawer_slide'), 3);
      expect(qty(r, 'cabinet_handle'), 14);
      expect(qty(r, 'nails'), 2); // 5.4 × 0.2 = 1.08 kg
      // The carpenter builds the laminated top, so none is bought.
      expect(qty(r, 'counter_laminate_m2'), isNull);
      expect(works(r), [
        (InteriorsWork.cabinetsBuilt, 5.4, 1.0),
        (InteriorsWork.countertop, 3.0, 1.0),
      ]);
    });

    test('built on site with a granite top from a fabricator', () {
      final r = run(
        cabinets,
        {'base': 2, 'sheetPrice': 1400},
        {'build': 'site'},
      );
      // 2 × 3.5 = 7 m² × 1.15 ÷ 2.977 = 2.7 sheets.
      expect(r.quantity, 3);
      expect(qty(r, 'counter_granite_m2'), closeTo(1.4, 1e-9));
      expect(qty(r, 'marine_plywood_6'), 1); // 0.58
      expect(qty(r, 'hpl_laminate'), 1); // 0.77
      expect(qty(r, 'contact_cement'), 1); // 0.8 L
      expect(qty(r, 'edge_band'), 1); // 19.8 m
      expect(qty(r, 'cabinet_hinge'), 8);
      expect(qty(r, 'drawer_slide'), 2);
      expect(qty(r, 'cabinet_handle'), 6);
      expect(companionWorks(r)['counter_granite_m2'], InteriorsWork.countertop);
      expect(works(r), [
        (InteriorsWork.cabinetsBuilt, 2.0, 1.0),
        (InteriorsWork.countertop, 2.0, 1.0),
      ]);
    });

    test('suggests the price of the chosen build', () {
      expect(
        cabinets.priceRef!({'build': 'order'})?.itemKey,
        'cabinet_base_lm',
      );
      expect(
        cabinets.priceRef!({'build': 'site'})?.itemKey,
        'marine_plywood_18',
      );
    });
  });
}
