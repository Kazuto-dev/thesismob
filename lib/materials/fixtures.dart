import '../core/format.dart';
import 'calc_helpers.dart';
import 'items.dart';
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

/// PVC and PPR fittings (elbows, tees, couplings, adapters) cost about 40%
/// of the pipe they join.
const fittingsShare = 0.40;

/// Solvent-cemented joints (one joint is one socket) per metre of pipe,
/// counting couplings and fittings.
const jointsPerMetre = 1.0;

/// Joints one 100 cc can of solvent cement makes, by pipe diameter
/// (Oatey's joints per quart, scaled to 100 cc).
const jointsPer100cc = {'1/2': 32, '3/4': 21, '1': 13, '2': 6, '3': 4, '4': 3};

/// Water pipes per roll of teflon tape, for the threaded adapters.
const pipesPerTeflonRoll = 10;

/// Threaded joints one 10 m roll of teflon tape wraps.
const teflonJointsPerRoll = 40;

/// Price book key of each PVC diameter option.
const _pipeKeyOf = {
  '1/2': '0_5',
  '3/4': '0_75',
  '1': '1',
  '2': '2',
  '3': '3',
  '4': '4',
};

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

/// A descriptive choice shown only when [visibleWhen] holds.
ChoiceField _describing(
  String id,
  String label,
  List<(String, String)> options, {
  VisibleWhen? visibleWhen,
  bool leading = false,
}) => ChoiceField(
  id: id,
  label: label,
  initial: notSpecified,
  visibleWhen: visibleWhen,
  leading: leading,
  options: [
    const ChoiceOption(notSpecified, 'Any'),
    for (final (oid, olabel) in options) ChoiceOption(oid, olabel),
  ],
);

/// "Price per piece" or "Price per set", matching how [unit] is sold.
String _pricePer(QuantityUnit unit) =>
    'Price per ${unit == QuantityUnit.pieces ? 'piece' : unit.singular}';

