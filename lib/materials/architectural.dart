import '../core/format.dart';
import 'calc_helpers.dart';
import 'definitions.dart';
import 'material_spec.dart';
import 'solutions.dart';

/// Litres in a US gallon, the unit used on the original paint calculator.
const litresPerGallon = 3.785;

/// Width of one corrugation pitch on standard corrugated GI sheets (3 in).
const corrugationPitch = 0.0762;

final paint = MaterialSpec(
  id: 'paint',
  name: 'Paint',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/paint.png',
  blurb: 'Gallons for a wall or ceiling, by coats and coverage',
  numbers: const [
    NumberField(id: 'length', label: 'Area length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Area width', unit: 'm', max: 10000),
    NumberField(
      id: 'coats',
      label: 'Number of coats',
      hint: 'Usually 2',
      integer: true,
      max: 10,
    ),
    NumberField(
      id: 'coverage',
      label: 'Coverage',
      unit: 'sqm/L',
      hint: 'Printed on the can',
      max: 100,
    ),
    NumberField(
      id: 'price',
      label: 'Price per gallon',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final coats = input['coats'];
    final litres = area * coats / input['coverage'];
    final gallons = litres / litresPerGallon;
    final cans = ceilCount(gallons);
    final coatLabel = coats == 1 ? '1 coat' : '${formatNumber(coats)} coats';
    return CalcResult(
      label: 'Paint, $coatLabel',
      area: area,
      quantity: cans.toDouble(),
      unit: QuantityUnit.gallons,
      unitPrice: input['price'],
      details: [
        ResultDetail('Paint needed', '${formatNumber(litres)} L'),
        ResultDetail('In gallons (3.785 L each)', formatNumber(gallons)),
      ],
    );
  },
  definitions: materialDefinitions['paint']!,
  solution: materialSolutions['paint']!,
  references: materialReferences['paint'] ?? const [],
);

final tiles = MaterialSpec(
  id: 'tiles',
  name: 'Tiles',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/tiles.png',
  blurb: 'Floor or wall tiles for a room',
  numbers: const [
    NumberField(id: 'length', label: 'Room length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Room width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per tile',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'size',
      label: 'Tile size',
      options: [
        ChoiceOption('15w', '15 × 15 cm wall', 0.0225),
        ChoiceOption('20w', '20 × 20 cm wall', 0.04),
        ChoiceOption('20x30w', '20 × 30 cm wall', 0.06),
        ChoiceOption('15f', '15 × 15 cm floor', 0.0225),
        ChoiceOption('20f', '20 × 20 cm floor', 0.04),
        ChoiceOption('30f', '30 × 30 cm floor', 0.09),
        ChoiceOption('40f', '40 × 40 cm floor', 0.16),
        ChoiceOption('60f', '60 × 60 cm floor', 0.36),
      ],
    ),
    contingencyField,
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final size = input.choice('size');
    final contingency = input.choice('contingency').value;
    final count = countByArea(area, size.value, contingency);
    return CalcResult(
      label: 'Tiles ${size.label}',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      details: areaDetails(
        area: area,
        unitArea: size.value,
        count: count,
        contingency: contingency,
        unit: QuantityUnit.pieces,
        unitAreaLabel: 'Area per tile',
      ),
    );
  },
  definitions: materialDefinitions['tiles']!,
  solution: materialSolutions['tiles']!,
  references: materialReferences['tiles'] ?? const [],
);

final roof = MaterialSpec(
  id: 'roof',
  name: 'Roofing Sheets',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/roof.png',
  blurb: 'Ribbed or corrugated sheets for a roof',
  numbers: const [
    NumberField(id: 'length', label: 'Roof length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Roof width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per sheet',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Roof type',
      options: [
        ChoiceOption('ribbed', 'Ribbed'),
        ChoiceOption('corrugated', 'Corrugated'),
      ],
    ),
    const ChoiceField(
      id: 'sheetWidth',
      label: 'Sheet width',
      options: [
        ChoiceOption('0.8', '0.8 m', 0.8),
        ChoiceOption('0.9', '0.9 m', 0.9),
        ChoiceOption('1.0', '1.0 m', 1.0),
        ChoiceOption('1.2', '1.2 m', 1.2),
      ],
    ),
    const ChoiceField(
      id: 'sheetLength',
      label: 'Sheet length',
      options: [
        ChoiceOption('5', '1.524 m (5 ft)', 1.524),
        ChoiceOption('6', '1.829 m (6 ft)', 1.829),
        ChoiceOption('7', '2.134 m (7 ft)', 2.134),
        ChoiceOption('8', '2.438 m (8 ft)', 2.438),
        ChoiceOption('9', '2.743 m (9 ft)', 2.743),
        ChoiceOption('10', '3.048 m (10 ft)', 3.048),
        ChoiceOption('12', '3.658 m (12 ft)', 3.658),
      ],
    ),
    ChoiceField(
      id: 'sideLap',
      label: 'Side lap',
      helper: 'How many corrugations neighbouring sheets overlap',
      options: const [
        ChoiceOption('1.5', '1.5 corrugations', 1.5),
        ChoiceOption('2.5', '2.5 corrugations', 2.5),
      ],
      visibleWhen: (selected) => selected['type'] == 'corrugated',
    ),
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final type = input.choice('type');
    final width = input.choice('sheetWidth').value;
    final length = input.choice('sheetLength').value;
    final corrugated = type.id == 'corrugated';
    final coveredWidth = corrugated
        ? width - input.choice('sideLap').value * corrugationPitch
        : width;
    final sheetArea = coveredWidth * length;
    final sheets = ceilCount(area / sheetArea);
    return CalcResult(
      label:
          'Roof sheet, ${type.label.toLowerCase()} '
          '${formatNumber(width)} × ${formatNumber(length)} m',
      area: area,
      quantity: sheets.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      details: [
        if (corrugated)
          ResultDetail(
            'Covered width after side lap',
            '${formatNumber(coveredWidth)} m',
          ),
        ResultDetail('Area per sheet', formatArea(sheetArea)),
      ],
    );
  },
  definitions: materialDefinitions['roof']!,
  solution: materialSolutions['roof']!,
  references: materialReferences['roof'] ?? const [],
);

final carpet = MaterialSpec(
  id: 'carpet',
  name: 'Carpet',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/carpet.png',
  blurb: 'Carpets or rugs to cover a room',
  numbers: const [
    NumberField(id: 'length', label: 'Room length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Room width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per piece',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'size',
      label: 'Carpet size',
      options: [
        ChoiceOption('160x230', '1.6 × 2.3 m', 1.6 * 2.3),
        ChoiceOption('133x190', '1.33 × 1.9 m', 1.33 * 1.9),
      ],
    ),
    contingencyField,
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final size = input.choice('size');
    final contingency = input.choice('contingency').value;
    final count = countByArea(area, size.value, contingency);
    return CalcResult(
      label: 'Carpet ${size.label}',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      details: areaDetails(
        area: area,
        unitArea: size.value,
        count: count,
        contingency: contingency,
        unit: QuantityUnit.pieces,
        unitAreaLabel: 'Area per carpet',
      ),
    );
  },
  definitions: materialDefinitions['carpet']!,
  solution: materialSolutions['carpet']!,
  references: materialReferences['carpet'] ?? const [],
);

final wallpaper = MaterialSpec(
  id: 'wallpaper',
  name: 'Wallpaper',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/wallpaper.png',
  blurb: 'Rolls to cover a wall',
  numbers: const [
    NumberField(id: 'width', label: 'Wall width', unit: 'm', max: 10000),
    NumberField(id: 'height', label: 'Wall height', unit: 'm', max: 100),
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
      label: 'Roll coverage',
      options: [
        ChoiceOption('4x8', '1.22 × 2.44 m (4 × 8 ft)', 1.2192 * 2.4384),
        ChoiceOption('4x10', '1.22 × 3.05 m (4 × 10 ft)', 1.2192 * 3.048),
      ],
    ),
    contingencyField,
  ],
  compute: (input) {
    final area = input['width'] * input['height'];
    final size = input.choice('size');
    final contingency = input.choice('contingency').value;
    final count = countByArea(area, size.value, contingency);
    return CalcResult(
      label: 'Wallpaper ${size.label}',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.rolls,
      unitPrice: input['price'],
      details: areaDetails(
        area: area,
        unitArea: size.value,
        count: count,
        contingency: contingency,
        unit: QuantityUnit.rolls,
        unitAreaLabel: 'Area per roll',
      ),
    );
  },
  definitions: materialDefinitions['wallpaper']!,
  solution: materialSolutions['wallpaper']!,
  references: materialReferences['wallpaper'] ?? const [],
);
