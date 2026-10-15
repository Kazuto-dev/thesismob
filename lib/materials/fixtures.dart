import '../core/format.dart';
import 'calc_helpers.dart';
import 'material_spec.dart';

/// Share of a bulb's light that reaches the room's work surface after
/// fixture, wall and dust losses (utilisation × maintenance factor).
const lightLossFactor = 0.5;

/// Wire is sold in boxes of 150 m.
const wireBoxLength = 150.0;

/// Extra wire for bends, drops and slack at every box.
const wireAllowance = 0.10;

/// Extra pipe for fittings, offsets and cuts.
const pipeAllowance = 0.10;

/// Under the Philippine Electrical Code no point along a wall may be more
/// than 1.8 m from an outlet, so one outlet serves 3.6 m of wall.
const outletSpacing = 3.6;

/// Choice between sizing from the room and entering a count directly.
ChoiceField _countBy(String items) => ChoiceField(
  id: 'mode',
  label: 'Count by',
  initial: 'room',
  leading: true,
  options: [
    const ChoiceOption('room', 'Room size'),
    ChoiceOption('count', 'Number of $items'),
  ],
);

bool _byRoom(Map<String, String> s) => s['mode'] != 'count';
bool _byCount(Map<String, String> s) => s['mode'] == 'count';

MaterialSpec _fixture({
  required String id,
  required String name,
  required String summaryName,
  required MaterialCategory category,
  required String blurb,
  required String quantityLabel,
  String? quantityHint,
  List<ChoiceField> choices = const [],
  List<(String, int)> companions = const [],
  String? note,
  required List<InfoSection> definitions,
  List<String> references = const [],
  List<String> keywords = const [],
}) => MaterialSpec(
  id: id,
  name: name,
  category: category,
  image: 'assets/images/materials/$id.png',
  blurb: blurb,
  keywords: keywords,
  numbers: [
    quantityField(quantityLabel, hint: quantityHint),
    priceField('Price per piece'),
  ],
  choices: choices,
  compute: perPiece(
    summaryName,
    descriptors: [for (final c in choices) c.id],
    companions: companions,
    note: note,
  ),
  definitions: definitions,
  solution: [
    InfoSection(
      'Cost',
      'Multiply the number of '
          '${quantityLabel.replaceFirst('Number of ', '')} by the price per '
          'piece. The type you choose describes the item in your summary and '
          'does not change the cost.',
      formula: 'cost = quantity × price per piece',
    ),
    if (companions.isNotEmpty)
      InfoSection(
        'Also needed',
        'Each piece usually needs the items listed under "Also needed". '
            'Their quantities are a planning guide and are not priced.',
      ),
  ],
  references: references,
);

const _ledBulbs = [
  ChoiceOption('5', '5 W, 480 lm', 480),
  ChoiceOption('7', '7 W, 650 lm', 650),
  ChoiceOption('9', '9 W, 880 lm', 880),
  ChoiceOption('12', '12 W, 1,200 lm', 1200),
  ChoiceOption('15', '15 W, 1,500 lm', 1500),
  ChoiceOption('18', '18 W, 1,800 lm', 1800),
];

