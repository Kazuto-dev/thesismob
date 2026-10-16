import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/home_services.dart';
import 'package:thesismob/materials/material_spec.dart';

CalcResult run(
  MaterialSpec spec,
  Map<String, double> numbers, [
  Map<String, String> choices = const {},
]) => spec.calculate(numbers, {...spec.initialChoices, ...choices});

double? qty(CalcResult r, String itemKey) =>
    r.companions.where((c) => c.itemKey == itemKey).firstOrNull?.quantity;

String? workOf(CalcResult r, String itemKey) {
  final c = r.companions.where((c) => c.itemKey == itemKey).firstOrNull;
  return c == null ? null : c.work ?? r.works.first.key;
}

List<(String, double)> works(CalcResult r) => [
  for (final w in r.works) (w.key, w.quantity),
];

void main() {
  group('service entrance', () {
    const house = {
      'riser': 3.0,
      'distance': 5.0,
      'ground': 3.0,
      'price': 160.0,
    };

    test('a 60 A service: 14 mm² wire in a ¾" RSC riser', () {
      final r = run(serviceEntrance, house);
      // Run 3 + 5 = 8 m; each wire 8 × 1.10 + 1.5 = 10.3 m; two → 21 m.
      expect(r.quantity, 21);
      expect(r.unit, QuantityUnit.metres);
      expect(r.itemKey, 'thhn_14_m');
      expect(r.total, 3360);
      expect(qty(r, 'meter_base'), 1);
      expect(qty(r, 'rsc_pipe_0_75'), 3); // 8.8 m in 3 m lengths
      expect(qty(r, 'entrance_cap_0_75'), 1);
      expect(qty(r, 'rsc_coupling_0_75'), 2);
      expect(qty(r, 'rsc_elbow_0_75'), 2);
      expect(qty(r, 'locknut_bushing_0_75'), 3);
      expect(qty(r, 'pipe_strap_0_75'), 7); // ⌈8 ÷ 1.5⌉ + 1
      expect(qty(r, 'thhn_8_0_m'), 4); // 3 × 1.10 = 3.3 m
      expect(qty(r, 'electrical_tape'), 1);
      // The rough-in buys the ground rod; the lump sum is optional.
      expect(qty(r, 'ground_rod'), isNull);
      expect(qty(r, 'utility_connection'), isNull);
      expect(works(r), [('service_entrance', 1.0)]);
    });

    test(
      'a 100 A service in IMC, with ground rod and the utility lump sum',
      () {
        final r = run(
          serviceEntrance,
          {...house, 'riser': 4, 'distance': 12},
          {'main': '100', 'pipe': 'imc', 'groundRod': 'here', 'utility': 'yes'},
        );
        // Run 16 m: 2 × (17.6 + 1.5) = 38.2 → 39 m of 30 mm².
        expect(r.quantity, 39);
        expect(r.itemKey, 'thhn_30_m');
        expect(qty(r, 'imc_pipe_1'), 6); // 17.6 m
        expect(qty(r, 'rsc_coupling_1'), 5);
        expect(qty(r, 'pipe_strap_1'), 12);
        expect(qty(r, 'ground_rod'), 1);
        expect(qty(r, 'utility_connection'), 1);
        expect(
          serviceEntrance.priceRef!({'main': '40'})!.itemKey,
          'thhn_8_0_m',
        );
      },
    );
  });

  group('water heater', () {
    test('two single-point heaters at the showers', () {
      final r = run(waterHeater, {'quantity': 2, 'price': 5500});
      expect(r.quantity, 2);
      expect(r.unit, QuantityUnit.sets);
      expect(r.total, 11000);
      expect(r.itemKey, 'water_heater_single');
      expect(qty(r, 'angle_valve'), 2);
      expect(qty(r, 'flexible_hose'), 2);
      expect(qty(r, 'wall_plug'), 8);
      expect(qty(r, 'teflon_tape'), 1); // 6 joints
      expect(qty(r, 'ppr_0_5'), isNull);
      expect(works(r), [('water_heater', 2.0)]);
    });

    test('a 50 L storage heater with 12 m of insulated PPR', () {
      final r = run(
        waterHeater,
        {'quantity': 1, 'run': 12, 'price': 14000},
        {'type': 'storage', 'tank': '50', 'insulation': 'yes'},
      );
      expect(r.itemKey, 'water_heater_storage_50');
      expect(qty(r, 'flexible_hose'), 2);
      expect(qty(r, 'ppr_0_5'), 4); // 13.2 m in 4 m pipes
      expect(qty(r, 'ppr_fitting_0_5'), 8); // 6 + 2 adapters
      expect(qty(r, 'pipe_insulation_0_5'), 7); // 12.6 m in 2 m
      expect(workOf(r, 'ppr_0_5'), 'piping');
      expect(workOf(r, 'angle_valve'), 'water_heater');
      expect(works(r), [('water_heater', 1.0), ('piping', 12.0)]);
    });

    test('a multi-point heater on ¾" pipe', () {
      final r = run(
        waterHeater,
        {'quantity': 1, 'run': 4, 'price': 1},
        {'type': 'multi', 'diameter': '0_75'},
      );
      expect(r.itemKey, 'water_heater_multi');
      expect(qty(r, 'ppr_0_75'), 2); // 4.4 m
      expect(qty(r, 'ppr_fitting_0_75'), 4);
      expect(qty(r, 'pipe_insulation_0_75'), isNull);
    });
  });

  group('bathroom accessories', () {
    test('three standard bathrooms with mirror, grab bar and curtain rod', () {
      final r = run(
        bathroomAccessories,
        {'bathrooms': 3, 'price': 2200},
        {'grabBars': '1', 'curtain': 'yes'},
      );
      expect(r.quantity, 3);
      expect(r.unit, QuantityUnit.sets);
      expect(r.total, 6600);
      expect(r.itemKey, 'bath_set4_standard');
      expect(qty(r, 'bath_mirror_standard'), 3);
      expect(qty(r, 'bath_grab_bar_standard'), 3);
      expect(qty(r, 'bath_curtain_rod_standard'), 3);
      // 4 + mirror + grab bar + rod = 7 pieces per bathroom.
      expect(works(r), [('bath_accessory', 21.0)]);
    });

    test('a medicine cabinet and the economy grade', () {
      final r = run(
        bathroomAccessories,
        {'bathrooms': 2, 'price': 900},
        {'grade': 'economy', 'mirror': 'cabinet'},
      );
      expect(r.itemKey, 'bath_set4_economy');
      expect(qty(r, 'bath_cabinet_economy'), 2);
      expect(qty(r, 'bath_mirror_economy'), isNull);
      expect(works(r), [('bath_accessory', 10.0)]);
    });

    test('premium grab bars by the piece', () {
      final r = run(
        bathroomAccessories,
        {'quantity': 5, 'pricePiece': 3000},
        {'by': 'piece', 'accessory': 'grab_bar', 'grade': 'premium'},
      );
      expect(r.itemKey, 'bath_grab_bar_premium');
      expect(r.total, 15000);
      expect(r.label, 'Grab bar, premium');
      expect(r.companions, isEmpty);
      expect(works(r), [('bath_accessory', 5.0)]);
    });
  });
}
