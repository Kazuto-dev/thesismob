import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/fixtures.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/services.dart';

final mep = [
  bulb,
  lightSwitch,
  junctionBox,
  outlet,
  wires,
  utilityBox,
  pvc,
  sink,
  toilet,
  faucet,
  shower,
  roughIn,
  waterTank,
  septicTank,
];

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

/// Quantity of the companion bought from [itemKey], or null if none.
double? bought(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

/// The initial choices, and each option of each choice on top of them.
List<Map<String, String>> variants(MaterialSpec m) => [
  m.initialChoices,
  for (final c in m.choices)
    for (final o in c.options) {...m.initialChoices, c.id: o.id},
];

/// Plain inputs: 3 in every required field shown for [selected].
Map<String, double> plain(MaterialSpec m, Map<String, String> selected) => {
  for (final f in m.visibleNumbers(selected))
    if (!f.optional) f.id: 3.0,
};

void main() {
  group('electrical and plumbing specs', () {
    test('ids are unique; every spec explains itself', () {
      expect(mep.map((m) => m.id).toSet(), hasLength(mep.length));
      for (final m in mep) {
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
        expect(m.priceRef, isNotNull, reason: m.id);
      }
      for (final m in [roughIn, waterTank, septicTank]) {
        expect(m.references, isNotEmpty, reason: m.id);
        expect(m.icon, isNotNull, reason: m.id);
      }
    });

    test('no text says companions are left out of the cost', () {
      for (final m in mep) {
        for (final s in [...m.definitions, ...m.solution]) {
          final text = '${s.body} ${s.formula ?? ''}'.toLowerCase();
          expect(text, isNot(contains('not priced')), reason: m.id);
          expect(text, isNot(contains('not part of the cost')), reason: m.id);
        }
      }
    });

    test('exactly one price field shows for every option', () {
      for (final m in mep) {
        for (final selected in variants(m)) {
          expect(
            m.visibleNumbers(selected).where((f) => f.isPrice),
            hasLength(1),
            reason: '${m.id} $selected',
          );
        }
      }
    });

    test('initial choices are valid options', () {
      for (final m in mep) {
        for (final c in m.choices) {
          if (c.initial != null) {
            expect(c.option(c.initial), isNotNull, reason: '${m.id}.${c.id}');
          }
        }
      }
    });

    test('the price field matches the price book item it is filled from', () {
      for (final m in mep) {
        for (final selected in variants(m)) {
          final ref = m.priceRef!(selected)!;
          final item = itemByKey(ref.itemKey);
          expect(item, isNotNull, reason: '${m.id} ${ref.itemKey}');
          final label = m
              .visibleNumbers(selected)
              .singleWhere((f) => f.isPrice)
              .label;
          final expected = switch (item!.unit) {
            'box' => 'Price per box',
            'm' => 'Price per metre',
            'set' => 'Price per set',
            _ => null,
          };
          if (expected != null) {
            expect(label, expected, reason: '${m.id} $selected');
          } else {
            expect(item.unit, 'pc', reason: '${m.id} $selected');
            expect(label, isNot(contains(' set')), reason: m.id);
            expect(label, isNot(contains(' box')), reason: m.id);
          }
        }
      }
    });

    test('plain inputs calculate; the main item is the one priced', () {
      for (final m in mep) {
        for (final selected in variants(m)) {
          final r = m.calculate(plain(m, selected), selected);
          expect(r.quantity, greaterThan(0), reason: '${m.id} $selected');
          expect(r.total, closeTo(r.quantity * 3, 0.005), reason: m.id);
          expect(itemByKey(r.itemKey ?? ''), isNotNull, reason: m.id);
          expect(
            r.itemKey,
            m.priceRef!(selected)!.itemKey,
            reason: '${m.id} $selected',
          );
          for (final c in r.companions) {
            expect(c.quantity, greaterThan(0), reason: '${m.id} ${c.itemKey}');
            expect(itemByKey(c.itemKey), isNotNull, reason: c.itemKey);
          }
        }
      }
    });

    test('search finds Filipino words', () {
      List<String> find(String q) => [
        for (final m in mep)
          if (m.matches(q)) m.id,
      ];
      expect(find('poso negro'), ['septic_tank']);
      expect(find('kuryente'), contains('rough_in'));
      expect(find('tangke'), containsAll(['water_tank', 'septic_tank']));
      expect(find('TUBO'), contains('pvc'));
      expect(find('gripo'), ['faucet']);
    });
  });

  group('Electrical devices', () {
    test('bulbs by the lumen method, with holders and ceiling boxes', () {
      final r = run(bulb, {'length': 5, 'width': 4, 'price': 120});
      // 150 lx × 20 m² = 3,000 lm ÷ (880 lm × 0.5) = 6.8 → 7 bulbs.
      expect(r.quantity, 7);
      expect(r.total, 840);
      expect(r.itemKey, 'led_bulb_9w');
      expect(bought(r, 'lamp_holder'), 7);
      expect(bought(r, 'junction_box'), 7);

      final counted = run(
        bulb,
        {'quantity': 4, 'price': 150},
        {'mode': 'count', 'watts': '12'},
      );
      expect(counted.itemKey, 'led_bulb_12w');
      expect(bought(counted, 'lamp_holder'), 4);
      expect(bought(counted, 'junction_box'), isNull);
    });

    test('a switch needs a utility box and a plate', () {
      final r = run(lightSwitch, {'quantity': 4, 'price': 60});
      expect(r.itemKey, 'switch');
      expect(r.total, 240);
      expect(bought(r, 'utility_box'), 4);
      expect(bought(r, 'switch_plate'), 4);
    });

    test('boxes are bought on their own', () {
      final j = run(junctionBox, {'quantity': 5, 'price': 30});
      expect(j.itemKey, 'junction_box');
      expect(j.companions, isEmpty);
      expect(
        run(utilityBox, {'quantity': 5, 'price': 25}).itemKey,
        'utility_box',
      );
    });

    test('outlets every 3.6 m of wall, each in a utility box', () {
      final r = run(outlet, {
        'length': 4,
        'width': 3,
        'doors': 0.9,
        'price': 150,
      });
      expect(r.quantity, 4); // 13.1 m ÷ 3.6 = 3.6
      expect(r.itemKey, 'outlet');
      expect(bought(r, 'utility_box'), 4);
      expect(r.note, contains('20 A'));
    });

    test('wire by the box or the metre, with conduit', () {
      final r = run(wires, {'run': 30, 'boxPrice': 5200});
      // 30 m × 3 wires × 1.1 = 99 m → 1 box; 33 m of conduit → 11 lengths.
      expect(r.quantity, 1);
      expect(r.itemKey, 'thhn_3_5_box');
      expect(bought(r, 'conduit_half'), 11);

      final m = run(
        wires,
        {'run': 30, 'price': 40},
        {'buy': 'metre', 'conductors': '2', 'size': '2.0'},
      );
      expect(m.quantity, 66);
      expect(m.itemKey, 'thhn_2_0_m');
      expect(m.total, 2640);
    });
  });

  group('PVC pipe', () {
    test('½" water line: pipes, fittings, solvent cement and tape', () {
      final r = run(pvc, {'run': 24, 'price': 165});
      expect(r.quantity, 9); // 26.4 m ÷ 3 = 8.8
      expect(r.total, 1485);
      expect(r.itemKey, 'pvc_0_5');
      final fittings = r.companions.singleWhere(
        (c) => c.itemKey == 'pvc_fittings',
      );
      expect(fittings.quantity, 1);
      expect(fittings.unitPrice, 594); // 40% of ₱1,485
      expect(bought(r, 'solvent_cement'), 1); // 24 joints ÷ 32
      expect(bought(r, 'teflon_tape'), 1); // 9 pipes ÷ 10
    });

    test('¾" line needs more cement per joint', () {
      final r = run(pvc, {'run': 50, 'price': 120}, {'diameter': '3/4'});
      expect(r.quantity, 19); // 55 ÷ 3 = 18.3
      expect(
        r.companions.singleWhere((c) => c.itemKey == 'pvc_fittings').unitPrice,
        912, // 0.4 × 19 × 120
      );
      expect(bought(r, 'solvent_cement'), 3); // 50 ÷ 21 = 2.4
      expect(bought(r, 'teflon_tape'), 2); // 19 ÷ 10
    });

    test('4" drain: no teflon tape, 3 joints per can', () {
      final r = run(pvc, {'run': 24, 'price': 460}, {'diameter': '4'});
      expect(r.itemKey, 'pvc_4');
      expect(r.quantity, 9);
      expect(
        r.companions.singleWhere((c) => c.itemKey == 'pvc_fittings').unitPrice,
        1656,
      );
      expect(bought(r, 'solvent_cement'), 8); // 24 ÷ 3
      expect(bought(r, 'teflon_tape'), isNull);
      // PPR is only offered for water lines.
      final selected = {...pvc.initialChoices, 'diameter': '4', 'length': '4'};
      expect(pvc.visibleChoices(selected).map((c) => c.id), ['diameter']);
      expect(run(pvc, {'run': 24, 'price': 1}, selected).quantity, 9);
    });

    test('PPR comes in 4 m pipes and needs no solvent cement', () {
      final r = run(pvc, {'run': 24, 'price': 250}, {'length': '4'});
      expect(r.quantity, 7); // 26.4 ÷ 4 = 6.6
      expect(r.itemKey, 'ppr_0_5');
      expect(r.label, 'PPR pipe ½" (20 mm)');
      expect(bought(r, 'solvent_cement'), isNull);
      expect(bought(r, 'teflon_tape'), 1);
      expect(
        pvc.priceRef!({'diameter': '1/2', 'length': '4'})!.itemKey,
        'ppr_0_5',
      );
    });
  });

  group('Plumbing fixtures', () {
    test('a toilet needs a valve, hose, wax ring and bolts', () {
      final r = run(toilet, {'quantity': 2, 'price': 5500});
      expect(r.itemKey, 'toilet');
      expect(r.unit, QuantityUnit.sets);
      expect(r.total, 11000);
      for (final key in [
        'angle_valve',
        'flexible_hose',
        'wax_ring',
        'closet_bolts',
      ]) {
        expect(bought(r, key), 2, reason: key);
      }
    });

    test('a squat bowl is priced per piece without wax ring or bolts', () {
      final r = run(
        toilet,
        {'quantity': 2, 'piecePrice': 1200},
        {'type': 'squat'},
      );
      expect(r.itemKey, 'squat_toilet');
      expect(r.total, 2400);
      expect(bought(r, 'angle_valve'), 2);
      expect(bought(r, 'wax_ring'), isNull);
      expect(bought(r, 'closet_bolts'), isNull);
    });

    test('lavatories and kitchen sinks, with valves, hoses and traps', () {
      final r = run(sink, {'quantity': 3, 'price': 2500}, {'type': 'pedestal'});
      expect(r.total, 7500);
      expect(r.label, 'Lavatory, Pedestal');
      expect(r.itemKey, 'lavatory');
      expect(r.unit, QuantityUnit.sets);
      expect(bought(r, 'angle_valve'), 3);
      expect(bought(r, 'flexible_hose'), 3);
      expect(bought(r, 'p_trap'), 3);

      final k = run(
        sink,
        {'quantity': 2, 'piecePrice': 2500},
        {'use': 'kitchen', 'bowl': 'double', 'supply': 'hot'},
      );
      expect(k.label, 'Kitchen sink, Double bowl');
      expect(k.itemKey, 'kitchen_sink');
      expect(k.total, 5000);
      expect(bought(k, 'angle_valve'), 4);
      expect(bought(k, 'flexible_hose'), 4);
      expect(bought(k, 'p_trap'), 2);
    });

    test('faucets and showers take teflon tape by the joint', () {
      final f = run(faucet, {'quantity': 3, 'price': 700});
      expect(f.itemKey, 'faucet');
      expect(bought(f, 'teflon_tape'), 1);
      // 25 faucets × 2 joints ÷ 40 per roll = 1.25 → 2 rolls.
      expect(
        bought(run(faucet, {'quantity': 25, 'price': 1}), 'teflon_tape'),
        2,
      );
      expect(run(faucet, {'quantity': 3, 'price': 0.1}).total, 0.3);

      final s = run(shower, {'quantity': 2, 'price': 1500});
      expect(s.itemKey, 'shower_set');
      expect(s.unit, QuantityUnit.sets);
      expect(bought(s, 'shower_valve'), 2);
      expect(bought(s, 'floor_drain'), 2);
      expect(bought(s, 'teflon_tape'), 1);
    });
  });

  group('Electrical rough-in', () {
    // A two-storey house: 12 lights, 14 outlets, 2 small aircons and a
    // water heater, 10 m home runs.
    const house = {
      'lights': 12.0,
      'outlets': 14.0,
      'aircons': 2.0,
      'dedicated': 1.0,
      'homeRun': 10.0,
      'price': 3500.0,
    };

    test('circuit schedule and panel size', () {
      final r = run(roughIn, house, {'storeys': '2'});
      expect(detail(r, 'Switches, 1 per 2 lights'), '6');
      expect(detail(r, 'Lighting, 15 A, 2.0 mm²'), '2 circuits');
      expect(detail(r, 'Convenience outlets, 20 A, 3.5 mm²'), '3 circuits');
      expect(detail(r, 'Laundry, 20 A, 3.5 mm²'), '1 circuit');
      expect(detail(r, 'Aircon, up to 1 HP, 20 A, 3.5 mm²'), '2 circuits');
      expect(detail(r, 'Other appliances, 20 A, 3.5 mm²'), '1 circuit');
      expect(detail(r, 'Circuits'), '9 circuits');
      // 9 × 1.25 = 11.25 → 12 spaces → a 12-branch panel.
      expect(detail(r, 'Panel spaces'), '12');
      expect(r.quantity, 1);
      expect(r.itemKey, 'panel_12');
      expect(r.label, 'Electrical rough-in, 9 circuits');
      expect(r.total, 3500);
    });

    test('wire, conduit, boxes, devices and breakers', () {
      final r = run(roughIn, house, {'storeys': '2'});
      // 6.5 m per point on two storeys.
      // 2.0 mm²: (12 + 6) × 6.5 + 2 × 10 = 137 m × 3 × 1.1 = 452.1 m
      //   → 3 boxes + 2.1 m cut.
      expect(detail(r, 'Wire 2.0 mm²'), '452.1 m');
      expect(bought(r, 'thhn_2_0_box'), 3);
      expect(bought(r, 'thhn_2_0_m'), 3);
      // 3.5 mm²: 14 × 6.5 + 4 × 10 + 3 × (6.5 + 10) = 180.5 m → 595.65 m
      //   → 3 boxes + 145.65 m, which is over 100 m → 4 boxes.
      expect(bought(r, 'thhn_3_5_box'), 4);
      expect(bought(r, 'thhn_3_5_m'), isNull);
      // 317.5 m of conduit × 1.1 ÷ 3 = 116.4 → 117 lengths.
      expect(detail(r, 'Conduit run'), '317.5 m');
      expect(bought(r, 'conduit_half'), 117);
      expect(bought(r, 'utility_box'), 23); // 6 + 14 + 2 + 1
      expect(bought(r, 'junction_box'), 12);
      expect(bought(r, 'switch'), 6);
      expect(bought(r, 'switch_plate'), 6);
      expect(bought(r, 'outlet'), 15);
      expect(bought(r, 'aircon_outlet'), 2);
      expect(bought(r, 'breaker_15a'), 2);
      expect(bought(r, 'breaker_20a'), 7);
      expect(bought(r, 'breaker_30a'), isNull);
      expect(bought(r, 'ground_rod'), 1);
      expect(bought(r, 'electrical_tape'), 3); // 9 ÷ 4
    });

    test('big aircons go on 30 A with 5.5 mm² wire', () {
      final r = run(roughIn, house, {'storeys': '2', 'aircon': 'large'});
      expect(detail(r, 'Aircon, 1.5 to 2.5 HP, 30 A, 5.5 mm²'), '2 circuits');
      expect(bought(r, 'breaker_20a'), 5);
      expect(bought(r, 'breaker_30a'), 2);
      // 2 × (6.5 + 10) = 33 m × 3.3 = 108.9 m → 1 box.
      expect(bought(r, 'thhn_5_5_box'), 1);
      // 3.5 mm²: 147.5 m × 3.3 = 486.75 m → 3 boxes + 36.75 m cut.
      expect(bought(r, 'thhn_3_5_box'), 3);
      expect(bought(r, 'thhn_3_5_m'), 37);
    });

    test('a small bungalow still gets two outlet circuits and a laundry', () {
      final r = run(roughIn, {
        'lights': 3,
        'outlets': 3,
        'homeRun': 10,
        'price': 2000,
      });
      // 1 lighting + 2 outlet + 1 laundry = 4 → 5 spaces → 6 branches.
      expect(detail(r, 'Circuits'), '4 circuits');
      expect(detail(r, 'Recommended panel'), '6 branches');
      expect(r.itemKey, 'panel_12', reason: 'the form starts at 12');
      expect(
        run(
          roughIn,
          {'lights': 3, 'outlets': 3, 'homeRun': 10, 'price': 2000},
          {'panel': '6'},
        ).itemKey,
        'panel_6',
      );
      // 2.0 mm²: (3 + 2) × 5 + 10 = 35 m × 3.3 = 115.5 m → 1 box.
      expect(bought(r, 'thhn_2_0_box'), 1);
      expect(bought(r, 'thhn_2_0_m'), isNull);
      // 3.5 mm²: 3 × 5 + 3 × 10 = 45 m × 3.3 = 148.5 m → 1 box.
      expect(bought(r, 'thhn_3_5_box'), 1);
      expect(bought(r, 'switch'), 2);
      expect(bought(r, 'aircon_outlet'), isNull);
      expect(bought(r, 'electrical_tape'), 1);
    });

    test('a chosen panel is used, but must hold the circuits', () {
      expect(run(roughIn, house, {'panel': '16'}).itemKey, 'panel_16');
      expect(roughIn.priceRef!({'panel': '16'})!.itemKey, 'panel_16');
      expect(roughIn.priceRef!(roughIn.initialChoices)!.itemKey, 'panel_12');
      expect(() => run(roughIn, house, {'panel': '8'}), throwsArgumentError);
      expect(
        () => run(roughIn, {...house, 'lights': 100, 'outlets': 100}),
        throwsArgumentError,
      );
    });
  });

  group('Water tank', () {
    test('a day of water for 6 people fits one 1,000 L tank', () {
      final r = run(waterTank, {'persons': 6, 'price': 8000});
      // 6 × 150 L × 1 day = 900 L.
      expect(detail(r, 'Storage for 1 day'), '900 L');
      expect(r.quantity, 1);
      expect(r.itemKey, 'water_tank_1000');
      expect(r.total, 8000);
      expect(bought(r, 'float_valve'), 1);
    });

    test('more days or a smaller tank need more tanks', () {
      expect(
        run(waterTank, {'persons': 6, 'price': 1}, {'days': '2'}).quantity,
        2,
      );
      final big = run(
        waterTank,
        {'persons': 6, 'price': 1},
        {'days': '3', 'size': '2000'},
      );
      expect(big.quantity, 2); // 2,700 L ÷ 2,000
      expect(big.itemKey, 'water_tank_2000');
      expect(bought(big, 'float_valve'), 2);
      // 5 × 200 L = exactly 1,000 L: one tank, not two.
      expect(
        run(waterTank, {'persons': 5, 'price': 1}, {'use': '200'}).quantity,
        1,
      );
    });
  });

  group('Septic tank', () {
    test('capacity by bedrooms, or by people when more', () {
      expect(septicVolumeForBedrooms(1), 2.838);
      expect(septicVolumeForBedrooms(2), 2.838);
      expect(septicVolumeForBedrooms(3), 3.785);
      expect(septicVolumeForBedrooms(4), 4.542);
      expect(septicVolumeForBedrooms(6), 5.678);
      expect(septicVolumeForBedrooms(8), closeTo(6.814, 1e-9));
    });

    test('polyethylene: 2,000 L tanks', () {
      final r = run(
        septicTank,
        {'bedrooms': 3, 'tankPrice': 25000},
        {'type': 'pe'},
      );
      expect(r.quantity, 2); // 3.785 m³ ÷ 2
      expect(r.itemKey, 'septic_tank');
      expect(r.total, 50000);
      expect(r.companions, isEmpty);
      // 30 people × 0.15 = 4.5 m³ beats 2.838 m³ for 2 bedrooms.
      expect(
        run(
          septicTank,
          {'bedrooms': 2, 'persons': 30, 'tankPrice': 1},
          {'type': 'pe'},
        ).quantity,
        3,
      );
    });

    test('block tank for 3 bedrooms', () {
      final r = run(septicTank, {'bedrooms': 3, 'price': 32});
      // W = √(3.785 ÷ 2.4) = 1.256 → 1.30; L = 3.785 ÷ (1.2 × 1.3) = 2.43
      // → 2.45; H = 1.2 + 0.3.
      expect(detail(r, 'Inside size'), '2.45 × 1.3 × 1.5 m');
      // (2 × 3.75 + 0.6) × 1.5 + 1.3 × 1.5 = 14.1 m² → 177 + 9 blocks.
      expect(detail(r, 'Walls with baffle'), '14.1 m²');
      expect(r.quantity, 186);
      expect(r.itemKey, 'chb_6');
      expect(r.total, 5952);
      // Slabs 2.75 × 1.6 × 0.1 × 2 = 0.88 m³; plaster 15.15 m².
      // Cement 0.88 × 9 + 14.1 × 1.018 + 15.15 × 0.192 = 25.2 → 26 bags.
      expect(bought(r, 'cement_40kg'), 26);
      // Sand 0.44 + 1.19 + 0.24 = 1.87 → 2 m³; gravel 0.88 → 1 m³.
      expect(bought(r, 'sand'), 2);
      expect(bought(r, 'gravel'), 1);
      // Slab bars: 18 × 2.75 m (2 per bar) = 9, 30 × 1.6 m (3 per bar)
      // = 10; walls 14.1 × 4.28 ÷ 6 = 10.1 → 11.
      expect(bought(r, 'rebar_10'), 30);
      // 2 × 9 × 15 crossings × 0.30 m ÷ 53 m/kg = 1.53 → 2 kg.
      expect(bought(r, 'tie_wire'), 2);
    });

    test('a large household sizes a bigger block tank', () {
      final r = run(septicTank, {'bedrooms': 2, 'persons': 30, 'price': 1});
      expect(detail(r, 'Liquid capacity'), '4.5 m³');
      expect(detail(r, 'Inside size'), '2.7 × 1.4 × 1.5 m');
      expect(r.quantity, 202);
    });

    test('the block price is hidden for a ready-made tank', () {
      final pe = {...septicTank.initialChoices, 'type': 'pe'};
      expect(
        septicTank.visibleNumbers(pe).singleWhere((f) => f.isPrice).id,
        'tankPrice',
      );
      expect(septicTank.priceRef!(pe)!.itemKey, 'septic_tank');
      expect(septicTank.priceRef!(septicTank.initialChoices)!.itemKey, 'chb_6');
    });
  });
}