final bulb = MaterialSpec(
  id: 'bulb',
  name: 'Light Bulb',
  category: MaterialCategory.electrical,
  image: 'assets/images/materials/bulb.png',
  blurb: 'LED bulbs for a room, by the light it needs',
  keywords: const ['bombilya', 'ilaw', 'light', 'LED', 'lamp', 'lighting'],
  numbers: [
    NumberField(
      id: 'length',
      label: 'Room length',
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'width',
      label: 'Room width',
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'quantity',
      label: 'Number of bulbs',
      unit: 'pcs',
      integer: true,
      max: 100000,
      visibleWhen: _byCount,
    ),
    priceField('Price per bulb'),
  ],
  choices: [
    _countBy('bulbs'),
    ChoiceField(
      id: 'room',
      label: 'Room',
      initial: 'living',
      helper: 'Sets how bright the room should be',
      options: const [
        ChoiceOption('bedroom', 'Bedroom, 100 lx', 100),
        ChoiceOption('living', 'Living room, 150 lx', 150),
        ChoiceOption('bath', 'Bathroom, 200 lx', 200),
        ChoiceOption('kitchen', 'Kitchen, 300 lx', 300),
        ChoiceOption('study', 'Study or office, 500 lx', 500),
      ],
      visibleWhen: _byRoom,
    ),
    const ChoiceField(
      id: 'watts',
      label: 'LED bulb',
      initial: '9',
      helper: 'E27 base. Lumens (lm) are printed on the box',
      options: _ledBulbs,
    ),
  ],
  compute: (input) {
    final bulbChoice = input.choice('watts');
    final label = 'LED bulb ${bulbChoice.label.split(',').first}';
    if (input.chose('mode', 'count')) {
      final quantity = input['quantity'];
      return CalcResult(
        label: label,
        quantity: quantity,
        unit: QuantityUnit.bulbs,
        unitPrice: input['price'],
        companions: [
          ResultDetail('Lamp holders, E27', formatCount(quantity, 'pc', 'pcs')),
        ],
      );
    }
    final area = input['length'] * input['width'];
    final lux = input.choice('room').value;
    final lumens = bulbChoice.value;
    final needed = lux * area;
    final bulbs = ceilCount(needed / (lumens * lightLossFactor));
    return CalcResult(
      label: label,
      area: area,
      quantity: bulbs.toDouble(),
      unit: QuantityUnit.bulbs,
      unitPrice: input['price'],
      details: [
        ResultDetail('Room area', formatArea(area)),
        ResultDetail(
          'Light needed (${formatNumber(lux)} lx × area)',
          '${formatNumber(needed.roundToDouble())} lm',
        ),
        ResultDetail(
          'Useful light per bulb (50%)',
          '${formatNumber(lumens * lightLossFactor)} lm',
        ),
        ResultDetail(
          'Bulbs',
          formatQuantity(bulbs.toDouble(), QuantityUnit.bulbs),
        ),
      ],
      companions: [
        ResultDetail('Lamp holders, E27', formatCount(bulbs, 'pc', 'pcs')),
        ResultDetail('Ceiling junction boxes', formatCount(bulbs, 'pc', 'pcs')),
      ],
      note: 'Spread the bulbs evenly over the ceiling.',
    );
  },
  definitions: const [
    InfoSection(
      'Lux (lx)',
      'How much light falls on a surface. Bedrooms need about 100 lx, living '
          'rooms 150, bathrooms 200, kitchens 300 and desks 500.',
    ),
    InfoSection(
      'Lumens (lm)',
      'How much light a bulb gives, printed on its box. LED bulbs give about '
          '100 lm per watt: a 9 W bulb gives about 880 lm.',
    ),
    InfoSection(
      'Light loss',
      'Shades, walls and dust absorb part of the light, so only about half '
          'of a bulb\'s lumens reach the floor and tables.',
    ),
    InfoSection(
      'E27',
      'The standard screw base for household bulbs in the Philippines.',
    ),
  ],
  solution: const [
    InfoSection(
      'Light needed',
      'Multiply the brightness the room needs by its area.',
      formula: 'lumens needed = lux × length × width',
    ),
    InfoSection(
      'Bulbs',
      'Divide by the useful light of one bulb, half its rated lumens, and '
          'round up.',
      formula: 'bulbs = round up(lumens needed ÷ (bulb lumens × 0.5))',
    ),
    InfoSection(
      'Cost',
      'Multiply the bulbs by the price per bulb.',
      formula: 'cost = bulbs × price per bulb',
    ),
  ],
  references: const [
    'https://www.engineeringtoolbox.com/light-level-rooms-d_708.html',
    'https://www.lrc.rpi.edu/programs/solidstate/assist/pdf/led-lighting-apps-guide-2002.pdf',
  ],
);