/// A fixture bought by the piece or set from the price book entry
/// [itemKey]. [companions] lists the items each one also needs and how
/// many; [alsoNeeded] explains them in the Solution sheet.
MaterialSpec _fixture({
  required String id,
  required String name,
  required String summaryName,
  required MaterialCategory category,
  required String blurb,
  required String quantityLabel,
  required String itemKey,
  QuantityUnit unit = QuantityUnit.pieces,
  PriceRef? Function(Map<String, String> selected)? priceRef,
  String? quantityHint,
  List<ChoiceField> choices = const [],
  List<(String, double)> companions = const [],
  InfoSection? alsoNeeded,
  String? note,
  required List<InfoSection> definitions,
  List<String> references = const [],
  List<String> keywords = const [],
}) {
  final things = quantityLabel.replaceFirst('Number of ', '');
  final pricePer = _pricePer(unit);
  return MaterialSpec(
    id: id,
    name: name,
    category: category,
    image: 'assets/images/materials/$id.png',
    blurb: blurb,
    keywords: keywords,
    numbers: [
      NumberField(
        id: 'quantity',
        label: quantityLabel,
        unit: unit.plural,
        hint: quantityHint,
        integer: true,
        max: 100000,
      ),
      priceField(pricePer),
    ],
    choices: choices,
    priceRef: priceRef ?? (_) => PriceRef(itemKey),
    compute: perPiece(
      summaryName,
      descriptors: [for (final c in choices) c.id],
      unit: unit,
      companions: companions,
      itemKey: itemKey,
      note: note,
    ),
    definitions: definitions,
    solution: [
      InfoSection(
        'Cost',
        'Multiply the number of $things by the '
            '${pricePer.toLowerCase()}. The type you choose describes the '
            'item in your summary and does not change the cost.',
        formula: 'cost = $things × ${pricePer.toLowerCase()}',
      ),
      ?alsoNeeded,
    ],
    references: references,
  );
}

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
  keywords: const [
    'bombilya',
    'ilaw',
    'kuryente',
    'light',
    'LED',
    'lamp',
    'lighting',
  ],
  numbers: [
    NumberField(
      id: 'length',
      label: 'Room length',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'width',
      label: 'Room width',
      typical: (min: 0.5, max: 40),
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
  priceRef: (s) => PriceRef(bulbKey(int.tryParse(s['watts'] ?? '') ?? 9)),
  compute: (input) {
    final bulbChoice = input.choice('watts');
    final label = 'LED bulb ${bulbChoice.label.split(',').first}';
    final itemKey = bulbKey(int.parse(bulbChoice.id));
    if (input.chose('mode', 'count')) {
      final quantity = input['quantity'];
      return CalcResult(
        label: label,
        quantity: quantity,
        unit: QuantityUnit.bulbs,
        unitPrice: input['price'],
        itemKey: itemKey,
        companions: [buy('lamp_holder', quantity)],
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
      itemKey: itemKey,
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
        buy('lamp_holder', bulbs.toDouble()),
        buy('junction_box', bulbs.toDouble()),
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
      'The standard screw base for household bulbs in the Philippines. Each '
          'bulb screws into a lamp holder, and each ceiling light hangs from '
          'a junction box. Lighting circuits use 2.0 mm² wire on a 15 A '
          'breaker.',
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
    InfoSection(
      'Also needed',
      'One E27 lamp holder per bulb. When you size a room, each light also '
          'gets a 4" × 4" junction box in the ceiling. Both are priced from '
          'your price book and added to the total.',
      formula: 'lamp holders = bulbs\njunction boxes = bulbs (room size only)',
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
  keywords: const ['suwits', 'kuryente', 'light switch', 'wide series'],
  quantityLabel: 'Number of switches',
  quantityHint: 'One per room entrance; a stair needs a pair of 3-way',
  itemKey: 'switch',
  choices: [
    descriptor('type', 'Switch type', [
      ('1gang', '1 gang'),
      ('2gang', '2 gang'),
      ('3gang', '3 gang'),
      ('3way', '3-way'),
    ]),
  ],
  companions: const [('utility_box', 1), ('switch_plate', 1)],
  alsoNeeded: const InfoSection(
    'Also needed',
    'Each switch sits in a 2" × 4" utility box behind a switch plate. Both '
        'are priced from your price book and added to the total.',
    formula: 'utility boxes = switches\nswitch plates = switches',
  ),
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
  itemKey: 'junction_box',
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
  keywords: const [
    'saksakan',
    'kuryente',
    'socket',
    'convenience outlet',
    'plug',
  ],
  numbers: [
    NumberField(
      id: 'length',
      label: 'Room length',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
      visibleWhen: _byRoom,
    ),
    NumberField(
      id: 'width',
      label: 'Room width',
      typical: (min: 0.5, max: 40),
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
  priceRef: (_) => const PriceRef('outlet'),
  compute: (input) {
    final label = describe('Outlet', [input.choices['type']]);
    const note =
        'Wire outlets with 3.5 mm² on a 20 A breaker, about 6 outlets per '
        'circuit. Kitchen counters need one outlet per 1.2 m of counter.';
    if (input.chose('mode', 'count')) {
      final quantity = input['quantity'];
      return CalcResult(
        label: label,
        quantity: quantity,
        unit: QuantityUnit.pieces,
        unitPrice: input['price'],
        itemKey: 'outlet',
        companions: [buy('utility_box', quantity)],
        note: note,
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
      itemKey: 'outlet',
      details: [
        ResultDetail('Wall around the room', formatLength(roundUp(perimeter))),
        if (doors > 0) ResultDetail('Less doorways', '−${formatLength(doors)}'),
        ResultDetail('One outlet per 3.6 m', formatCount(outlets, 'outlet')),
      ],
      companions: [buy('utility_box', outlets.toDouble())],
      note: note,
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
    InfoSection(
      'Circuits',
      'Outlets are wired with 3.5 mm² wire on a 20 A breaker, usually 6 to 8 '
          'outlets per circuit. 2.0 mm² wire is only for 15 A lighting '
          'circuits.',
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
    InfoSection(
      'Also needed',
      'Each outlet sits in a 2" × 4" utility box, priced from your price '
          'book and added to the total.',
      formula: 'utility boxes = outlets',
    ),
  ],
  references: const [
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
  ],
);

bool _byMetre(Map<String, String> s) => s['buy'] == 'metre';

final wires = MaterialSpec(
  id: 'wires',
  name: 'Electrical Wire',
  category: MaterialCategory.electrical,
  image: 'assets/images/materials/wires.png',
  blurb: 'THHN building wire by circuit, in 150 m boxes',
  keywords: const ['kawad', 'kable', 'kuryente', 'THHN', 'cable', 'wiring'],
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
      visibleWhen: (s) => !_byMetre(s),
    ),
    priceField('Price per metre', visibleWhen: _byMetre),
  ],
  choices: [
    const ChoiceField(
      id: 'size',
      label: 'Wire size',
      initial: '3.5',
      helper:
          '2.0 mm² for 15 A lights, 3.5 mm² for 20 A outlets, 5.5 mm² for '
          '30 A aircon',
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
      helper: 'Line and neutral, plus a green ground wire',
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
  priceRef: (s) {
    final size = s['size'] ?? '3.5';
    return PriceRef(_byMetre(s) ? wireMetreKey(size) : wireBoxKey(size));
  },
  compute: (input) {
    final run = input['run'];
    final size = input.choice('size');
    final conductors = input.choice('conductors').value;
    final metres = run * conductors * (1 + wireAllowance);
    final label = 'THHN wire ${size.label}';
    final details = [
      ResultDetail('Circuit length', formatLength(run)),
      ResultDetail('Wires', '× ${formatNumber(conductors)}'),
      ResultDetail(
        'With 10% for bends and slack',
        formatLength(roundUp(metres, 1)),
      ),
    ];
    final conduit = buy('conduit_half', run * (1 + pipeAllowance) / 3);
    if (input.chose('buy', 'metre')) {
      final bought = ceilCount(metres).toDouble();
      return CalcResult(
        label: label,
        quantity: bought,
        unit: QuantityUnit.metres,
        unitPrice: input['price'],
        itemKey: wireMetreKey(size.id),
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
      itemKey: wireBoxKey(size.id),
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
      'The Philippine Electrical Code caps the breaker on small wire: '
          '2.0 mm² (#14) at 15 A for lighting, 3.5 mm² (#12) at 20 A for '
          'outlets, 5.5 mm² (#10) at 30 A for air conditioners. 8.0 mm² and '
          'up are for feeders.',
    ),
    InfoSection(
      'Wires in the circuit',
      'Every circuit needs a line and a neutral wire, plus a green ground '
          'wire of the same size for circuits up to 30 A.',
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
      'Divide by 150 m per box and round up. By the metre, round up to a '
          'whole metre.',
      formula: 'boxes = round up(metres ÷ 150)',
    ),
    InfoSection(
      'Conduit',
      'PVC conduit ½" comes in 3 m lengths; 10% extra covers fittings and '
          'cuts. It is priced from your price book and added to the total.',
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
    'https://open-exam-prep.com/study-guides/ph-prc-electrical-engineering/pec1-safety-sizing-protection/overcurrent-protection-branch-feeder-design',
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
  itemKey: 'utility_box',
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

bool _ppr(Map<String, String> s) =>
    _isWaterPipe(s['diameter']) && s['length'] == '4';

bool _isWaterPipe(String? diameter) =>
    waterPipeSizes.contains(_pipeKeyOf[diameter ?? '1/2']);

String _pvcKey(Map<String, String> s) {
  final size = _pipeKeyOf[s['diameter']] ?? '0_5';
  return _ppr(s) ? pprKey(size) : pipeKey(size);
}

final pvc = MaterialSpec(
  id: 'pvc',
  name: 'PVC Pipe',
  category: MaterialCategory.plumbing,
  image: 'assets/images/materials/pvc.png',
  blurb: 'Pipes for a run, with fittings, solvent cement and tape',
  keywords: const [
    'tubo',
    'pipe',
    'tubig',
    'drainage',
    'PPR',
    'fittings',
    'solvent cement',
    'neltex',
    'moldex',
  ],
  numbers: [
    const NumberField(
      id: 'run',
      label: 'Total pipe run',
      unit: 'm',
      hint: 'Add up every straight length of pipe',
      max: 100000,
    ),
    priceField('Price per pipe'),
  ],
  choices: [
    const ChoiceField(
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
      label: 'Pipe',
      initial: '3',
      helper: 'PPR is joined by heat, so it needs no solvent cement',
      options: const [
        ChoiceOption('3', 'PVC, 3 m', 3),
        ChoiceOption('4', 'PPR, 4 m', 4),
      ],
      visibleWhen: (s) => _isWaterPipe(s['diameter']),
    ),
  ],
  priceRef: (s) => PriceRef(_pvcKey(s)),
  compute: (input) {
    final run = input['run'];
    final diameter = input.choice('diameter');
    final selected = {for (final e in input.choices.entries) e.key: e.value.id};
    final water = _isWaterPipe(diameter.id);
    final ppr = _ppr(selected);
    final length = ppr ? 4.0 : 3.0;
    final needed = run * (1 + pipeAllowance);
    final pipes = ceilCount(needed / length);
    final price = input['price'];
    final joints = run * jointsPerMetre;
    final perCan = jointsPer100cc[diameter.id]!;
    return CalcResult(
      label: '${ppr ? 'PPR' : 'PVC'} pipe ${diameter.label}',
      quantity: pipes.toDouble(),
      unit: QuantityUnit.pipes,
      unitPrice: price,
      itemKey: _pvcKey(selected),
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
        if (!ppr)
          ResultDetail(
            'Joints, about 1 per metre ($perCan per 100 cc)',
            formatNumber(roundUp(joints, 0)),
          ),
      ],
      companions: [
        allowance(
          'pvc_fittings',
          fittingsShare * pipes * price,
          label: 'Fittings: elbows, tees, couplings (40% of pipe cost)',
        ),
        if (!ppr) buy('solvent_cement', joints / perCan),
        if (water) buy('teflon_tape', pipes / pipesPerTeflonRoll),
      ],
      note:
          'Fittings are an allowance of 40% of the pipe cost. Count them '
          'from your plan for a closer figure.',
    );
  },
  definitions: const [
    InfoSection(
      'PVC pipe',
      'Rigid plastic pipe. Blue pressure pipe carries water; orange or grey '
          'sanitary pipe carries waste water. Standard lengths are 3 m; PPR '
          'hot-and-cold water pipe comes in 4 m and is joined by heat '
          'fusion.',
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
    InfoSection(
      'Fittings, solvent cement and teflon tape',
      'Elbows, tees, couplings and adapters usually cost about 40% as much '
          'as the pipe. PVC joints are glued with solvent cement, sold in '
          '100 cc cans; bigger pipes take more per joint. Threaded adapters '
          'on water lines are sealed with teflon tape.',
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
    InfoSection(
      'Fittings',
      'An allowance of 40% of the pipe cost, added to the total.',
      formula: 'fittings = 0.40 × pipes × price per pipe',
    ),
    InfoSection(
      'Solvent cement',
      'About one glued joint per metre of run, counting couplings and '
          'fittings. A 100 cc can makes 32 joints at ½", 21 at ¾", 13 at 1", '
          '6 at 2", 4 at 3" and 3 at 4". PPR needs none.',
      formula: 'cans = round up(run ÷ joints per can)',
    ),
    InfoSection(
      'Teflon tape',
      'For ½" to 1" water lines only: one roll per 10 pipes, for the '
          'threaded adapters.',
      formula: 'rolls = round up(pipes ÷ 10)',
    ),
  ],
  references: const [
    'https://www.neltex.com/products.do?item_id=51663',
    'https://mpi.moldex.com.ph/mb-pipes-and-fittings',
    'https://www.commercial-industrial-supply.com/resource-center/how-much-pvc-glue-to-use/',
    'https://www.simplywise.com/blog/how-to-estimate-plumbing-job/',
  ],
);

bool _kitchen(Map<String, String> s) => s['use'] == 'kitchen';
bool _lavatory(Map<String, String> s) => !_kitchen(s);

final sink = MaterialSpec(
  id: 'sink',
  name: 'Sink',
  category: MaterialCategory.plumbing,
  image: 'assets/images/materials/sink.png',
  blurb: 'Lavatories and kitchen sinks, with valves, hoses and traps',
  keywords: const [
    'lababo',
    'lavatory',
    'basin',
    'hugasan',
    'kitchen sink',
    'banyo',
  ],
  numbers: [
    const NumberField(
      id: 'quantity',
      label: 'Number of sinks',
      unit: 'pcs',
      integer: true,
      max: 100000,
    ),
    priceField('Price per set', visibleWhen: _lavatory),
    priceField('Price per piece', id: 'piecePrice', visibleWhen: _kitchen),
  ],
  choices: [
    const ChoiceField(
      id: 'use',
      label: 'Sink',
      initial: 'lavatory',
      leading: true,
      options: [
        ChoiceOption('lavatory', 'Lavatory (bathroom)'),
        ChoiceOption('kitchen', 'Kitchen sink'),
      ],
    ),
    _describing('type', 'Lavatory type', [
      ('wall', 'Wall-hung'),
      ('pedestal', 'Pedestal'),
      ('vessel', 'Vessel'),
      ('drop_in', 'Drop-in'),
      ('undermount', 'Undermount'),
    ], visibleWhen: _lavatory),
    _describing('bowl', 'Kitchen sink type', [
      ('single', 'Single bowl'),
      ('double', 'Double bowl'),
      ('drainboard', 'With drainboard'),
    ], visibleWhen: _kitchen),
    const ChoiceField(
      id: 'supply',
      label: 'Water supply',
      initial: 'cold',
      helper: 'One angle valve and hose for each supply line',
      options: [
        ChoiceOption('cold', 'Cold only', 1),
        ChoiceOption('hot', 'Hot and cold', 2),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_kitchen(s) ? 'kitchen_sink' : 'lavatory'),
  compute: (input) {
    final kitchen = input.chose('use', 'kitchen');
    final quantity = input['quantity'];
    final lines = input.choice('supply').value;
    return CalcResult(
      label: kitchen
          ? describe('Kitchen sink', [input.choices['bowl']])
          : describe('Lavatory', [input.choices['type']]),
      quantity: quantity,
      unit: kitchen ? QuantityUnit.pieces : QuantityUnit.sets,
      unitPrice: kitchen ? input['piecePrice'] : input['price'],
      itemKey: kitchen ? 'kitchen_sink' : 'lavatory',
      companions: [
        buy('angle_valve', quantity * lines),
        buy('flexible_hose', quantity * lines),
        buy('p_trap', quantity),
      ],
      note:
          'Add the faucets with the Faucet calculator. Some lavatory sets '
          'come with a P-trap; check before buying.',
    );
  },
  definitions: const [
    InfoSection(
      'Sink types',
      'A lavatory is the bathroom basin: wall-hung and pedestal basins stand '
          'alone, vessel basins sit on a counter, and drop-in and undermount '
          'basins are set into it. Kitchen sinks are usually stainless, with '
          'one or two bowls.',
    ),
    InfoSection(
      'Angle valve and hose',
      'The angle valve shuts off water at the wall; a flexible hose links it '
          'to the faucet. A sink with hot and cold water needs two of each.',
    ),
    InfoSection(
      'P-trap',
      'The U-bend under the sink. It holds water to keep sewer gas out: '
          '1¼" for lavatories, 1½" for kitchen sinks.',
    ),
  ],
  solution: const [
    InfoSection(
      'Cost',
      'Multiply the number of sinks by the price per set (lavatory) or per '
          'piece (kitchen sink). The type describes the item in your summary '
          'and does not change the cost.',
      formula: 'cost = sinks × price',
    ),
    InfoSection(
      'Also needed',
      'Each supply line needs an angle valve and a flexible hose, and each '
          'sink a P-trap. They are priced from your price book and added to '
          'the total.',
      formula:
          'angle valves = hoses = sinks × supply lines (1 or 2)\n'
          'P-traps = sinks',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/',
  ],
);

bool _squat(Map<String, String> s) => s['type'] == 'squat';

final toilet = MaterialSpec(
  id: 'toilet',
  name: 'Toilet',
  category: MaterialCategory.plumbing,
  image: 'assets/images/materials/toilet.png',
  blurb: 'Water closets, with valves and seals',
  keywords: const ['inidoro', 'kubeta', 'water closet', 'WC', 'CR', 'banyo'],
  numbers: [
    const NumberField(
      id: 'quantity',
      label: 'Number of toilets',
      unit: 'pcs',
      integer: true,
      max: 100000,
    ),
    priceField('Price per set', visibleWhen: (s) => !_squat(s)),
    priceField('Price per piece', id: 'piecePrice', visibleWhen: _squat),
  ],
  choices: [
    _describing('type', 'Toilet type', [
      ('two_piece', 'Two-piece'),
      ('one_piece', 'One-piece'),
      ('squat', 'Squat'),
    ]),
  ],
  priceRef: (s) => PriceRef(_squat(s) ? 'squat_toilet' : 'toilet'),
  compute: (input) {
    final squat = input.chose('type', 'squat');
    final quantity = input['quantity'];
    return CalcResult(
      label: describe('Toilet', [input.choices['type']]),
      quantity: quantity,
      unit: squat ? QuantityUnit.pieces : QuantityUnit.sets,
      unitPrice: squat ? input['piecePrice'] : input['price'],
      itemKey: squat ? 'squat_toilet' : 'toilet',
      companions: [
        buy('angle_valve', quantity),
        buy('flexible_hose', quantity),
        if (!squat) ...[
          buy('wax_ring', quantity),
          buy('closet_bolts', quantity),
        ],
      ],
      note: squat
          ? 'A squat bowl is set in mortar, so it needs no wax ring or bolts.'
          : null,
    );
  },
  definitions: const [
    InfoSection(
      'Toilet types',
      'Two-piece toilets have a separate tank; one-piece toilets are a '
          'single casting that is easier to clean. Squat bowls are set into '
          'the floor in mortar.',
    ),
    InfoSection(
      'Angle valve and hose',
      'The angle valve shuts off water at the wall; a flexible hose feeds '
          'the flush tank.',
    ),
    InfoSection(
      'Wax ring and closet bolts',
      'The wax ring seals the toilet to its floor outlet on the soil pipe; '
          'closet bolts hold it down.',
    ),
  ],
  solution: const [
    InfoSection(
      'Cost',
      'Multiply the number of toilets by the price per set, or per piece '
          'for squat bowls.',
      formula: 'cost = toilets × price',
    ),
    InfoSection(
      'Also needed',
      'Each toilet needs an angle valve and a flexible hose; sitting toilets '
          'also need a wax ring and a closet bolt set. They are priced from '
          'your price book and added to the total.',
      formula:
          'angle valves = hoses = toilets\n'
          'wax rings = bolt sets = toilets (not squat)',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/',
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
  itemKey: 'faucet',
  choices: [
    descriptor('type', 'Faucet type', [
      ('single', 'Single-handle'),
      ('double', 'Double-handle'),
      ('gooseneck', 'Gooseneck'),
      ('pull_out', 'Pull-out'),
      ('hose_bibb', 'Hose bibb'),
    ]),
  ],
  companions: const [('teflon_tape', 2 / teflonJointsPerRoll)],
  alsoNeeded: const InfoSection(
    'Also needed',
    'A faucet has about 2 threaded joints, and a 10 m roll of teflon tape '
        'wraps about 40. The tape is priced from your price book and added '
        'to the total.',
    formula: 'rolls = round up(faucets × 2 ÷ 40)',
  ),
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
  keywords: const ['dutsa', 'shower head', 'bathroom', 'banyo'],
  quantityLabel: 'Number of showers',
  itemKey: 'shower_set',
  unit: QuantityUnit.sets,
  choices: [
    descriptor('type', 'Shower type', [
      ('exposed', 'Exposed'),
      ('concealed', 'Concealed'),
      ('mixer', 'Mixer'),
    ]),
  ],
  companions: const [
    ('shower_valve', 1),
    ('floor_drain', 1),
    ('teflon_tape', 4 / teflonJointsPerRoll),
  ],
  alsoNeeded: const InfoSection(
    'Also needed',
    'Each shower needs a shower valve and a floor drain. Its valve, arm and '
        'head have about 4 threaded joints, and a 10 m roll of teflon tape '
        'wraps about 40. They are priced from your price book and added to '
        'the total.',
    formula:
        'shower valves = floor drains = showers\n'
        'teflon rolls = round up(showers × 4 ÷ 40)',
  ),
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
