import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'fixtures.dart' show wireAllowance, wireBoxLength;
import 'items.dart';
import 'material_spec.dart';
import 'work_items.dart';

// Whole-house services: electrical rough-in, water storage and septic
// tank. Sources are listed in docs/calculations.md.

// ---------------------------------------------------------------------------
// Electrical rough-in
// ---------------------------------------------------------------------------

/// Lighting outlets on one 15 A circuit (practice: 8 to 10).
const lightsPerCircuit = 8;

/// Convenience outlets on one 20 A circuit (practice: 6 to 8).
const outletsPerCircuit = 6;

/// 20 A small-appliance circuits every dwelling needs for the kitchen and
/// dining area, plus one 20 A laundry circuit.
const smallApplianceCircuits = 2;
const laundryCircuits = 1;

/// Spare panel spaces for future circuits, as a share of the circuits.
const panelSpare = 0.25;

/// Conduit per outlet point (light, switch or outlet) on one storey, and
/// the extra per point for each storey above the first.
const conduitPerPoint = 5.0;
const conduitPerExtraStorey = 1.5;

/// Line, neutral and an equipment ground of the same size: PEC allows a
/// ground the size of the circuit wire for circuits up to 30 A.
const conductorsPerCircuit = 3;

/// PVC conduit is sold in 3 m lengths.
const conduitLength = 3.0;

/// Extra conduit for bends, offsets and cuts.
const conduitAllowance = 0.10;

/// Below this many metres of one size, wire is cut from the reel instead of
/// bought by the 150 m box.
const wireBoxMinimum = 100.0;

/// Circuits one roll of electrical tape covers.
const circuitsPerTapeRoll = 4;

/// The panel size a form starts with; it suits most houses.
const typicalPanelBranches = 12;

/// One kind of branch circuit in the schedule.
typedef BranchCircuits = ({
  String label,
  int count,
  int amps,
  String wire,
  double conduit,
});

/// Buys [metres] of [size] wire: whole 150 m boxes, and the rest by the
/// metre unless it is at least 100 m, when another box is cheaper.
List<Companion> _buyWire(String size, double metres) {
  if (metres <= 0) return const [];
  var boxes = (metres / wireBoxLength + 1e-9).floor();
  var rest = metres - boxes * wireBoxLength;
  if (rest >= wireBoxMinimum) {
    boxes++;
    rest = 0;
  }
  return [
    if (boxes > 0) buy(wireBoxKey(size), boxes.toDouble()),
    if (rest > 1e-6) buy(wireMetreKey(size), rest),
  ];
}

int _count(CalcInput input, String id) => input.optional(id).round();