final lightSwitch = _fixture(
  id: 'switch',
  name: 'Switch',
  summaryName: 'Switch',
  category: MaterialCategory.electrical,
  blurb: 'Wall switches, with boxes and plates',
  keywords: const ['suwits', 'light switch', 'wide series'],
  quantityLabel: 'Number of switches',
  quantityHint: 'One per room entrance; a stair needs a pair of 3-way',
  choices: [
    descriptor('type', 'Switch type', [
      ('1gang', '1 gang'),
      ('2gang', '2 gang'),
      ('3gang', '3 gang'),
      ('3way', '3-way'),
    ]),
  ],
  companions: const [('Utility boxes, 2" × 4"', 1), ('Switch plates', 1)],
  definitions: const [
    InfoSection(
      'Gang',
      'How many switches share one plate: a 2-gang switch controls two '
          'lights from one box.',
    ),
    InfoSection(
      '3-way switch',
      'Used in pairs to control one light from two places, such as the top '
          'and bottom of a stair or both ends of a hall.',
    ),
    InfoSection(
      'Where switches go',
      'Every room, bathroom, hallway and stair needs at least one '
          'wall-switched light. Stairs with six or more steps need a switch '
          'at each floor.',
    ),
  ],
  references: const [
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
  ],
);

final junctionBox = _fixture(
  id: 'junction_box',
  name: 'Junction Box',
  summaryName: 'Junction box',
  category: MaterialCategory.electrical,
  blurb: 'Octagonal boxes for ceiling lights and splices',
  keywords: const ['octagonal box', 'junction', '4x4', 'ceiling box'],
  quantityLabel: 'Number of boxes',
  quantityHint: 'One per ceiling light, plus one at each splice',
  choices: [
    descriptor('type', 'Box type', [
      ('octagonal', 'Octagonal 4" × 4"'),
      ('square', 'Square 4" × 4"'),
    ]),
  ],
  definitions: const [
    InfoSection(
      'Junction box',
      'A 4" × 4" box, usually octagonal, that holds wire splices and '
          'carries a ceiling light. Square 4" × 4" boxes serve as pull boxes '
          'on long conduit runs.',
    ),
    InfoSection(
      'How many',
      'Every light outlet and every place where wires are joined needs a '
          'box, so that no splice is left outside an enclosure.',
    ),
  ],
);

