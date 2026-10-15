import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/materials/material_spec.dart';

void main() {
  const length = NumberField(
    id: 'length',
    label: 'Wall length',
    unit: 'm',
    max: 10000,
  );
  const coats = NumberField(
    id: 'coats',
    label: 'Number of coats',
    integer: true,
    max: 10,
  );
  const price = NumberField(
    id: 'price',
    label: 'Price per block',
    isPrice: true,
    max: 1000000,
  );

  test('accepts positive numbers with surrounding spaces', () {
    expect(length.validate(' 10.5 '), isNull);
    expect(length.parse(' 10.5 '), 10.5);
  });

  test('explains what is wrong', () {
    expect(length.validate(''), 'Enter a wall length');
    expect(price.validate(''), 'Enter the price per block');
    expect(length.validate('abc'), 'Enter a number, like 2.5');
    expect(length.validate('10,5'), 'Enter a number, like 2.5');
    expect(length.validate('-5'), 'Must be more than 0');
    expect(length.validate('0'), 'Must be more than 0');
    expect(length.validate('1e9'), 'Must be 10,000 or less');
    expect(length.validate('Infinity'), 'Enter a number, like 2.5');
    expect(coats.validate('2.5'), 'Enter a whole number');
    expect(coats.validate('11'), 'Must be 10 or less');
  });

  test('parse returns null for invalid input', () {
    expect(length.parse('abc'), isNull);
    expect(length.parse('-1'), isNull);
  });

  test('optional fields accept empty and zero', () {
    const openings = NumberField(
      id: 'openings',
      label: 'Doors and windows',
      optional: true,
    );
    expect(openings.validate(''), isNull);
    expect(openings.parse(''), 0);
    expect(openings.validate('0'), isNull);
    expect(openings.validate('abc'), 'Enter a number, like 2.5');
  });

  test('fields can depend on a choice', () {
    final byRoom = NumberField(
      id: 'length',
      label: 'Room length',
      visibleWhen: (s) => s['mode'] != 'count',
    );
    expect(byRoom.isVisible(const {'mode': 'room'}), isTrue);
    expect(byRoom.isVisible(const {'mode': 'count'}), isFalse);
  });
}
