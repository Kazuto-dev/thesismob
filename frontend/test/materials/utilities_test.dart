import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/items.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/utilities.dart';
import 'package:thesismob/materials/work_items.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

/// Quantity of the first companion bought from [itemKey], or null if none.
double? qty(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

/// Every companion line bought from [itemKey].
List<Companion> lines(CalcResult r, String itemKey) => [
  for (final c in r.companions)
    if (c.itemKey == itemKey) c,
];

/// The work [itemKey] was put into: its own, or the main work.
String? workOf(CalcResult r, String itemKey) {
  final c = r.companions.where((c) => c.itemKey == itemKey).firstOrNull;
  return c == null ? null : c.work ?? r.works.first.key;
}

/// The bill of quantities works of [r], main work first.
List<(String, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity),
];

String? detail(CalcResult r, String label) =>
    r.details.where((d) => d.label.startsWith(label)).firstOrNull?.value;

/// The initial choices, and each option of each choice on top of them.
List<Map<String, String>> variants(MaterialSpec m) => [
  m.initialChoices,
  for (final c in m.choices)
    for (final o in c.options) {...m.initialChoices, c.id: o.id},
];

void main() {
  group('utilities specs', () {
    test('are in the catalog with icons, sources and search words', () {
      for (final m in utilitiesMaterials) {
        expect(materialById(m.id), same(m));
        expect(m.icon, isNotNull, reason: m.id);
        expect(m.definitions, isNotEmpty, reason: m.id);
        expect(m.solution, isNotEmpty, reason: m.id);
        expect(m.keywords, isNotEmpty, reason: m.id);
        for (final url in m.references) {
          expect(Uri.parse(url).host, isNotEmpty, reason: '${m.id} $url');
        }
      }
      expect(drainage.category, MaterialCategory.plumbing);
      expect(waterPump.category, MaterialCategory.plumbing);
      expect(auxiliary.category, MaterialCategory.electrical);
      expect(lightFixtures.category, MaterialCategory.electrical);
    });

    test('one price field for every option, filled from a known item', () {
      for (final m in utilitiesMaterials) {
        for (final selected in variants(m)) {
          expect(
            m.visibleNumbers(selected).where((f) => f.isPrice),
            hasLength(1),
            reason: '${m.id} $selected',
          );
          final ref = m.priceRef!(selected)!;
          expect(itemByKey(ref.itemKey), isNotNull, reason: '$selected');
        }
      }
    });

    test('plain inputs price the item the price field suggests', () {
      for (final m in utilitiesMaterials) {
        for (final selected in variants(m)) {
          final numbers = {
            for (final f in m.visibleNumbers(selected))
              if (!f.optional) f.id: 3.0,
          };
          final r = m.calculate(numbers, selected);
          expect(r.quantity, greaterThan(0), reason: '${m.id} $selected');
          expect(r.total, closeTo(r.quantity * 3, 0.005));
          expect(
            r.itemKey,
            m.priceRef!(selected)!.itemKey,
            reason: '$selected',
          );
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
      for (final i in utilitiesItems) {
        expect(i.price, greaterThan(0), reason: i.key);
        expect(i.estimate, isTrue, reason: i.key);
      }
      expect(itemByKey('pvc_6')!.group, ItemGroup.plumbing);
      expect(itemByKey('cat6_box')!.group, ItemGroup.electrical);
    });

    test('new work items have a crew and a daily output', () {
      final expected = {
        UtilityWork.catchBasin: ('set', 1.0, 1.0, 1.0),
        UtilityWork.pumpInstall: ('set', 1.0, 1.0, 1.0),
        UtilityWork.auxPoint: ('pt', 8.0, 1.0, 0.5),
        UtilityWork.cctvCamera: ('set', 4.0, 1.0, 1.0),
      };
      for (final MapEntry(:key, value: (unit, output, skilled, helpers))
          in expected.entries) {
        final w = workItemByKey(key)!;
        expect(w.unit, unit, reason: key);
        expect(w.output, output, reason: key);
        expect(w.crew.skilled, skilled, reason: key);
        expect(w.crew.helpers, helpers, reason: key);
      }
      expect(workItemByKey(UtilityWork.catchBasin)!.reference, '502');
    });

    test('search finds Filipino words', () {
      expect(drainage.matches('imburnal'), isTrue);
      expect(waterPump.matches('bomba'), isTrue);
      expect(auxiliary.matches('cctv'), isTrue);
      expect(lightFixtures.matches('ilaw'), isTrue);
    });
  });

  group('drainage', () {
    test('24 m of 4" drain with 3 block catch basins', () {
      final r = run(drainage, {
        'run': 24,
        'basins': 3,
        'cleanouts': 2,
        'drains': 1,
        'price': 460,
      });
      // 24 × 1.05 = 25.2 m ÷ 3 = 8.4 → 9 pipes.
      expect(r.quantity, 9);
      expect(r.unit, QuantityUnit.pipes);
      expect(r.itemKey, 'pvc_4');
      expect(r.total, 4140);
      expect(r.label, 'PVC drain pipe 4"');
      // Fittings: 0.30 × 9 × 460.
      expect(lines(r, 'pvc_fittings').single.unitPrice, 1242);
      expect(qty(r, 'solvent_cement'), 8); // 24 joints ÷ 3 per can
      expect(qty(r, 'cleanout'), 2);
      expect(lines(r, 'cleanout').single.label, 'Cleanout plug, 4"');
      expect(qty(r, 'floor_drain'), 1);
      // Walls 3 × 4 × 0.55 × 0.60 = 3.96 m² × 12.5 = 49.5 → 50, +5% → 53.
      expect(qty(r, 'chb_4'), 53);
      expect(detail(r, 'Basin walls'), '3.96 m²');
      // 3 × (0.04225 × 9 + 1.32 × 0.522 + 1.08 × 0.192) = 3.83 bags.
      expect(qty(r, 'cement_40kg'), 4);
      // 3 × (0.04225 × 0.5 + 1.32 × 0.0435 + 1.08 × 0.016) = 0.29 m³.
      expect(qty(r, 'sand'), 0.5);
      expect(qty(r, 'gravel'), 0.5); // 3 × 0.04225 = 0.13 m³
      expect(qty(r, 'grating_cast_iron'), 3);
      expect(qty(r, 'catch_basin_box'), isNull);
      expect(works(r), [(Work.piping, 24.0), (UtilityWork.catchBasin, 3.0)]);
      for (final key in ['chb_4', 'cement_40kg', 'sand', 'gravel']) {
        expect(workOf(r, key), UtilityWork.catchBasin, reason: key);
      }
      expect(workOf(r, 'grating_cast_iron'), UtilityWork.catchBasin);
      expect(workOf(r, 'cleanout'), Work.piping);
      expect(workOf(r, 'pvc_fittings'), Work.piping);
    });

    test('6" Series 1000 with precast boxes', () {
      final r = run(
        drainage,
        {'run': 10, 'basins': 2, 'price': 1600},
        {'diameter': '6', 'class': 's1000', 'basin': 'box'},
      );
      expect(r.quantity, 4); // 10.5 ÷ 3 = 3.5
      expect(r.itemKey, 'pvc_s1000_6');
      expect(r.label, 'PVC drain pipe Series 1000 6"');
      expect(lines(r, 'pvc_fittings').single.unitPrice, 1920);
      expect(qty(r, 'solvent_cement'), 10); // 1 joint per 100 cc at 6"
      expect(qty(r, 'catch_basin_box'), 2);
      expect(workOf(r, 'catch_basin_box'), UtilityWork.catchBasin);
      expect(qty(r, 'chb_4'), isNull);
      expect(qty(r, 'grating_cast_iron'), isNull);
      expect(works(r), [(Work.piping, 10.0), (UtilityWork.catchBasin, 2.0)]);
    });

    test('a sanitary line without basins is only piping', () {
      final r = run(drainage, {'run': 6, 'price': 220}, {'diameter': '2'});
      expect(r.quantity, 3); // 6.3 ÷ 3 = 2.1
      expect(r.itemKey, 'pvc_2');
      expect(qty(r, 'solvent_cement'), 1); // 6 joints, 6 per can
      expect(qty(r, 'chb_4'), isNull);
      expect(qty(r, 'cleanout'), isNull);
      expect(works(r), [(Work.piping, 6.0)]);
    });

    test('steel gratings, and the price follows size and class', () {
      final r = run(
        drainage,
        {'run': 6, 'basins': 1, 'price': 460},
        {'grating': 'steel'},
      );
      expect(qty(r, 'grating_steel'), 1);
      expect(qty(r, 'grating_cast_iron'), isNull);
      expect(drainage.priceRef!(drainage.initialChoices)!.itemKey, 'pvc_4');
      expect(
        drainage.priceRef!({'diameter': '3', 'class': 's1000'})!.itemKey,
        'pvc_s1000_3',
      );
      expect(drainage.priceRef!({'diameter': '6'})!.itemKey, 'pvc_6');
      expect(drainage.visibleChoices({'basin': 'box'}).map((c) => c.id), [
        'diameter',
        'class',
        'basin',
      ]);
    });
  });

  group('water pump', () {
    test('3 or 4 bathrooms take a 1 HP jet pump with a 60 L tank', () {
      final r = run(
        waterPump,
        {'distance': 12, 'price': 7500},
        {'bathrooms': '4'},
      );
      expect(r.quantity, 1);
      expect(r.unit, QuantityUnit.sets);
      expect(r.total, 7500);
      expect(r.itemKey, 'jet_pump_1hp');
      expect(r.label, 'Jet pump 1 HP with 60 L pressure tank');
      expect(detail(r, '3 or 4 bathrooms'), '1 HP');
      expect(detail(r, 'One size up'), isNull);
      expect(qty(r, 'pressure_tank_60'), 1);
      expect(qty(r, 'tank_connector'), 1);
      expect(qty(r, 'pressure_switch'), 1);
      expect(qty(r, 'pressure_gauge'), 1);
      expect(qty(r, 'check_valve_1'), 1);
      expect(qty(r, 'gate_valve_1'), 2);
      expect(qty(r, 'union_1'), 2);
      expect(qty(r, 'pump_hose_1'), 2);
      expect(qty(r, 'teflon_tape'), 1); // 21 joints, 40 per roll
      expect(qty(r, 'pump_base'), 1);
      // 12 m × 3 wires × 1.10 = 39.6 m.
      expect(qty(r, 'thhn_3_5_m'), 40);
      expect(qty(r, 'conduit_half'), 5); // 12 × 1.1 ÷ 3 = 4.4
      expect(qty(r, 'breaker_20a'), 1);
      for (final key in ['thhn_3_5_m', 'conduit_half', 'breaker_20a']) {
        expect(workOf(r, key), Work.wiring, reason: key);
      }
      expect(workOf(r, 'pressure_tank_60'), UtilityWork.pumpInstall);
      expect(works(r), [(UtilityWork.pumpInstall, 1.0), (Work.wiring, 39.6)]);
    });

    test('a booster needs no tank; a third storey is one size up', () {
      final r = run(
        waterPump,
        {'distance': 5, 'price': 20000},
        {'type': 'booster', 'storeys': '3'},
      );
      expect(r.itemKey, 'booster_pump_1hp');
      expect(r.label, 'Booster pump 1 HP with built-in controller');
      expect(detail(r, 'Up to 2 bathrooms'), '½ HP');
      expect(detail(r, 'One size up for 3 storeys'), '1 HP');
      for (final key in [
        'pressure_tank_24',
        'pressure_tank_60',
        'pressure_switch',
        'pressure_gauge',
        'tank_connector',
      ]) {
        expect(qty(r, key), isNull, reason: key);
      }
      expect(qty(r, 'teflon_tape'), 1); // 16 joints
      expect(qty(r, 'thhn_3_5_m'), 17); // 16.5 m
      expect(qty(r, 'conduit_half'), 2); // 1.83 lengths
      expect(works(r), [(UtilityWork.pumpInstall, 1.0), (Work.wiring, 16.5)]);
    });

    test('sizes stop at 1½ HP; the smallest is on a 15 A breaker', () {
      final big = run(
        waterPump,
        {'distance': 10, 'price': 11500},
        {'bathrooms': '6', 'storeys': '3'},
      );
      expect(big.itemKey, 'jet_pump_1_5hp');
      expect(qty(big, 'pressure_tank_100'), 1);
      expect(qty(big, 'breaker_20a'), 1);

      final small = run(
        waterPump,
        {'distance': 10, 'price': 4500},
        {'storeys': '1'},
      );
      expect(small.itemKey, 'jet_pump_0_5hp');
      expect(qty(small, 'pressure_tank_24'), 1);
      expect(qty(small, 'breaker_15a'), 1);
      expect(qty(small, 'breaker_20a'), isNull);
    });

    test('the suggested price is the pump the choices size', () {
      String ref(Map<String, String> s) => waterPump.priceRef!(s)!.itemKey;
      expect(ref(waterPump.initialChoices), 'jet_pump_0_5hp');
      expect(
        ref({'type': 'booster', 'bathrooms': '4', 'storeys': '3'}),
        'booster_pump_1_5hp',
      );
      expect(ref({'bathrooms': '4', 'storeys': '2'}), 'jet_pump_1hp');
    });
  });

  group('data, TV and CCTV', () {
    test('a house with data, TV, 4 HD cameras and a doorbell', () {
      final r = run(
        auxiliary,
        {'data': 4, 'tv': 3, 'cameras': 4, 'run': 15, 'price': 30},
        {'doorbell': 'yes'},
      );
      // 4 runs × 15 m × 1.10 = 66 m of CAT6.
      expect(r.quantity, 66);
      expect(r.unit, QuantityUnit.metres);
      expect(r.itemKey, 'cat6_m');
      expect(r.total, 1980);
      expect(qty(r, 'keystone_cat6'), 4);
      expect(qty(r, 'faceplate_keystone'), 7);
      expect(qty(r, 'utility_box'), 8); // 4 data + 3 TV + push button
      expect(qty(r, 'rj45_plug'), 4);
      expect(qty(r, 'network_switch_8'), isNull); // 4 fit the router
      expect(qty(r, 'rg6_m'), 50); // 3 × 16.5 = 49.5 m
      expect(qty(r, 'rg6_box'), isNull);
      expect(qty(r, 'keystone_f'), 3);
      expect(qty(r, 'f_connector'), 7); // 2 × 3 + 1 splitter input
      expect(qty(r, 'tv_splitter_4'), 1);
      expect(qty(r, 'doorbell'), 1);
      expect(qty(r, 'thhn_2_0_m'), 33); // 15 × 2 × 1.10
      // 8 points × 15 × 1.10 = 132 m ÷ 3 = 44 lengths; cameras 66 ÷ 3 = 22.
      expect(lines(r, 'conduit_half').map((c) => c.quantity), [44, 22]);
      expect(qty(r, 'cctv_camera_hd'), 4);
      expect(qty(r, 'dvr_4'), 1);
      expect(qty(r, 'hdd_1tb'), 1);
      expect(qty(r, 'rg59_m'), 66);
      expect(qty(r, 'cctv_connectors'), 4);
      expect(qty(r, 'cctv_psu'), 1);
      expect(qty(r, 'junction_box'), 4);
      expect(qty(r, 'nvr_4'), isNull);
      expect(qty(r, 'poe_switch_4'), isNull);
      for (final key in ['cctv_camera_hd', 'dvr_4', 'hdd_1tb', 'rg59_m']) {
        expect(workOf(r, key), UtilityWork.cctvCamera, reason: key);
      }
      expect(lines(r, 'conduit_half').last.work, UtilityWork.cctvCamera);
      expect(workOf(r, 'rg6_m'), UtilityWork.auxPoint);
      expect(works(r), [
        (UtilityWork.auxPoint, 8.0),
        (UtilityWork.cctvCamera, 4.0),
      ]);
    });

    test('IP cameras run on CAT6 bought by the box, with NVR and PoE', () {
      final r = run(
        auxiliary,
        {'data': 6, 'cameras': 6, 'run': 20, 'boxPrice': 7500},
        {'cctv': 'ip', 'buy': 'box'},
      );
      // (6 + 6) × 20 × 1.10 = 264 m → 1 box of 305 m.
      expect(r.quantity, 1);
      expect(r.unit, QuantityUnit.boxes);
      expect(r.itemKey, 'cat6_box');
      expect(r.total, 7500);
      expect(detail(r, 'CAT6, runs'), '264 m');
      expect(qty(r, 'network_switch_8'), 1); // 6 data outlets
      expect(qty(r, 'cctv_camera_ip'), 6);
      expect(qty(r, 'nvr_8'), 1);
      expect(qty(r, 'hdd_2tb'), 1);
      expect(qty(r, 'poe_switch_8'), 1);
      expect(lines(r, 'rj45_plug').map((c) => c.quantity), [6, 12]);
      expect(qty(r, 'rg59_m'), isNull);
      expect(qty(r, 'cctv_psu'), isNull);
      expect(qty(r, 'rg6_m'), isNull);
      expect(qty(r, 'doorbell'), isNull);
      expect(lines(r, 'conduit_half').map((c) => c.quantity), [44, 44]);
      expect(works(r), [
        (UtilityWork.auxPoint, 6.0),
        (UtilityWork.cctvCamera, 6.0),
      ]);
    });

    test('many cameras and long coax runs fill boxes', () {
      final r = run(auxiliary, {
        'data': 1,
        'tv': 10,
        'cameras': 20,
        'run': 20,
        'price': 30,
      });
      expect(qty(r, 'dvr_16'), 2);
      expect(qty(r, 'hdd_4tb'), 2);
      expect(qty(r, 'cctv_psu'), 5);
      // 20 × 22 m = 440 m: a box and 135 m cut.
      expect(qty(r, 'rg59_box'), 1);
      expect(qty(r, 'rg59_m'), 135);
      // 10 × 22 m = 220 m: 200 m or more left buys a box.
      expect(qty(r, 'rg6_box'), 1);
      expect(qty(r, 'rg6_m'), isNull);
      expect(qty(r, 'tv_splitter_4'), 3);
      expect(qty(r, 'f_connector'), 23);
    });

    test('recorders by channel count', () {
      expect(recordersFor(1), (channels: 4, count: 1));
      expect(recordersFor(4), (channels: 4, count: 1));
      expect(recordersFor(5), (channels: 8, count: 1));
      expect(recordersFor(9), (channels: 16, count: 1));
      expect(recordersFor(17), (channels: 16, count: 2));
    });

    test('data outlets alone need no CCTV work', () {
      final r = run(auxiliary, {'data': 2, 'run': 10, 'price': 30});
      expect(r.quantity, 22);
      expect(qty(r, 'tv_splitter_4'), isNull);
      expect(qty(r, 'junction_box'), isNull);
      expect(works(r), [(UtilityWork.auxPoint, 2.0)]);
    });
  });

  group('lighting fixtures', () {
    test('a 5 × 4 m living room takes 9 downlights of 750 lm', () {
      final r = run(lightFixtures, {'length': 5, 'width': 4, 'price': 280});
      // 150 lx × 20 m² = 3,000 lm ÷ (750 × 0.6 × 0.8 = 360) = 8.3 → 9.
      expect(r.quantity, 9);
      expect(r.area, 20);
      expect(r.itemKey, 'led_downlight_4');
      expect(r.label, 'LED downlight 4", 9 W');
      expect(r.total, 2520);
      expect(detail(r, 'Useful light per fixture'), '360 lm');
      expect(detail(r, 'Lighting load'), '81 W');
      expect(qty(r, 'flex_conduit_m'), 14); // 9 × 1.5 = 13.5 m
      expect(qty(r, 'thhn_2_0_m'), 27); // 9 × 1.5 × 2
      expect(works(r), [(Work.lightFixture, 9.0)]);
    });

    test('brighter rooms and other fixtures', () {
      // 300 lx × 12 m² ÷ (1,800 × 0.48 = 864) = 4.2 → 5 battens.
      final kitchen = run(
        lightFixtures,
        {'length': 3, 'width': 4, 'price': 480},
        {'room': 'kitchen', 'type': 'batten'},
      );
      expect(kitchen.quantity, 5);
      expect(kitchen.itemKey, 'led_batten');
      // 500 lx × 9 m² ÷ (1,000 × 0.48) = 9.4 → 10.
      final study = run(
        lightFixtures,
        {'length': 3, 'width': 3, 'price': 420},
        {'room': 'study', 'type': 'downlight_6'},
      );
      expect(study.quantity, 10);
      // 100 lx × 9 m² ÷ (2,000 × 0.48) = 0.94 → 1.
      final bedroom = run(
        lightFixtures,
        {'length': 3, 'width': 3, 'price': 950},
        {'room': 'bedroom', 'type': 'ceiling_lamp'},
      );
      expect(bedroom.quantity, 1);
      expect(bedroom.itemKey, 'led_ceiling_lamp');
    });

    test('a count of fixtures is priced as entered', () {
      final r = run(
        lightFixtures,
        {'quantity': 6, 'price': 180},
        {'mode': 'count', 'type': 'pin_light'},
      );
      expect(r.quantity, 6);
      expect(r.area, isNull);
      expect(r.itemKey, 'led_pin_light');
      expect(qty(r, 'flex_conduit_m'), 9);
      expect(qty(r, 'thhn_2_0_m'), 18);
      expect(works(r), [(Work.lightFixture, 6.0)]);
      expect(
        lightFixtures.priceRef!({'type': 'pin_light'})!.itemKey,
        'led_pin_light',
      );
    });
  });
}