final outlet = MaterialSpec(
  id: 'outlet',
  name: 'Outlet',
  category: MaterialCategory.electrical,
  image: 'assets/images/materials/outlet.png',
  blurb: 'Convenience outlets for a room, spaced by the code',
  keywords: const ['saksakan', 'socket', 'convenience outlet', 'plug'],
  numbers: [
    NumberField(
      id: 'length',
      label: 'Room length',
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'width',
      label: 'Room width',
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'doors',
      label: 'Doorway widths',
      unit: 'm',
      hint: 'Optional. Total width of doors, about 0.9 m each',
      optional: true,
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'quantity',
      label: 'Number of outlets',
      unit: 'pcs',
      integer: true,
      max: 100000,
      visibleWhen: _byCount,
    ),
    priceField('Price per outlet'),
  ],
  choices: [
    _countBy('outlets'),
    descriptor('type', 'Outlet type', [
      ('1', '1 gang'),
      ('2', '2 gang'),
      ('3', '3 gang'),
    ]),
  ],
  compute: (input) {
    final label = describe('Outlet', [input.choices['type']]);
    if (input.chose('mode', 'count')) {
      final quantity = input['quantity'];
      return CalcResult(
        label: label,
        quantity: quantity,
        unit: QuantityUnit.pieces,
        unitPrice: input['price'],
        companions: [
          ResultDetail(
            'Utility boxes, 2" × 4"',
            formatCount(quantity, 'pc', 'pcs'),
          ),
        ],
      );
    }
    final perimeter = 2 * (input['length'] + input['width']);
    final doors = input.optional('doors');
    final wall = perimeter - doors;
    if (wall <= 0) {
      throw ArgumentError('Doorways must be shorter than the walls');
    }
    final outlets = ceilCount(wall / outletSpacing);
    return CalcResult(
      label: label,
      quantity: outlets.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      details: [
        ResultDetail('Wall around the room', formatLength(roundUp(perimeter))),
        if (doors > 0) ResultDetail('Less doorways', '−${formatLength(doors)}'),
        ResultDetail('One outlet per 3.6 m', formatCount(outlets, 'outlet')),
      ],
      companions: [
        ResultDetail(
          'Utility boxes, 2" × 4"',
          formatCount(outlets, 'pc', 'pcs'),
        ),
        const ResultDetail('Wire for outlets', '3.5 mm²'),
      ],
      note: 'Kitchen counters need one outlet per 1.2 m of counter.',
    );
  },
  definitions: const [
    InfoSection(
      'Convenience outlet',
      'A wall socket for plugging in appliances. A duplex outlet has two '
          'sockets on one plate.',
    ),
    InfoSection(
      'Spacing rule',
      'The Philippine Electrical Code requires that no point along a wall '
          'is more than 1.8 m from an outlet, so outlets go at most 3.6 m '
          'apart. Doorways break the wall and are left out.',
    ),
    InfoSection(
      'Kitchens and bathrooms',
      'Kitchen counters need an outlet every 1.2 m; bathrooms need one '
          'within 0.9 m of each basin.',
    ),
  ],
  solution: const [
    InfoSection(
      'Wall length',
      'Go around the room and subtract the doorways.',
      formula: 'wall = 2 × (length + width) − doorways',
    ),
    InfoSection(
      'Outlets',
      'One outlet for every 3.6 m of wall, rounded up.',
      formula: 'outlets = round up(wall ÷ 3.6)',
    ),
    InfoSection(
      'Cost',
      'Multiply the outlets by the price per outlet.',
      formula: 'cost = outlets × price per outlet',
    ),
  ],
  references: const [
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
  ],
);

