import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/professional_fees.dart';

void main() {
  test('UAP Doc 202 minimum basic fees by building group', () {
    expect(BuildingGroup.values.map((g) => g.basicFeePct), [6, 7, 8, 10, 12]);
  });

  test('the four design services make up the minimum basic fee', () {
    for (final g in BuildingGroup.values) {
      final core = [
        DesignService.architectural,
        DesignService.structural,
        DesignService.electrical,
        DesignService.plumbing,
      ].fold<double>(0, (sum, s) => sum + s.percentFor(g));
      expect(core, closeTo(g.basicFeePct, 1e-9), reason: g.name);
    }
    expect(DesignService.supervision.percentFor(BuildingGroup.simple), 1.5);
  });

  test('a house usually needs no mechanical design or supervision', () {
    final house = usualPercents(BuildingGroup.residence);
    expect(house.keys, isNot(contains(DesignService.mechanical)));
    expect(house.keys, isNot(contains(DesignService.supervision)));
    expect(
      usualPercents(BuildingGroup.moderate).keys,
      contains(DesignService.mechanical),
    );
  });

  test('a ₱3.7M house', () {
    final fees = professionalFees(3700000, {
      ...usualPercents(BuildingGroup.residence),
      DesignService.supervision: 1.5,
    });
    expect(fees[DesignService.architectural], 222000);
    expect(fees[DesignService.structural], 74000);
    expect(fees[DesignService.electrical], 37000);
    expect(fees[DesignService.plumbing], 37000);
    expect(fees[DesignService.supervision], 55500);
    expect(fees.values.fold<double>(0, (a, b) => a + b), 425500);
    expect(professionalFees(0, {DesignService.structural: 2}), {
      DesignService.structural: 0,
    });
  });
}
