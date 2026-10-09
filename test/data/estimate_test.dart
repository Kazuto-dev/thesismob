import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/materials/catalog.dart';

void main() {
  // Runs on the VM and in Chrome (CI): ids once used 1 << 32, which is 0
  // in JavaScript and made Random.nextInt throw on the web.
  test('fromResult creates unique ids and keeps the inputs', () {
    final spec = materialById('chb')!;
    final result = spec.calculate(const {
      'length': 10,
      'height': 3,
      'price': 25,
    }, spec.initialChoices);
    final ids = {
      for (var i = 0; i < 50; i++)
        Estimate.fromResult(
          materialId: spec.id,
          result: result,
          inputs: const {'length': 10},
          choices: const {},
        ).id,
    };
    expect(ids, hasLength(50));

    final e = Estimate.fromResult(
      materialId: spec.id,
      result: result,
      inputs: const {'length': 10, 'height': 3, 'price': 25},
      choices: spec.initialChoices,
    );
    expect(e.total, 9375);
    expect(e.toSheetRow(), ['CHB 4"', 30.0, 375.0, 9375.0]);
    expect(Estimate.fromJson(e.toJson()).sameCalculationAs(e), isTrue);
  });
}