final wires = MaterialSpec(
  id: 'wires',
  name: 'Electrical Wire',
  category: MaterialCategory.electrical,
  image: 'assets/images/materials/wires.png',
  blurb: 'THHN building wire by circuit, in 150 m boxes',
  keywords: const ['kawad', 'kable', 'THHN', 'cable', 'wiring'],
  numbers: [
    const NumberField(
      id: 'run',
      label: 'Circuit length',
      unit: 'm',
      hint: 'Along the conduit from the panel, with drops to each box',
      max: 100000,
    ),
    priceField(
      'Price per box',
      id: 'boxPrice',
      visibleWhen: (s) => s['buy'] != 'metre',
    ),
    priceField('Price per metre', visibleWhen: (s) => s['buy'] == 'metre'),
  ],
  choices: [
    const ChoiceField(
      id: 'size',
      label: 'Wire size',
      initial: '3.5',
      helper: '2.0 mm² for lights, 3.5 mm² for outlets, 5.5 mm² for aircon',
      options: [
        ChoiceOption('2.0', '2.0 mm²'),
        ChoiceOption('3.5', '3.5 mm²'),
        ChoiceOption('5.5', '5.5 mm²'),
        ChoiceOption('8.0', '8.0 mm²'),
      ],
    ),
    const ChoiceField(
      id: 'conductors',
      label: 'Wires in the circuit',
      initial: '3',
      helper: 'Line and neutral, plus a ground wire for outlets and aircon',
      options: [
        ChoiceOption('2', '2 wires', 2),
        ChoiceOption('3', '3 with ground', 3),
      ],
    ),
    const ChoiceField(
      id: 'buy',
      label: 'Buy',
      initial: 'box',
      options: [
        ChoiceOption('box', 'By the box (150 m)'),
        ChoiceOption('metre', 'By the metre'),
      ],
    ),
  ],
  compute: (input) {
    final run = input['run'];
    final conductors = input.choice('conductors').value;
    final metres = run * conductors * (1 + wireAllowance);
    final label = 'THHN wire ${input.choice('size').label}';
    final details = [
      ResultDetail('Circuit length', formatLength(run)),
      ResultDetail('Wires', '× ${formatNumber(conductors)}'),
      ResultDetail(
        'With 10% for bends and slack',
        formatLength(roundUp(metres, 1)),
      ),
    ];
    final conduit = ResultDetail(
      'PVC conduit ½", 3 m',
      formatCount(ceilCount(run * 1.1 / 3), 'length'),
    );
    if (input.chose('buy', 'metre')) {
      final bought = ceilCount(metres).toDouble();
      return CalcResult(
        label: label,
        quantity: bought,
        unit: QuantityUnit.metres,
        unitPrice: input['price'],
        details: details,
        companions: [conduit],
      );
    }
    final boxes = ceilCount(metres / wireBoxLength);
    return CalcResult(
      label: label,
      quantity: boxes.toDouble(),
      unit: QuantityUnit.boxes,
      unitPrice: input['boxPrice'],
      details: [
        ...details,
        ResultDetail('Boxes of 150 m', formatCount(boxes, 'box', 'boxes')),
      ],
      companions: [conduit],
    );
  },
  definitions: const [
    InfoSection(
      'THHN wire',
      'Stranded copper building wire with heat-resistant insulation, used '
          'inside conduit. Sold in boxes of 150 m, or cut by the metre.',
    ),
    InfoSection(
      'Wire size',
      '2.0 mm² (#14) for lighting circuits, 3.5 mm² (#12) for outlets, '
          '5.5 mm² (#10) for air conditioners, 8.0 mm² and up for feeders.',
    ),
    InfoSection(
      'Wires in the circuit',
      'Every circuit needs a line and a neutral wire. Outlet and aircon '
          'circuits add a green ground wire.',
    ),
    InfoSection(
      'Circuit length',
      'Measure along the conduit path from the panel board to the last box, '
          'including drops down the wall to switches and outlets.',
    ),
  ],
  solution: const [
    InfoSection(
      'Wire needed',
      'Each wire runs the full circuit length. Add 10% for bends and for the '
          'slack left at every box.',
      formula: 'metres = circuit length × wires × 1.10',
    ),
    InfoSection(
      'Boxes',
      'Divide by 150 m per box and round up.',
      formula: 'boxes = round up(metres ÷ 150)',
    ),
    InfoSection(
      'Conduit',
      'PVC conduit comes in 3 m lengths; 10% extra covers fittings and cuts.',
      formula: 'lengths = round up(circuit length × 1.1 ÷ 3)',
    ),
    InfoSection(
      'Cost',
      'Boxes × price per box, or metres × price per metre.',
      formula: 'cost = quantity × price',
    ),
  ],
  references: const [
    'https://phelpsdodge.com.ph/frequently-asked-questions/',
    'http://electricaldesign1.blogspot.com/2010/02/cost-estimation.html',
  ],
);

final utilityBox = _fixture(
  id: 'utility_box',
  name: 'Utility Box',
  summaryName: 'Utility box',
  category: MaterialCategory.electrical,
  blurb: '2" × 4" boxes for switches and outlets',
  keywords: const ['2x4 box', 'switch box', 'outlet box'],
  quantityLabel: 'Number of boxes',
  quantityHint: 'One per switch and outlet location',
  choices: [
    descriptor('type', 'Mounting', [
      ('flush', 'Flush'),
      ('surface', 'Surface'),
    ]),
  ],
  definitions: const [
    InfoSection(
      'Utility box',
      'A 2" × 4" box set in the wall that holds a switch or an outlet. Up to '
          'three wide-series devices fit one box.',
    ),
    InfoSection(
      'Flush or surface',
      'Flush boxes are buried in the wall before plastering; surface boxes '
          'mount on a finished wall.',
    ),
  ],
);

