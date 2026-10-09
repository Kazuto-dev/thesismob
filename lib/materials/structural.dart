import '../core/format.dart';
import 'calc_helpers.dart';
import 'definitions.dart';
import 'material_spec.dart';
import 'solutions.dart';

/// Face area of a standard 40 × 20 cm hollow block, whatever its thickness.
const chbFaceArea = 0.08;

/// A 4' × 8' plywood sheet: 1.2192 m × 2.4384 m.
const plywoodSheetArea = 1.2192 * 2.4384;

/// A 1 m × 50 m roll of PE foam.
const insulationRollArea = 50.0;

final chb = MaterialSpec(
  id: 'chb',
  name: 'Concrete Hollow Blocks',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/chb.png',
  blurb: 'Blocks for a wall, with optional contingency',
  numbers: const [
    NumberField(id: 'length', label: 'Wall length', unit: 'm', max: 10000),
    NumberField(id: 'height', label: 'Wall height', unit: 'm', max: 100),
    NumberField(
      id: 'price',
      label: 'Price per block',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'size',
      label: 'Block size',
      initial: '4',
      helper: 'Thickness does not change the count',
      options: [
        ChoiceOption('4', '4"'),
        ChoiceOption('5', '5"'),
        ChoiceOption('6', '6"'),
      ],
    ),
    contingencyField,
  ],
  compute: (input) {
    final area = input['length'] * input['height'];
    final contingency = input.choice('contingency').value;
    final count = countByArea(area, chbFaceArea, contingency);
    return CalcResult(
      label: 'CHB ${input.choice('size').label}',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.blocks,
      unitPrice: input['price'],
      details: areaDetails(
        area: area,
        unitArea: chbFaceArea,
        count: count,
        contingency: contingency,
        unit: QuantityUnit.blocks,
        unitAreaLabel: 'Face area per block',
      ),
    );
  },
  definitions: materialDefinitions['chb']!,
  solution: materialSolutions['chb']!,
  references: materialReferences['chb'] ?? const [],
);

final plywood = MaterialSpec(
  id: 'plywood',
  name: 'Plywood',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/plywood.png',
  blurb: "4' × 8' sheets for a floor, wall or ceiling",
  numbers: const [
    NumberField(id: 'length', label: 'Area length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Area width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per sheet',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'size',
      label: 'Sheet size',
      initial: '4x8',
      options: [
        ChoiceOption('4x8', "4' × 8' (1.22 × 2.44 m)", plywoodSheetArea),
      ],
    ),
    contingencyField,
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final contingency = input.choice('contingency').value;
    final sheetArea = input.choice('size').value;
    final count = countByArea(area, sheetArea, contingency);
    return CalcResult(
      label: "Plywood 4' × 8'",
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      details: areaDetails(
        area: area,
        unitArea: sheetArea,
        count: count,
        contingency: contingency,
        unit: QuantityUnit.sheets,
        unitAreaLabel: 'Area per sheet',
      ),
    );
  },
  definitions: materialDefinitions['plywood']!,
  solution: materialSolutions['plywood']!,
  references: materialReferences['plywood'] ?? const [],
);

final insulation = MaterialSpec(
  id: 'insulation',
  name: 'Foam Insulation',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/insulation.png',
  blurb: 'PE foam rolls for roofs, walls and ducts',
  numbers: const [
    NumberField(id: 'length', label: 'Area length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Area width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per roll',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'size',
      label: 'Roll size',
      initial: '1x50',
      options: [ChoiceOption('1x50', '1 m × 50 m', insulationRollArea)],
    ),
    ChoiceField(
      id: 'thickness',
      label: 'Thickness',
      initial: notSpecified,
      options: [
        ChoiceOption(notSpecified, 'Not specified'),
        ChoiceOption('2', '2 mm'),
        ChoiceOption('3', '3 mm'),
        ChoiceOption('5', '5 mm'),
        ChoiceOption('10', '10 mm'),
        ChoiceOption('12', '12 mm'),
        ChoiceOption('15', '15 mm'),
        ChoiceOption('20', '20 mm'),
        ChoiceOption('25', '25 mm'),
        ChoiceOption('35', '35 mm'),
        ChoiceOption('40', '40 mm'),
        ChoiceOption('50', '50 mm'),
      ],
    ),
    ChoiceField(
      id: 'type',
      label: 'Type',
      initial: notSpecified,
      options: [
        ChoiceOption(notSpecified, 'Not specified'),
        ChoiceOption('bare', 'Bare'),
        ChoiceOption('foil1', 'Foil on one side'),
        ChoiceOption('foil2', 'Foil on both sides'),
        ChoiceOption('foil_adhesive', 'Foil and adhesive'),
      ],
    ),
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final rollArea = input.choice('size').value;
    final rolls = ceilCount(area / rollArea);
    return CalcResult(
      label: describe('PE foam insulation', [
        input.choice('thickness'),
        input.choice('type'),
      ]),
      area: area,
      quantity: rolls.toDouble(),
      unit: QuantityUnit.rolls,
      unitPrice: input['price'],
      details: [ResultDetail('Area per roll', formatArea(rollArea))],
    );
  },
  definitions: materialDefinitions['insulation']!,
  solution: materialSolutions['insulation']!,
  references: materialReferences['insulation'] ?? const [],
);