final roughIn = MaterialSpec(
  id: 'rough_in',
  name: 'Electrical Rough-in',
  category: MaterialCategory.electrical,
  icon: Icons.electrical_services_outlined,
  blurb: 'Circuits, wire, conduit, boxes and breakers for a whole house',
  keywords: const [
    'kuryente',
    'wiring',
    'house wiring',
    'circuit',
    'panel board',
    'breaker',
    'conduit',
    'rough-in',
    'linya ng kuryente',
    'THHN',
  ],
  numbers: const [
    NumberField(
      id: 'lights',
      label: 'Lighting outlets',
      unit: 'pcs',
      hint: 'Ceiling and wall lights',
      integer: true,
      max: 1000,
    ),
    NumberField(
      id: 'outlets',
      label: 'Convenience outlets',
      unit: 'pcs',
      hint: 'Wall sockets, including the washer outlet',
      integer: true,
      max: 1000,
    ),
    NumberField(
      id: 'switches',
      label: 'Switches',
      unit: 'pcs',
      hint: 'Optional. Leave empty for 1 per 2 lights',
      integer: true,
      optional: true,
      max: 1000,
    ),
    NumberField(
      id: 'aircons',
      label: 'Aircon units',
      unit: 'pcs',
      hint: 'Optional. Each gets its own circuit',
      integer: true,
      optional: true,
      max: 100,
    ),
    NumberField(
      id: 'dedicated',
      label: 'Other 20 A appliance circuits',
      unit: 'pcs',
      hint: 'Optional. Water heater, pump, refrigerator, washer…',
      integer: true,
      optional: true,
      max: 100,
    ),
    NumberField(
      id: 'homeRun',
      label: 'Home run per circuit',
      typical: (min: 2, max: 60),
      unit: 'm',
      hint: 'Conduit from the panel to the first box of each circuit',
      initial: '10',
      max: 1000,
    ),
    NumberField(
      id: 'price',
      label: 'Price of the panel board',
      unit: '₱',
      isPrice: true,
      max: 10000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'aircon',
      label: 'Aircon size',
      initial: 'small',
      helper: 'Used when you enter aircon units',
      options: [
        ChoiceOption('small', 'Up to 1 HP: 20 A, 3.5 mm²'),
        ChoiceOption('large', '1.5 to 2.5 HP: 30 A, 5.5 mm²'),
      ],
    ),
    const ChoiceField(
      id: 'storeys',
      label: 'Storeys',
      initial: '1',
      helper: 'Upper floors need longer drops to the panel',
      options: [
        ChoiceOption('1', '1 storey', 1),
        ChoiceOption('2', '2 storeys', 2),
        ChoiceOption('3', '3 storeys', 3),
      ],
    ),
    ChoiceField(
      id: 'panel',
      label: 'Panel board',
      initial: '$typicalPanelBranches',
      helper:
          'The breakdown recommends a size with 25% spare spaces; pick it '
          'to price that panel.',
      options: [
        for (final n in panelBranches)
          ChoiceOption('$n', '$n branches', n.toDouble()),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(
    panelKey(int.tryParse(s['panel'] ?? '') ?? typicalPanelBranches),
  ),
  compute: (input) {
    final lights = input['lights'].round();
    final outlets = input['outlets'].round();
    final switchesEntered = _count(input, 'switches');
    final switches = switchesEntered > 0
        ? switchesEntered
        : (lights / 2).ceil();
    final aircons = _count(input, 'aircons');
    final dedicated = _count(input, 'dedicated');
    final large = input.chose('aircon', 'large');
    final storeys = input.choice('storeys').value;
    final homeRun = input['homeRun'];
    final perPoint = conduitPerPoint + conduitPerExtraStorey * (storeys - 1);

    final lighting = ceilCount(lights / lightsPerCircuit);
    final general = math.max(
      ceilCount(outlets / outletsPerCircuit),
      smallApplianceCircuits,
    );
    final schedule = <BranchCircuits>[
      (
        label: 'Lighting',
        count: lighting,
        amps: 15,
        wire: '2.0',
        conduit: (lights + switches) * perPoint + lighting * homeRun,
      ),
      (
        label: 'Convenience outlets',
        count: general,
        amps: 20,
        wire: '3.5',
        conduit: outlets * perPoint + general * homeRun,
      ),
      (
        label: 'Laundry',
        count: laundryCircuits,
        amps: 20,
        wire: '3.5',
        conduit: laundryCircuits * homeRun,
      ),
      if (aircons > 0)
        (
          label: large ? 'Aircon, 1.5 to 2.5 HP' : 'Aircon, up to 1 HP',
          count: aircons,
          amps: large ? 30 : 20,
          wire: large ? '5.5' : '3.5',
          conduit: aircons * (perPoint + homeRun),
        ),
      if (dedicated > 0)
        (
          label: 'Other appliances',
          count: dedicated,
          amps: 20,
          wire: '3.5',
          conduit: dedicated * (perPoint + homeRun),
        ),
    ];

    final circuits = schedule.fold(0, (sum, c) => sum + c.count);
    // Every light, switch, outlet, aircon and appliance outlet is a point.
    final points = lights + switches + outlets + aircons + dedicated;
    final spaces = ceilCount(circuits * (1 + panelSpare));
    final recommended = panelBranches.where((n) => n >= spaces).firstOrNull;
    final branches = input.choice('panel').value.round();
    if (branches < circuits) {
      throw ArgumentError(
        recommended == null
            ? 'This house needs about $spaces panel spaces, more than a '
                  '${panelBranches.last}-branch panel holds. Ask an '
                  'electrician to split it over two panels'
            : 'A $branches-branch panel cannot hold $circuits circuits. '
                  'Choose $recommended branches',
      );
    }

    final conduitRun = schedule.fold(0.0, (sum, c) => sum + c.conduit);
    final wireBySize = <String, double>{};
    final breakers = <int, int>{};
    for (final c in schedule) {
      wireBySize[c.wire] =
          (wireBySize[c.wire] ?? 0) +
          c.conduit * conductorsPerCircuit * (1 + wireAllowance);
      breakers[c.amps] = (breakers[c.amps] ?? 0) + c.count;
    }
    final sizes = [
      for (final size in wireSizes)
        if (wireBySize.containsKey(size)) size,
    ];
    final amps = [
      for (final a in breakerRatings)
        if (breakers.containsKey(a)) a,
    ];

    final companions = [
      for (final size in sizes) ..._buyWire(size, wireBySize[size]!),
      buy('conduit_half', conduitRun * (1 + conduitAllowance) / conduitLength),
      buy('utility_box', (switches + outlets + aircons + dedicated).toDouble()),
      buy('junction_box', lights.toDouble()),
      buy('switch', switches.toDouble()),
      buy('switch_plate', switches.toDouble()),
      buy('outlet', (outlets + dedicated).toDouble()),
      buy('aircon_outlet', aircons.toDouble()),
      for (final a in amps)
        buy(breakerKey(a), breakers[a]!.toDouble(), work: Work.panel),
      buy('ground_rod', 1),
      buy('electrical_tape', circuits / circuitsPerTapeRoll),
    ];

    return CalcResult(
      label: 'Electrical rough-in, ${formatCount(circuits, 'circuit')}',
      quantity: 1,
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      itemKey: panelKey(branches),
      details: [
        if (switchesEntered == 0)
          ResultDetail(
            'Switches, 1 per 2 lights',
            formatNumber(switches.toDouble()),
          ),
        for (final c in schedule)
          ResultDetail(
            '${c.label}, ${c.amps} A, ${c.wire} mm²',
            formatCount(c.count, 'circuit'),
          ),
        ResultDetail('Circuits', formatCount(circuits, 'circuit')),
        ResultDetail(
          'Panel spaces with 25% spare',
          formatNumber(spaces.toDouble()),
        ),
        ResultDetail(
          'Recommended panel',
          recommended == null ? 'Two panels' : '$recommended branches',
        ),
        ResultDetail('Panel board chosen', '$branches branches'),
        ResultDetail('Conduit per point', formatLength(perPoint)),
        ResultDetail('Conduit run', formatLength(roundUp(conduitRun, 1))),
        for (final size in sizes)
          ResultDetail(
            'Wire $size mm², 3 wires + 10%',
            formatLength(roundUp(wireBySize[size]!, 1)),
          ),
      ],
      companions: [
        for (final c in companions)
          if (c.quantity > 0) c,
      ],
      note:
          'A planning estimate. A licensed electrical engineer must design '
          'the circuits and sign the plans under the Philippine Electrical '
          'Code. The service entrance, meter base and main feeder are not '
          'included.',
      works: [
        if (points > 0) WorkQuantity(Work.roughIn, points.toDouble()),
        const WorkQuantity(Work.panel, 1),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Rough-in',
      'Everything hidden in the walls and ceiling before the finishes: '
          'conduit, boxes, wire and the panel board, plus the switches, '
          'outlets and breakers that complete each circuit.',
    ),
    InfoSection(
      'Branch circuit',
      'One breaker in the panel and the wires it protects. The Philippine '
          'Electrical Code limits small wire to 15 A on 2.0 mm², 20 A on '
          '3.5 mm² and 30 A on 5.5 mm² (PEC 2.40.1.4(D)).',
    ),
    InfoSection(
      'Circuits a house needs',
      'Lights go on 15 A circuits of at most 8 lights. Outlets go on 20 A '
          'circuits of at most 6, with at least 2 small-appliance circuits '
          'for the kitchen and dining area and 1 laundry circuit. Each '
          'aircon gets its own circuit: 20 A on 3.5 mm² up to 1 HP, 30 A on '
          '5.5 mm² for 1.5 to 2.5 HP. A water heater, pump or other large '
          'appliance also gets its own 20 A circuit; an electric range may '
          'need 40 A.',
    ),
    InfoSection(
      'Panel board',
      'The box of breakers where every circuit starts. Leave 20 to 30% of '
          'its spaces spare for future circuits.',
    ),
    InfoSection(
      'Home run',
      'The conduit from the panel board to the first box of a circuit. '
          'About 10 m in a small house; measure it on your plan for a large '
          'one.',
    ),
    InfoSection(
      'Ground wire and ground rod',
      'Every circuit carries a green ground wire, and the panel is bonded '
          'to a copper-clad ground rod driven into the soil.',
    ),
  ],
  solution: const [
    InfoSection(
      'Circuits',
      'Lighting circuits are the lights ÷ 8; outlet circuits are the outlets '
          '÷ 6 but at least 2, plus 1 laundry circuit. Add one circuit per '
          'aircon and per other appliance.',
      formula:
          'lighting = round up(lights ÷ 8)\n'
          'outlet circuits = max(round up(outlets ÷ 6), 2) + 1\n'
          'circuits = lighting + outlet + aircons + appliances',
    ),
    InfoSection(
      'Panel board',
      'Add 25% spare spaces and round up to a panel size: 4, 6, 8, 12, 16, '
          '20, 24 or 30 branches. That is the recommended panel; the form '
          'starts at 12 branches, so pick the recommended size to price it. '
          'The panel is the main item.',
      formula:
          'spaces = round up(circuits × 1.25)\n'
          'recommended = smallest panel ≥ spaces',
    ),
    InfoSection(
      'Conduit',
      'Allow 5 m of conduit per light, switch and outlet, 1.5 m more per '
          'point for each storey above the first, plus a home run per '
          'circuit. Aircon and appliance circuits have one point each. '
          'Conduit comes in 3 m lengths; add 10%.',
      formula:
          'run per point = 5 + 1.5 × (storeys − 1)\n'
          'run = points × run per point + circuits × home run\n'
          'lengths = round up(run × 1.1 ÷ 3)',
    ),
    InfoSection(
      'Wire',
      'Each circuit has a line, a neutral and a ground wire of the same '
          'size, along its conduit run, plus 10% for slack. Each size is '
          'bought in 150 m boxes; less than 100 m left over is cut by the '
          'metre.',
      formula:
          'metres = run × 3 × 1.10\n'
          'boxes = whole 150 m boxes, + 1 if 100 m or more is left',
    ),
    InfoSection(
      'Boxes and devices',
      'A utility box for every switch, outlet, aircon and appliance outlet; '
          'a junction box for every light. Switches come with a plate. Each '
          'appliance circuit ends at an outlet.',
      formula:
          'utility boxes = switches + outlets + aircons + appliances\n'
          'junction boxes = lights\n'
          'outlets bought = outlets + appliances\n'
          'aircon outlets = aircons',
    ),
    InfoSection(
      'Breakers, ground and tape',
      'One breaker per circuit at its rating, one ground rod set, and a roll '
          'of electrical tape for every 4 circuits. All of these are priced '
          'from your price book and added to the total.',
      formula: 'tape = round up(circuits ÷ 4)',
    ),
  ],
  references: const [
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
    'https://open-exam-prep.com/study-guides/ph-prc-electrical-engineering/pec1-safety-sizing-protection/overcurrent-protection-branch-feeder-design',
    'https://pdfcoffee.com/lecture-11-electrical-system-design-residential-pdf-free.html',
    'https://phelpsdodge.com.ph/frequently-asked-questions/',
    'https://aedoconstruction.com/blog/house-rewiring-cost-philippines/',
  ],
);

// ---------------------------------------------------------------------------
// Water tank
// ---------------------------------------------------------------------------

final waterTank = MaterialSpec(
  id: 'water_tank',
  name: 'Water Tank',
  category: MaterialCategory.plumbing,
  icon: Icons.water_drop_outlined,
  blurb: 'Tanks to store a day or more of water for the household',
  keywords: const [
    'tangke',
    'tangke ng tubig',
    'tubig',
    'imbakan ng tubig',
    'water storage',
    'cistern',
    'poly tank',
  ],
  numbers: [
    const NumberField(
      id: 'persons',
      label: 'People in the house',
      unit: 'persons',
      integer: true,
      max: 10000,
    ),
    priceField('Price per tank'),
  ],
  choices: [
    const ChoiceField(
      id: 'use',
      label: 'Water use per person',
      initial: '150',
      helper: '150 L a day is the usual planning figure',
      options: [
        ChoiceOption('100', '100 L a day', 100),
        ChoiceOption('150', '150 L a day', 150),
        ChoiceOption('200', '200 L a day', 200),
      ],
    ),
    const ChoiceField(
      id: 'days',
      label: 'Storage',
      initial: '1',
      helper: 'Keep at least a day where water is often cut off',
      options: [
        ChoiceOption('1', '1 day', 1),
        ChoiceOption('2', '2 days', 2),
        ChoiceOption('3', '3 days', 3),
      ],
    ),
    ChoiceField(
      id: 'size',
      label: 'Tank size',
      initial: '1000',
      helper: 'Polyethylene tanks',
      options: [
        for (final l in waterTankLitres)
          ChoiceOption('$l', '${formatNumber(l.toDouble())} L', l.toDouble()),
      ],
    ),
  ],
  priceRef: (s) =>
      PriceRef(waterTankKey(int.tryParse(s['size'] ?? '') ?? 1000)),
  compute: (input) {
    final persons = input['persons'];
    final perPerson = input.choice('use').value;
    final days = input.choice('days').value;
    final size = input.choice('size');
    final daily = persons * perPerson;
    final storage = daily * days;
    final tanks = ceilCount(storage / size.value);
    return CalcResult(
      label: 'Water tank, ${size.label}',
      quantity: tanks.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      itemKey: waterTankKey(size.value.round()),
      details: [
        ResultDetail(
          'Daily use (${formatNumber(perPerson)} L × people)',
          '${formatNumber(daily)} L',
        ),
        ResultDetail(
          'Storage for ${formatCount(days, 'day')}',
          '${formatNumber(storage)} L',
        ),
        ResultDetail('Tanks of ${size.label}', formatCount(tanks, 'tank')),
        ResultDetail('Storage bought', '${formatNumber(tanks * size.value)} L'),
      ],
      companions: [buy('float_valve', tanks.toDouble())],
      note:
          'Set tanks on a level, sturdy base. A full 1,000 L tank weighs '
          'about a tonne.',
      works: [if (tanks > 0) WorkQuantity(Work.tank, tanks.toDouble())],
    );
  },
  definitions: const [
    InfoSection(
      'Water use',
      'About 150 L per person per day is the usual planning figure for a '
          'Philippine home; LWUA uses about 140 L for a household of 6. '
          'Choose 100 L for a frugal household or 200 L for one with a '
          'garden or many appliances.',
    ),
    InfoSection(
      'Storage',
      'Where the water supply is cut off often, store at least one day of '
          'use. An overhead tank usually holds about a third of the total.',
    ),
    InfoSection(
      'Float valve',
      'A valve on the tank inlet that closes when the tank is full, so it '
          'does not overflow.',
    ),
  ],
  solution: const [
    InfoSection(
      'Storage needed',
      'Multiply the people by the water each uses a day and by the days of '
          'storage.',
      formula: 'storage = people × litres per day × days',
    ),
    InfoSection(
      'Tanks',
      'Divide by the tank size and round up.',
      formula: 'tanks = round up(storage ÷ tank size)',
    ),
    InfoSection(
      'Cost',
      'Multiply the tanks by the price per tank. Each tank also gets a float '
          'valve, priced from your price book and added to the total.',
      formula: 'cost = tanks × price per tank\nfloat valves = tanks',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/npc-water-tank-cistern-sizing-calculator-philippines/',
  ],
);

// ---------------------------------------------------------------------------
// Septic tank
// ---------------------------------------------------------------------------

/// Liquid capacity of a septic tank for a single-family house, by
/// bedrooms, in m³ (NPC Appendix B Table B-2; 3 bedrooms and up follow
/// the UPC table it is based on).
double septicVolumeForBedrooms(int bedrooms) {
  if (bedrooms <= 2) return 2.838;
  if (bedrooms == 3) return 3.785;
  if (bedrooms == 4) return 4.542;
  if (bedrooms <= 6) return 5.678;
  return 5.678 + 0.568 * (bedrooms - 6);
}

/// Liquid capacity per person when the household is large for its
/// bedrooms, in m³.
const septicPerPerson = 0.15;

/// Liquid capacity of one ready-made polyethylene septic tank, in m³.
const peSepticTankVolume = 2.0;

/// Inside proportions of a block septic tank: liquid depth, the air space
/// above it, length twice the width, and the NPC minimum size.
const septicLiquidDepth = 1.2;
const septicFreeboard = 0.3;
const septicLengthToWidth = 2.0;
const septicMinLength = 1.5;
const septicMinWidth = 0.9;

/// The inlet chamber takes two thirds of the length.
const septicInletShare = 2 / 3;

/// A 6" block wall is 0.15 m thick.
const chb6Thickness = 0.15;

/// Floor and cover slabs: 0.10 m of Class A concrete with 10 mm bars at
/// 0.20 m both ways.
const septicSlabThickness = 0.10;
const septicBarSpacing = 0.20;

/// 10 mm bars per m² of block wall: vertical every 0.60 m and horizontal
/// every third course, laps included (Fajardo).
const septicWallBars = 4.28;

/// Lap of a 10 mm bar spliced to reach a long span.
const _barLap = 0.40;

/// Rounds a dimension up to the next 5 cm.
double _upTo5cm(double metres) => ceilCount(metres * 20) / 20;

/// 6 m bars needed to cut [pieces] bars of [length] m.
int _barsToCut(int pieces, double length) {
  if (length <= rebarStockLength) {
    final perBar = (rebarStockLength / length + 1e-9).floor();
    return ceilCount(pieces / perBar);
  }
  final splices = ceilCount(length / rebarStockLength) - 1;
  return ceilCount(pieces * (length + splices * _barLap) / rebarStockLength);
}

bool _peTank(Map<String, String> s) => s['type'] == 'pe';

final septicTank = MaterialSpec(
  id: 'septic_tank',
  name: 'Septic Tank',
  category: MaterialCategory.plumbing,
  icon: Icons.propane_tank_outlined,
  blurb: 'Tank size for a house, as a ready-made tank or built of blocks',
  keywords: const [
    'poso negro',
    'pozo negro',
    'septic',
    'tangke',
    'sanitary',
    'CHB septic tank',
  ],
  numbers: [
    const NumberField(
      id: 'bedrooms',
      label: 'Bedrooms',
      unit: 'rooms',
      integer: true,
      max: 100,
    ),
    const NumberField(
      id: 'persons',
      label: 'People in the house',
      unit: 'persons',
      hint: 'Optional. Sizes a bigger tank for a large household',
      integer: true,
      optional: true,
      max: 10000,
    ),
    priceField('Price per block', visibleWhen: (s) => !_peTank(s)),
    priceField('Price per tank', id: 'tankPrice', visibleWhen: _peTank),
  ],
  choices: const [
    ChoiceField(
      id: 'type',
      label: 'Septic tank',
      initial: 'chb',
      leading: true,
      options: [
        ChoiceOption('chb', 'Concrete hollow block, built on site'),
        ChoiceOption('pe', 'Polyethylene, ready-made'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_peTank(s) ? 'septic_tank' : 'chb_6'),
  compute: (input) {
    final bedrooms = input['bedrooms'].round();
    final persons = input.optional('persons');
    final byBedrooms = septicVolumeForBedrooms(bedrooms);
    final byPersons = persons * septicPerPerson;
    final volume = math.max(byBedrooms, byPersons);
    final sizing = [
      ResultDetail(
        'Capacity for ${formatCount(bedrooms, 'bedroom')}',
        formatVolume(byBedrooms),
      ),
      if (persons > 0)
        ResultDetail(
          'Capacity for ${formatCount(persons, 'person')} × 0.15 m³',
          formatVolume(roundUp(byPersons, 3)),
        ),
      ResultDetail('Liquid capacity', formatVolume(roundUp(volume, 3))),
    ];

    if (input.chose('type', 'pe')) {
      final tanks = ceilCount(volume / peSepticTankVolume);
      return CalcResult(
        label: 'Septic tank, polyethylene, 2,000 L',
        quantity: tanks.toDouble(),
        unit: QuantityUnit.pieces,
        unitPrice: input['tankPrice'],
        itemKey: 'septic_tank',
        details: [
          ...sizing,
          ResultDetail(
            'Tanks of 2,000 L, 2 chambers',
            formatCount(tanks, 'tank'),
          ),
        ],
        note:
            'Set the tank at least 15 m from any well, outside the house. '
            'Check the size with the tank supplier.',
        works: const [WorkQuantity(Work.tank, 1)],
      );
    }

    const t = chb6Thickness;
    const depth = septicLiquidDepth + septicFreeboard;
    final width = _upTo5cm(
      math.max(
        septicMinWidth,
        math.sqrt(volume / (septicLengthToWidth * septicLiquidDepth)),
      ),
    );
    final length = _upTo5cm(
      math.max(septicMinLength, volume / (septicLiquidDepth * width)),
    );
    // Outer walls on their centre line, plus a baffle across the width.
    final outerWalls = (2 * (length + width) + 4 * t) * depth;
    final baffle = width * depth;
    final wallArea = outerWalls + baffle;
    final blocks = withWaste(ceilCount(wallArea * chbPerSquareMetre), 0.05);
    final plaster = 2 * (length + width) * depth + 2 * baffle;

    final slabLength = length + 2 * t;
    final slabWidth = width + 2 * t;
    final concrete = 2 * slabLength * slabWidth * septicSlabThickness;
    final mix = concreteMix('A');
    final mortar = chbMortar['6']!;

    final barsAlong = ceilCount(slabWidth / septicBarSpacing) + 1;
    final barsAcross = ceilCount(slabLength / septicBarSpacing) + 1;
    final slabBars =
        _barsToCut(2 * barsAlong, slabLength) +
        _barsToCut(2 * barsAcross, slabWidth);
    final wallBars = ceilCount(wallArea * septicWallBars / rebarStockLength);
    final ties = 2 * barsAlong * barsAcross;

    return CalcResult(
      label:
          'Septic tank, 6" CHB, ${formatNumber(length)} × '
          '${formatNumber(width)} × ${formatNumber(depth)} m',
      area: wallArea,
      quantity: blocks.total.toDouble(),
      unit: QuantityUnit.blocks,
      unitPrice: input['price'],
      itemKey: 'chb_6',
      details: [
        ...sizing,
        ResultDetail(
          'Inside size, L × W × H',
          '${formatNumber(length)} × ${formatNumber(width)} × '
              '${formatNumber(depth)} m',
        ),
        ResultDetail(
          'Liquid depth + air space',
          '${formatLength(septicLiquidDepth)} + '
              '${formatLength(septicFreeboard)}',
        ),
        ResultDetail(
          'Baffle wall from the inlet end',
          formatLength(roundUp(length * septicInletShare)),
        ),
        ResultDetail(
          'Walls with baffle, 6" CHB',
          formatArea(roundUp(wallArea)),
        ),
        ResultDetail(
          'Blocks at 12.5 per m²',
          formatQuantity(blocks.base.toDouble(), QuantityUnit.blocks),
        ),
        ...wasteDetail(blocks, 0.05, QuantityUnit.blocks),
        ResultDetail(
          'Floor and cover slabs, '
          '${formatNumber(slabLength)} × ${formatNumber(slabWidth)} × '
          '${formatNumber(septicSlabThickness)} m',
          formatVolume(roundUp(concrete, 3)),
        ),
        ResultDetail('Plaster, inside faces', formatArea(roundUp(plaster))),
      ],
      companions: [
        buy(
          'cement_40kg',
          concrete * mix.cement +
              wallArea * mortar.cement +
              plaster * plasterCement,
        ),
        buy(
          'sand',
          concrete * mix.sand + wallArea * mortar.sand + plaster * plasterSand,
        ),
        buy('gravel', concrete * mix.gravel),
        buy(rebarKey(10), (slabBars + wallBars).toDouble()),
        buy('tie_wire', ties * tieWirePerTie(10) / tieWireMetresPerKg),
      ],
      note:
          'Leave two manholes of at least 0.50 m in the cover slab, one over '
          'each chamber. Keep the tank at least 15 m from any well and '
          'outside the house.',
      works: [WorkQuantity(Work.septicChb, volume)],
    );
  },
  definitions: const [
    InfoSection(
      'Septic tank',
      'A watertight tank where sewage settles and breaks down before the '
          'liquid flows out to a leaching field or drain. The National '
          'Plumbing Code requires two chambers: the inlet chamber holds at '
          'least two thirds of the capacity.',
    ),
    InfoSection(
      'Size',
      'The plumbing code sizes a house by bedrooms: 2,838 L for 1 or 2 '
          'bedrooms (NPC Table B-2). Larger sizes follow the US plumbing code '
          'table the NPC is based on: 3,785 L for 3, 4,542 L for 4, 5,678 L '
          'for 5 or 6, and 568 L more for each extra bedroom; confirm them '
          'with your sanitary engineer. A large household is sized at 0.15 m³ '
          'per person if that is more.',
    ),
    InfoSection(
      'Polyethylene tank',
      'A ready-made two-chamber plastic tank, assumed here to hold 2,000 L. '
          'Several tanks are joined in a row when one is not enough.',
    ),
    InfoSection(
      'Block tank',
      'Walls of 6" hollow blocks, plastered inside, on a 0.10 m concrete '
          'floor and under a 0.10 m concrete cover, both reinforced with '
          '10 mm bars at 0.20 m each way. The liquid is 1.2 m deep with '
          '0.3 m of air above it; the NPC minimum inside size is '
          '1.5 × 0.9 m.',
    ),
  ],
  solution: const [
    InfoSection(
      'Capacity',
      'Take the larger of the bedroom table and 0.15 m³ per person.',
      formula: 'capacity = max(table by bedrooms, people × 0.15 m³)',
    ),
    InfoSection(
      'Polyethylene tanks',
      'Divide by 2 m³ per tank and round up. Cost is tanks × price per '
          'tank.',
      formula: 'tanks = round up(capacity ÷ 2)',
    ),
    InfoSection(
      'Block tank size',
      'With the liquid 1.2 m deep and the length twice the width, round '
          'each side up to 5 cm; the walls are 0.3 m taller than the liquid.',
      formula:
          'width = max(0.9, √(capacity ÷ (2 × 1.2)))\n'
          'length = max(1.5, capacity ÷ (1.2 × width))\n'
          'height = 1.2 + 0.3 = 1.5 m',
    ),
    InfoSection(
      'Blocks',
      'Measure the outer walls on their centre line and add the baffle '
          'across the width. 12.5 blocks per m², plus 5% for breakage. Cost '
          'is blocks × price per block.',
      formula:
          'walls = (2 × (length + width) + 4 × 0.15) × height + width × height\n'
          'blocks = round up(walls × 12.5) + round up(5%)',
    ),
    InfoSection(
      'Concrete',
      'Floor and cover slabs reach the outside of the walls. Class A '
          'concrete (1:2:4) takes 9 bags of cement, 0.5 m³ of sand and 1 m³ '
          'of gravel per m³.',
      formula:
          'slab = (length + 0.3) × (width + 0.3)\n'
          'concrete = 2 × slab × 0.10',
    ),
    InfoSection(
      'Mortar and plaster',
      'Class B mortar for 6" blocks: 1.018 bags of cement and 0.0844 m³ of '
          'sand per m² of wall. Plaster 16 mm thick on the inside faces and '
          'both faces of the baffle: 0.192 bags and 0.016 m³ per m².',
      formula:
          'plaster = 2 × (length + width) × height + 2 × width × height\n'
          'cement = concrete × 9 + walls × 1.018 + plaster × 0.192\n'
          'sand = concrete × 0.5 + walls × 0.0844 + plaster × 0.016',
    ),
    InfoSection(
      'Bars and tie wire',
      'Each slab has 10 mm bars at 0.20 m both ways, cut from 6 m bars. The '
          'walls take 4.28 m of 10 mm bar per m². Each slab crossing takes '
          '0.30 m of tie wire, at 53 m per kg. Cement, sand, gravel, bars '
          'and tie wire are priced from your price book and added to the '
          'total.',
      formula:
          'bars per slab = (round up(side ÷ 0.20) + 1) each way\n'
          'wall bars = round up(walls × 4.28 ÷ 6)\n'
          'tie wire = crossings × 0.30 ÷ 53 kg',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/septic-tank-sizing-philippines-npc/',
    'https://www2.vcrma.org/wp-content/uploads/2024/02/septic-tank-criteria-single-family-dwellings.pdf',
    'https://www.scribd.com/document/542099418/std',
    'https://www.slideshare.net/slideshow/plumbing-1ppt/262234425',
  ],
);