final pvc = MaterialSpec(
  id: 'pvc',
  name: 'PVC Pipe',
  category: MaterialCategory.plumbing,
  image: 'assets/images/materials/pvc.png',
  blurb: 'Pipes for a run, in 3 m lengths',
  keywords: const ['tubo', 'pipe', 'tubig', 'drainage', 'neltex', 'moldex'],
  numbers: const [
    NumberField(
      id: 'run',
      label: 'Total pipe run',
      unit: 'm',
      hint: 'Add up every straight length of pipe',
      max: 100000,
    ),
    NumberField(
      id: 'price',
      label: 'Price per pipe',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'diameter',
      label: 'Diameter',
      initial: '1/2',
      helper: '½" to 1" for water supply, 2" to 4" for drainage',
      options: [
        ChoiceOption('1/2', '½" (20 mm)'),
        ChoiceOption('3/4', '¾" (25 mm)'),
        ChoiceOption('1', '1" (32 mm)'),
        ChoiceOption('2', '2" (57 mm)'),
        ChoiceOption('3', '3" (82 mm)'),
        ChoiceOption('4', '4" (107 mm)'),
      ],
    ),
    ChoiceField(
      id: 'length',
      label: 'Pipe length',
      initial: '3',
      options: [ChoiceOption('3', '3 m', 3), ChoiceOption('4', '4 m (PPR)', 4)],
    ),
  ],
  compute: (input) {
    final run = input['run'];
    final length = input.choice('length').value;
    final needed = run * (1 + pipeAllowance);
    final pipes = ceilCount(needed / length);
    return CalcResult(
      label: 'PVC pipe ${input.choice('diameter').label}',
      quantity: pipes.toDouble(),
      unit: QuantityUnit.pipes,
      unitPrice: input['price'],
      details: [
        ResultDetail('Pipe run', formatLength(run)),
        ResultDetail(
          'With 10% for fittings and cuts',
          formatLength(roundUp(needed, 1)),
        ),
        ResultDetail(
          'Pipes of ${formatLength(length)}',
          formatQuantity(pipes.toDouble(), QuantityUnit.pipes),
        ),
      ],
      note: 'Elbows, tees and couplings are counted separately.',
    );
  },
  definitions: const [
    InfoSection(
      'PVC pipe',
      'Rigid plastic pipe. Blue pressure pipe carries water; orange or grey '
          'sanitary pipe carries waste water. Standard lengths are 3 m; PPR '
          'hot-water pipe comes in 4 m.',
    ),
    InfoSection(
      'Diameter',
      'Water lines use ½" (20 mm) to fixtures and ¾" to 1" for mains. '
          'Drains use 2" for sinks and showers, 3" to 4" for toilets and '
          'the main sewer line.',
    ),
    InfoSection(
      'Pipe run',
      'The total length of straight pipe on your plan, in metres.',
    ),
  ],
  solution: const [
    InfoSection(
      'Pipe needed',
      'Add 10% to the run for offsets, fittings and cutting.',
      formula: 'pipe = run × 1.10',
    ),
    InfoSection(
      'Pipes',
      'Divide by the pipe length and round up.',
      formula: 'pipes = round up(pipe ÷ pipe length)',
    ),
    InfoSection(
      'Cost',
      'Multiply the pipes by the price per pipe.',
      formula: 'cost = pipes × price per pipe',
    ),
  ],
  references: const [
    'https://www.neltex.com/products.do?item_id=51663',
    'https://mpi.moldex.com.ph/mb-pipes-and-fittings',
  ],
);

