import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'material_spec.dart';

/// Door sets by option id: size, price list entry, and the hinges and
/// lockset each door takes. PVC door sets come with their hinges.
const doorTypes = {
  'interior': (
    label: 'Interior flush',
    size: '0.80 × 2.10 m',
    key: 'door_set',
    hinges: 3,
    hinge: 'hinge',
    lockset: 'lockset',
  ),
  'main': (
    label: 'Main entrance panel',
    size: '0.90 × 2.10 m',
    key: 'door_main',
    hinges: 4,
    hinge: 'hinge_heavy',
    lockset: 'lockset_entrance',
  ),
  'pvc': (
    label: 'Bathroom PVC',
    size: '0.70 × 2.10 m',
    key: 'door_pvc',
    hinges: 0,
    hinge: 'hinge',
    lockset: 'lockset',
  ),
};

final doors = MaterialSpec(
  id: 'doors',
  name: 'Doors',
  category: MaterialCategory.architectural,
  icon: Icons.door_front_door_outlined,
  blurb: 'Door sets with jambs, hinges and locksets',
  keywords: const [
    'pinto',
    'pintuan',
    'door',
    'flush door',
    'panel door',
    'PVC door',
    'hinge',
    'bisagra',
    'lockset',
    'doorknob',
    'seradura',
  ],
  priceRef: (s) {
    final type = doorTypes[s['type']];
    return type == null ? null : PriceRef(type.key);
  },
  numbers: [quantityField('Number of doors'), priceField('Price per door set')],
  choices: [
    ChoiceField(
      id: 'type',
      label: 'Door',
      initial: 'interior',
      helper: 'Each set is the door leaf with its jamb',
      options: [
        for (final MapEntry(:key, :value) in doorTypes.entries)
          ChoiceOption(key, '${value.label}, ${value.size}'),
      ],
    ),
  ],
  compute: (input) {
    final count = input['quantity'];
    final type = doorTypes[input.choice('type').id]!;
    return CalcResult(
      label: 'Door, ${type.label.toLowerCase()} ${type.size}',
      quantity: count,
      unit: QuantityUnit.sets,
      unitPrice: input['price'],
      itemKey: type.key,
      details: [
        ResultDetail('Door size', type.size),
        ResultDetail(
          'Hinges per door',
          type.hinges == 0 ? 'Come with the set' : '${type.hinges}',
        ),
        const ResultDetail('Locksets per door', '1'),
      ],
      companions: [
        if (type.hinges > 0) buy(type.hinge, count * type.hinges),
        buy(type.lockset, count),
      ],
      note: type.hinges == 0
          ? 'PVC door sets come with their hinges.'
          : 'Door sets include the jamb; paint or varnish is not included.',
    );
  },
  definitions: const [
    InfoSection(
      'Door set',
      'The door leaf with its jamb (the frame fixed in the wall opening), '
          'priced as one set.',
    ),
    InfoSection(
      'Door types',
      'Interior and bedroom doors are usually flush doors 0.80 × 2.10 m, '
          'hollow-core plywood on a wood frame. Main entrance doors are '
          'solid panel doors 0.90 × 2.10 m. Bathroom doors are often PVC, '
          '0.70 × 2.10 m.',
    ),
    InfoSection(
      'Hinges',
      'Three 3½" butt hinges hang an interior door. A heavy main door takes '
          'four 4" hinges. PVC door sets come with their hinges.',
    ),
    InfoSection(
      'Lockset',
      'The knob or lever with its latch and lock. Use a privacy lockset for '
          'bedrooms and bathrooms and a keyed entrance lockset for the main '
          'door.',
    ),
  ],
  solution: const [
    InfoSection(
      'Door sets',
      'One set for each door.',
      formula: 'sets = number of doors',
    ),
    InfoSection(
      'Hinges and locksets',
      'Three hinges per interior door, four per main door and none for PVC '
          'sets; one lockset per door.',
      formula:
          'hinges = doors × 3 (main door 4, PVC 0)\n'
          'locksets = doors × 1',
    ),
    InfoSection(
      'Cost',
      'Multiply the doors by the price per set. Hinges and locksets are '
          'priced from your price list and added to the total.',
      formula: 'cost = doors × price per set + hinges + locksets',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/',
    'https://www.officialgazette.gov.ph/1983/02/25/batas-pambansa-blg-344/',
  ],
);

/// Square feet in a square metre.
const squareFeetPerSquareMetre = 10.764;

/// Silicone sealant: one 300 ml tube seals about 7 m of joint.
const sealantPerTube = 7.0;

final windows = MaterialSpec(
  id: 'windows',
  name: 'Windows',
  category: MaterialCategory.architectural,
  icon: Icons.window_outlined,
  blurb: 'Aluminium windows by the square metre, with sealant',
  keywords: const [
    'bintana',
    'window',
    'aluminum window',
    'sliding window',
    'salamin',
    'glass',
    'jalousie',
    'awning',
  ],
  priceRef: (_) => const PriceRef('window_m2'),
  numbers: [
    const NumberField(
      id: 'width',
      label: 'Window width',
      unit: 'm',
      hint: 'Of the opening, e.g. 1.20',
      max: 100,
    ),
    const NumberField(
      id: 'height',
      label: 'Window height',
      unit: 'm',
      hint: 'Of the opening, e.g. 1.20',
      max: 100,
    ),
    quantityField('Number of windows'),
    priceField('Price per m²'),
  ],
  choices: [
    descriptor('type', 'Window type', const [
      ('sliding', 'Aluminium sliding'),
      ('awning', 'Awning or casement'),
      ('fixed', 'Fixed glass'),
    ]),
  ],
  compute: (input) {
    final width = input['width'];
    final height = input['height'];
    final count = input['quantity'];
    final each = width * height;
    final area = roundUp(each * count);
    final perimeter = 2 * (width + height) * count;
    return CalcResult(
      label: describe(
        'Window ${formatNumber(width)} × ${formatNumber(height)} '
        'm',
        [input.choices['type']],
      ),
      area: area,
      quantity: area,
      unit: QuantityUnit.squareMetres,
      unitPrice: input['price'],
      itemKey: 'window_m2',
      details: [
        ResultDetail(
          'Each window',
          '${formatNumber(width)} × ${formatNumber(height)} m = '
              '${formatArea(roundUp(each))}',
        ),
        if (count != 1) ResultDetail('Windows', '× ${formatNumber(count)}'),
        ResultDetail('Window area', formatArea(area)),
        ResultDetail(
          'In square feet',
          '${formatNumber(area * squareFeetPerSquareMetre)} ft²',
        ),
      ],
      companions: [buy('sealant', perimeter * 2 / sealantPerTube)],
      note:
          'Fabricators often quote per square foot. Multiply a price per '
          'ft² by 10.764 for the price per m².',
    );
  },
  definitions: const [
    InfoSection(
      'Window types',
      'Aluminium sliding windows are the most common. Awning and casement '
          'windows swing out, and small awning windows suit bathrooms. Fixed '
          'glass does not open.',
    ),
    InfoSection(
      'Width and height',
      'The size of the wall opening. Common sizes are 1.20 × 1.20, '
          '1.00 × 1.20 and 1.50 × 1.20 m, and 0.60 × 0.60 m for bathrooms.',
    ),
    InfoSection(
      'Price per m²',
      'Aluminium and glass fabricators quote per square foot, supplied and '
          'installed, by frame series and glass thickness. One square metre '
          'is 10.764 ft².',
    ),
    InfoSection(
      'Sealant',
      'Silicone sealant closes the joint between the frame and the wall on '
          'both sides. A 300 ml tube seals about 7 m.',
    ),
    InfoSection(
      'Window openings',
      'The National Building Code asks for window openings of at least 10% '
          'of the floor area in rooms without air conditioning.',
    ),
  ],
  solution: const [
    InfoSection(
      'Window area',
      'Width times height of each window, times the number of windows.',
      formula: 'area = width × height × windows',
    ),
    InfoSection(
      'Sealant',
      'The frame perimeter is sealed inside and out.',
      formula: 'tubes = round up(2 × (width + height) × windows × 2 ÷ 7)',
    ),
    InfoSection(
      'Cost',
      'Multiply the area by the price per m². Sealant is priced from your '
          'price list and added to the total.',
      formula:
          'cost = area × price per m² + sealant\n'
          'price per m² = price per ft² × 10.764',
    ),
  ],
  references: const [
    'https://www.officialgazette.gov.ph/1977/02/19/presidential-decree-no-1096/',
    'https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/',
  ],
);