final sink = _fixture(
  id: 'sink',
  name: 'Sink',
  summaryName: 'Sink',
  category: MaterialCategory.plumbing,
  blurb: 'Kitchen and bathroom sinks, with fittings',
  keywords: const ['lababo', 'lavatory', 'basin', 'hugasan'],
  quantityLabel: 'Number of sinks',
  choices: [
    descriptor('type', 'Sink type', [
      ('wall', 'Wall-hung'),
      ('pedestal', 'Pedestal'),
      ('vessel', 'Vessel'),
      ('drop_in', 'Drop-in'),
      ('undermount', 'Undermount'),
    ]),
  ],
  companions: const [
    ('Faucets', 1),
    ('Angle valves', 1),
    ('Flexible hoses', 1),
    ('P-traps', 1),
  ],
  note: 'Lavatory sets often include these; check before buying.',
  definitions: const [
    InfoSection(
      'Sink types',
      'Wall-hung and pedestal basins stand alone; vessel sinks sit on a '
          'counter; drop-in and undermount sinks are set into it.',
    ),
    InfoSection(
      'Angle valve and hose',
      'The angle valve shuts off water at the wall; a flexible hose links it '
          'to the faucet.',
    ),
    InfoSection(
      'P-trap',
      'The U-bend under the sink. It holds water to keep sewer gas out: '
          '1¼" for lavatories, 1½" for kitchen sinks.',
    ),
  ],
);

final toilet = _fixture(
  id: 'toilet',
  name: 'Toilet',
  summaryName: 'Toilet',
  category: MaterialCategory.plumbing,
  blurb: 'Water closets, with valves and seals',
  keywords: const ['inidoro', 'kubeta', 'water closet', 'WC', 'CR'],
  quantityLabel: 'Number of toilets',
  choices: [
    descriptor('type', 'Toilet type', [
      ('two_piece', 'Two-piece'),
      ('one_piece', 'One-piece'),
      ('squat', 'Squat'),
    ]),
  ],
  companions: const [
    ('Angle valves', 1),
    ('Flexible hoses', 1),
    ('Wax rings', 1),
    ('Closet bolt sets', 1),
  ],
  definitions: const [
    InfoSection(
      'Toilet types',
      'Two-piece toilets have a separate tank; one-piece toilets are a '
          'single casting that is easier to clean.',
    ),
    InfoSection(
      'Wax ring and closet bolts',
      'The wax ring seals the toilet to the 3" floor drain; closet bolts '
          'hold it down.',
    ),
  ],
);

final faucet = _fixture(
  id: 'faucet',
  name: 'Faucet',
  summaryName: 'Faucet',
  category: MaterialCategory.plumbing,
  blurb: 'Faucets by handle and spout type',
  keywords: const ['gripo', 'tap', 'bibb'],
  quantityLabel: 'Number of faucets',
  choices: [
    descriptor('type', 'Faucet type', [
      ('single', 'Single-handle'),
      ('double', 'Double-handle'),
      ('gooseneck', 'Gooseneck'),
      ('pull_out', 'Pull-out'),
      ('hose_bibb', 'Hose bibb'),
    ]),
  ],
  companions: const [('Teflon tape', 1)],
  definitions: const [
    InfoSection(
      'Faucet types',
      'Single-handle faucets mix hot and cold with one lever. Gooseneck and '
          'pull-out spouts suit kitchen sinks; a hose bibb is an outdoor tap.',
    ),
    InfoSection(
      'Teflon tape',
      'Thread-seal tape wrapped on threaded joints so they do not leak.',
    ),
  ],
);

final shower = _fixture(
  id: 'shower',
  name: 'Shower',
  summaryName: 'Shower',
  category: MaterialCategory.plumbing,
  blurb: 'Shower sets, with valve and floor drain',
  keywords: const ['dutsa', 'shower head', 'bathroom'],
  quantityLabel: 'Number of showers',
  choices: [
    descriptor('type', 'Shower type', [
      ('exposed', 'Exposed'),
      ('concealed', 'Concealed'),
      ('mixer', 'Mixer'),
    ]),
  ],
  companions: const [('Shower valves', 1), ('Floor drains, 2"', 1)],
  definitions: const [
    InfoSection(
      'Exposed or concealed',
      'Exposed showers mount on the wall surface; concealed ones hide the '
          'valve and pipes inside the wall.',
    ),
    InfoSection(
      'Floor drain',
      'Every shower area needs a floor drain with a 2" trap.',
    ),
  ],
);
