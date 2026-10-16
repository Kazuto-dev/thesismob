// The electrical service entrance, water heaters and bathroom
// accessories. Sources are listed in docs/calculations.md.

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'fixtures.dart' show teflonJointsPerRoll;
import 'items.dart';
import 'material_spec.dart';
import 'work_items.dart';

/// Keys of the work items these calculators measure.
abstract final class HomeServiceWork {
  static const serviceEntrance = 'service_entrance';
  static const waterHeater = 'water_heater';
  static const bathAccessory = 'bath_accessory';
}

/// Work items these calculators measure. No DPWH item number was
/// confirmed for them; outputs are for small jobs.
const homeServicesWorkItems = <WorkItem>[
  WorkItem(
    HomeServiceWork.serviceEntrance,
    'Service entrance: riser, entrance cap, meter base and service wires',
    'set',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1, helpers: 1),
    output: 1,
  ),
  WorkItem(
    HomeServiceWork.waterHeater,
    'Water heaters, mounted, connected and tested',
    'set',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 2,
  ),
  WorkItem(
    HomeServiceWork.bathAccessory,
    'Bathroom accessories, drilled and mounted',
    'pc',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1),
    output: 8,
  ),
];

// ---------------------------------------------------------------------------
// Price book
// ---------------------------------------------------------------------------

/// Service sizes offered: the main breaker, the THHN/THWN wire that
/// carries it at 75 °C (PEC Table 3.10.2.6(B)(16)) and the riser that
/// holds two of those wires within the 31% fill of PEC Chapter 9, Table 1.
typedef ServiceSize = ({
  String id,
  String label,
  int amps,
  String wire,
  int ampacity,
  String pipe,
  String pipeLabel,
});

const serviceSizes = <ServiceSize>[
  (
    id: '40',
    label: '40 A: 2 × 8.0 mm² in ¾" pipe',
    amps: 40,
    wire: '8.0',
    ampacity: 50,
    pipe: '0_75',
    pipeLabel: '¾" (20 mm)',
  ),
  (
    id: '60',
    label: '60 A: 2 × 14 mm² in ¾" pipe',
    amps: 60,
    wire: '14',
    ampacity: 65,
    pipe: '0_75',
    pipeLabel: '¾" (20 mm)',
  ),
  (
    id: '100',
    label: '100 A: 2 × 30 mm² in 1" pipe',
    amps: 100,
    wire: '30',
    ampacity: 100,
    pipe: '1',
    pipeLabel: '1" (25 mm)',
  ),
];

ServiceSize _serviceSize(String? id) =>
    serviceSizes.firstWhere((s) => s.id == id, orElse: () => serviceSizes[1]);

/// The grounding electrode conductor for services up to 30 mm² (PEC
/// Table 2.50.3.66, which follows NEC Table 250.66).
const groundWire = '8.0';

/// Riser and fitting sizes, with their labels and prices: RSC pipe, IMC
/// pipe, entrance cap, coupling, elbow, locknut and bushing, strap.
const _racewaySizes = {
  '0_75': (
    label: '¾" (20 mm)',
    rsc: 900.0,
    imc: 650.0,
    cap: 250.0,
    coupling: 60.0,
    elbow: 250.0,
    locknut: 45.0,
    strap: 15.0,
  ),
  '1': (
    label: '1" (25 mm)',
    rsc: 1300.0,
    imc: 950.0,
    cap: 320.0,
    coupling: 85.0,
    elbow: 350.0,
    locknut: 60.0,
    strap: 20.0,
  ),
};

String racewayPipeKey(String type, String size) => '${type}_pipe_$size';
String entranceCapKey(String size) => 'entrance_cap_$size';
String conduitCouplingKey(String size) => 'rsc_coupling_$size';
String conduitElbowKey(String size) => 'rsc_elbow_$size';
String locknutKey(String size) => 'locknut_bushing_$size';
String pipeStrapKey(String size) => 'pipe_strap_$size';

/// Water heaters offered.
typedef HeaterType = ({String id, String name, double price});

const heaterTypes = <HeaterType>[
  (
    id: 'single',
    name: 'Water heater, single-point instant, 3.5–4.5 kW',
    price: 5500,
  ),
  (
    id: 'multi',
    name: 'Water heater, multi-point instant, 6–8 kW',
    price: 15000,
  ),
  (id: 'storage_30', name: 'Water heater, storage tank, 30 L', price: 11000),
  (id: 'storage_50', name: 'Water heater, storage tank, 50 L', price: 14000),
];

String heaterKey(String id) => 'water_heater_$id';
String pprFittingKey(String size) => 'ppr_fitting_$size';
String pipeInsulationKey(String size) => 'pipe_insulation_$size';

/// Bathroom accessories offered, with prices by grade: economy, standard,
/// premium.
typedef BathAccessory = ({
  String id,
  String label,
  String name,
  List<double> prices,
});

const bathAccessories = <BathAccessory>[
  (
    id: 'set4',
    label: '4-piece set',
    name: 'Bathroom accessory set: towel bar, paper holder, soap dish, hook',
    prices: [900, 2200, 5500],
  ),
  (
    id: 'towel_bar',
    label: 'Towel bar',
    name: 'Towel bar, 60 cm',
    prices: [350, 800, 2000],
  ),
  (
    id: 'paper_holder',
    label: 'Toilet paper holder',
    name: 'Toilet paper holder',
    prices: [200, 450, 1200],
  ),
  (
    id: 'soap_dish',
    label: 'Soap dish',
    name: 'Soap dish, wall-mounted',
    prices: [150, 400, 1000],
  ),
  (
    id: 'robe_hook',
    label: 'Robe hook',
    name: 'Robe hook',
    prices: [100, 250, 700],
  ),
  (
    id: 'grab_bar',
    label: 'Grab bar',
    name: 'Grab bar, stainless, 60 cm',
    prices: [600, 1200, 3000],
  ),
  (
    id: 'mirror',
    label: 'Mirror',
    name: 'Bathroom mirror, about 50 × 70 cm',
    prices: [700, 1500, 4000],
  ),
  (
    id: 'cabinet',
    label: 'Medicine cabinet with mirror',
    name: 'Medicine cabinet with mirror door',
    prices: [1800, 3500, 8000],
  ),
  (
    id: 'curtain_rod',
    label: 'Shower curtain rod',
    name: 'Shower curtain rod, adjustable',
    prices: [300, 700, 1800],
  ),
];

/// Grades of bathroom accessories, cheapest first.
const bathGrades = [
  ('economy', 'Economy'),
  ('standard', 'Standard'),
  ('premium', 'Premium'),
];

String bathAccessoryKey(String id, String grade) => 'bath_${id}_$grade';

BathAccessory _bathAccessory(String id) =>
    bathAccessories.firstWhere((a) => a.id == id);

Item _pc(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'pc', group, plural: 'pcs', price: price, estimate: true);

Item _set(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'set', group, plural: 'sets', price: price, estimate: true);

/// Price book items these calculators buy. Every price is our estimate of
/// Metro Manila retail for late 2026; see docs/calculations.md.
final List<Item> homeServicesItems = [
  // Service entrance.
  _pc(
    'meter_base',
    'Meter base (socket), 1-phase, from the utility',
    ItemGroup.electrical,
    1500,
  ),
  for (final MapEntry(key: size, value: r) in _racewaySizes.entries) ...[
    Item(
      racewayPipeKey('rsc', size),
      'RSC pipe ${r.label}, 3 m',
      'length',
      ItemGroup.electrical,
      plural: 'lengths',
      price: r.rsc,
      estimate: true,
    ),
    Item(
      racewayPipeKey('imc', size),
      'IMC pipe ${r.label}, 3 m',
      'length',
      ItemGroup.electrical,
      plural: 'lengths',
      price: r.imc,
      estimate: true,
    ),
    _pc(
      entranceCapKey(size),
      'Entrance cap (weatherhead) ${r.label}',
      ItemGroup.electrical,
      r.cap,
    ),
    _pc(
      conduitCouplingKey(size),
      'RSC coupling ${r.label}',
      ItemGroup.electrical,
      r.coupling,
    ),
    _pc(
      conduitElbowKey(size),
      'RSC elbow 90° ${r.label}',
      ItemGroup.electrical,
      r.elbow,
    ),
    _set(
      locknutKey(size),
      'Locknut and bushing ${r.label}',
      ItemGroup.electrical,
      r.locknut,
    ),
    _pc(
      pipeStrapKey(size),
      'Two-hole pipe strap ${r.label}',
      ItemGroup.electrical,
      r.strap,
    ),
  ],
  const Item(
    'utility_connection',
    'Utility service application and bill deposit',
    'lot',
    ItemGroup.other,
    plural: 'lots',
    price: 4000,
    estimate: true,
  ),

  // Water heaters.
  for (final h in heaterTypes)
    _set(heaterKey(h.id), h.name, ItemGroup.fixtures, h.price),
  _pc(
    pprFittingKey('0_5'),
    'PPR fitting ½", elbow, tee, coupling or adapter',
    ItemGroup.plumbing,
    45,
  ),
  _pc(
    pprFittingKey('0_75'),
    'PPR fitting ¾", elbow, tee, coupling or adapter',
    ItemGroup.plumbing,
    70,
  ),
  _pc(
    pipeInsulationKey('0_5'),
    'Pipe insulation, closed-cell foam, for ½" pipe, 2 m',
    ItemGroup.plumbing,
    90,
  ),
  _pc(
    pipeInsulationKey('0_75'),
    'Pipe insulation, closed-cell foam, for ¾" pipe, 2 m',
    ItemGroup.plumbing,
    110,
  ),

  // Bathroom accessories.
  for (final a in bathAccessories)
    for (final (i, (grade, gradeLabel)) in bathGrades.indexed)
      a.id == 'set4'
          ? _set(
              bathAccessoryKey(a.id, grade),
              '${a.name}, ${gradeLabel.toLowerCase()}',
              ItemGroup.fixtures,
              a.prices[i],
            )
          : _pc(
              bathAccessoryKey(a.id, grade),
              '${a.name}, ${gradeLabel.toLowerCase()}',
              ItemGroup.fixtures,
              a.prices[i],
            ),
];

/// The calculators.
final List<MaterialSpec> homeServicesMaterials = [
  serviceEntrance,
  waterHeater,
  bathroomAccessories,
];

// ---------------------------------------------------------------------------
// Service entrance
// ---------------------------------------------------------------------------

/// RSC and IMC pipe come in 3 m lengths, bought with 10% for bends,
/// threading and cuts.
const racewayLength = 3.0;
const racewayAllowance = 0.10;

/// Extra service wire: 1.0 m at the entrance cap for the drip loop and
/// the utility's connection, and 0.5 m to loop through the meter base.
const serviceWireTails = 1.5;

/// Service wire runs along the pipe plus 10% for slack.
const serviceWireAllowance = 0.10;

/// Straps at most 1.5 m apart, one at each end.
const strapSpacing = 1.5;

/// Two elbows (into the meter base and through the wall) and three
/// locknut and bushing sets (meter base in and out, panel board).
const serviceElbows = 2;
const serviceLocknuts = 3;

final serviceEntrance = MaterialSpec(
  id: 'service_entrance',
  name: 'Electrical Service Entrance',
  category: MaterialCategory.electrical,
  icon: Icons.electric_meter_outlined,
  blurb: 'Meter base, riser pipe, service wires and grounding',
  keywords: const [
    'service entrance',
    'metro',
    'kontador',
    'meter base',
    'meter socket',
    'Meralco',
    'entrance cap',
    'weatherhead',
    'RSC',
    'IMC',
    'main breaker',
    'ground rod',
  ],
  numbers: [
    const NumberField(
      id: 'riser',
      label: 'Riser pipe length',
      unit: 'm',
      hint: 'From the entrance cap down to the meter base',
      initial: '3',
      typical: (min: 1, max: 10),
      max: 100,
    ),
    const NumberField(
      id: 'distance',
      label: 'Meter to panel board',
      unit: 'm',
      hint: 'Along the pipe, to the main breaker in the panel board',
      initial: '5',
      typical: (min: 0.5, max: 50),
      max: 1000,
    ),
    const NumberField(
      id: 'ground',
      label: 'Ground wire to the ground rod',
      unit: 'm',
      hint: 'From the panel board to the ground rod',
      initial: '3',
      typical: (min: 1, max: 30),
      max: 1000,
    ),
    priceField('Price per metre of wire'),
  ],
  choices: [
    ChoiceField(
      id: 'main',
      label: 'Main breaker',
      initial: '60',
      helper: 'Sets the service wire and pipe; 60 A suits most small houses',
      options: [
        for (final s in serviceSizes)
          ChoiceOption(s.id, s.label, s.amps.toDouble()),
      ],
    ),
    const ChoiceField(
      id: 'pipe',
      label: 'Riser pipe',
      initial: 'rsc',
      helper: 'Steel pipe, as utilities require for the service entrance',
      options: [
        ChoiceOption('rsc', 'RSC, rigid steel'),
        ChoiceOption('imc', 'IMC, intermediate steel'),
      ],
    ),
    const ChoiceField(
      id: 'groundRod',
      label: 'Ground rod',
      initial: 'rough_in',
      helper: 'The Electrical Rough-in already buys one',
      options: [
        ChoiceOption('rough_in', 'Counted in the Electrical Rough-in'),
        ChoiceOption('here', 'Include it here'),
      ],
    ),
    const ChoiceField(
      id: 'utility',
      label: 'Utility connection and bill deposit',
      initial: 'no',
      helper: 'A lump sum; the utility sets the deposit from your load',
      options: [
        ChoiceOption('no', 'Not included'),
        ChoiceOption('yes', 'Include a lump sum'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(wireMetreKey(_serviceSize(s['main']).wire)),
  compute: (input) {
    final riser = input['riser'];
    final distance = input['distance'];
    final ground = input['ground'];
    final size = _serviceSize(input.choice('main').id);
    final pipeType = input.chose('pipe', 'imc') ? 'imc' : 'rsc';
    final run = riser + distance;
    final perWire = run * (1 + serviceWireAllowance) + serviceWireTails;
    final wire = ceilCount(2 * perWire);
    final pipes = ceilCount(run * (1 + racewayAllowance) / racewayLength);
    final couplings = pipes - 1;
    final straps = ceilCount(run / strapSpacing) + 1;
    final groundMetres = ground * (1 + serviceWireAllowance);
    final p = size.pipe;
    return CalcResult(
      label:
          'Service entrance ${size.amps} A, 2 × ${size.wire} mm² THHN/THWN '
          'in ${pipeType.toUpperCase()} ${size.pipeLabel}',
      quantity: wire.toDouble(),
      unit: QuantityUnit.metres,
      unitPrice: input['price'],
      itemKey: wireMetreKey(size.wire),
      details: [
        ResultDetail('${size.wire} mm² at 75 °C carries', '${size.ampacity} A'),
        ResultDetail('Pipe run, riser + meter to panel', formatLength(run)),
        ResultDetail(
          'Each wire: run + 10% + 1.5 m at the cap and meter',
          formatLength(roundUp(perWire)),
        ),
        ResultDetail('Two wires', formatLength(wire.toDouble())),
        ResultDetail(
          '${pipeType.toUpperCase()} ${size.pipeLabel}, 3 m, + 10%',
          formatCount(pipes, 'length'),
        ),
        ResultDetail(
          'Ground wire $groundWire mm², + 10%',
          formatLength(roundUp(groundMetres)),
        ),
      ],
      companions: [
        buy('meter_base', 1),
        buy(racewayPipeKey(pipeType, p), pipes.toDouble()),
        buy(entranceCapKey(p), 1),
        if (couplings > 0) buy(conduitCouplingKey(p), couplings.toDouble()),
        buy(conduitElbowKey(p), serviceElbows.toDouble()),
        buy(locknutKey(p), serviceLocknuts.toDouble()),
        buy(pipeStrapKey(p), straps.toDouble()),
        buy(
          wireMetreKey(groundWire),
          groundMetres,
          label: 'THHN wire $groundWire mm², green, ground wire',
        ),
        if (input.chose('groundRod', 'here')) buy('ground_rod', 1),
        buy('electrical_tape', 1),
        if (input.chose('utility', 'yes')) buy('utility_connection', 1),
      ],
      note:
          'Build it to the utility\'s service entrance drawing: Meralco '
          'issues the meter base and inspects the work before it connects '
          'the meter. Long runs may need a larger wire for voltage drop.',
      works: const [WorkQuantity(HomeServiceWork.serviceEntrance, 1)],
    );
  },
  definitions: const [
    InfoSection(
      'Service entrance',
      'Where the utility\'s wires reach the house: an entrance cap on top '
          'of a steel riser pipe, the meter base below it, and the service '
          'wires from the cap through the meter to the main breaker in the '
          'panel board. The Electrical Rough-in calculator covers everything '
          'after the main breaker.',
    ),
    InfoSection(
      'Main breaker and wire size',
      'The service wires must carry the main breaker\'s rating. In the '
          'PEC ampacity table, THHN/THWN copper at 75 °C carries 50 A on '
          '8.0 mm², 65 A on 14 mm² and 100 A on 30 mm². Some designers use '
          '22 mm² for 100 A under the 83% rule for dwellings, which the code '
          'writes for 120/240 V three-wire services; the app keeps 30 mm².',
    ),
    InfoSection(
      'Riser pipe',
      'RSC (rigid steel conduit) or the lighter IMC, threaded and joined '
          'with couplings, strapped to the wall at most 1.5 m apart. Two '
          '8.0 or 14 mm² wires fit a ¾" pipe and two 30 mm² wires a 1" pipe '
          'within the 31% fill the code allows for two wires.',
    ),
    InfoSection(
      'Grounding',
      'A green 8.0 mm² wire runs from the panel board to a copper-clad '
          'ground rod, the size the code asks for services up to 30 mm². '
          'The Electrical Rough-in already buys one ground rod with its '
          'clamp, so it is left out here unless you choose to include it.',
    ),
    InfoSection(
      'Utility connection',
      'Meralco asks for a bill deposit of about one month\'s estimated bill, '
          'set from the load you apply for, and issues the meter base. The '
          'lump sum is our estimate for a small house; your utility will '
          'tell you the real amount.',
    ),
  ],
  solution: const [
    InfoSection(
      'Service wire',
      'Two wires, each along the riser and the run to the panel board plus '
          '10%, with 1.5 m more for the drip loop at the entrance cap and '
          'the loop through the meter base. Bought by the metre.',
      formula:
          'run = riser + meter to panel\n'
          'wire = round up(2 × (run × 1.10 + 1.5))',
    ),
    InfoSection(
      'Cost',
      'Multiply the wire by the price per metre.',
      formula: 'cost = wire × price per metre',
    ),
    InfoSection(
      'Pipe and fittings',
      'Pipe along the run plus 10%, in 3 m lengths, with a coupling at each '
          'joint, two elbows, three locknut and bushing sets, an entrance '
          'cap and a strap every 1.5 m plus one.',
      formula:
          'lengths = round up(run × 1.10 ÷ 3)\n'
          'couplings = lengths − 1\n'
          'straps = round up(run ÷ 1.5) + 1',
    ),
    InfoSection(
      'Ground, meter and lump sum',
      'The ground wire plus 10%, the meter base, a roll of electrical tape, '
          'and the ground rod and utility lump sum when chosen. All are '
          'priced from your price book and added to the total.',
      formula: 'ground wire = round up(ground × 1.10)',
    ),
  ],
  references: const [
    'https://filipinoengineer.com/blog/2026/04/pec-2017-motors-motor-circuits-controllers-for-a-single-motor.html',
    'https://www.lapptannehill.com/resources/technical-information/ampacity-chart',
    'https://www.ecmweb.com/national-electrical-code/qa/article/20902669/stumped-by-the-code-rule-for-sizing-service-conductors-for-dwellings',
    'https://iaeimagazine.org/electrical-fundamentals/sizing-of-conductors-related-to-grounding-bonding/',
    'https://company.meralco.com.ph/faq-about/start-or-modify-service',
  ],
);

// ---------------------------------------------------------------------------
// Water heaters
// ---------------------------------------------------------------------------

/// PPR pipe comes in 4 m lengths, bought with 10% for cuts.
const pprLength = 4.0;
const hotPipeAllowance = 0.10;

/// About one PPR fitting every 2 m of run, plus two threaded adapters per
/// heater.
const pprFittingSpacing = 2.0;
const pprAdaptersPerHeater = 2;

/// Foam insulation comes in 2 m lengths, bought with 5% waste.
const insulationLength = 2.0;
const insulationWaste = 0.05;

/// Wall plugs with screws to hang each heater.
const heaterPlugs = 4;

bool _storage(Map<String, String> s) => s['type'] == 'storage';

String _heaterId(Map<String, String> s) => switch (s['type']) {
  'multi' => 'multi',
  'storage' => s['tank'] == '50' ? 'storage_50' : 'storage_30',
  _ => 'single',
};

final waterHeater = MaterialSpec(
  id: 'water_heater',
  name: 'Water Heater',
  category: MaterialCategory.plumbing,
  icon: Icons.hot_tub_outlined,
  blurb: 'Instant or storage heaters, with PPR hot-water pipe',
  keywords: const [
    'water heater',
    'heater',
    'pampainit ng tubig',
    'mainit na tubig',
    'hot water',
    'shower heater',
    'PPR',
    'PN20',
  ],
  numbers: [
    const NumberField(
      id: 'quantity',
      label: 'Number of heaters',
      unit: 'pcs',
      integer: true,
      max: 100,
    ),
    const NumberField(
      id: 'run',
      label: 'Hot water pipe run',
      unit: 'm',
      hint: 'Optional. From the heaters to the hot-water outlets',
      optional: true,
      typical: (min: 1, max: 100),
      max: 10000,
    ),
    priceField('Price per heater'),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Heater',
      initial: 'single',
      leading: true,
      options: [
        ChoiceOption('single', 'Single-point instant, at one shower'),
        ChoiceOption('multi', 'Multi-point instant, for a bathroom'),
        ChoiceOption('storage', 'Storage tank'),
      ],
    ),
    const ChoiceField(
      id: 'tank',
      label: 'Tank size',
      initial: '30',
      visibleWhen: _storage,
      options: [ChoiceOption('30', '30 L'), ChoiceOption('50', '50 L')],
    ),
    ChoiceField(
      id: 'diameter',
      label: 'PPR pipe, PN20',
      initial: '0_5',
      helper: 'Used when you enter a pipe run',
      options: [
        for (final (id, label) in pipeSizes)
          if (id == '0_5' || id == '0_75') ChoiceOption(id, label),
      ],
    ),
    const ChoiceField(
      id: 'insulation',
      label: 'Pipe insulation',
      initial: 'no',
      options: [
        ChoiceOption('no', 'None'),
        ChoiceOption('yes', 'Foam sleeves'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(heaterKey(_heaterId(s))),
  compute: (input) {
    final count = input['quantity'].round();
    final run = input.optional('run');
    final selected = {for (final e in input.choices.entries) e.key: e.value.id};
    final id = _heaterId(selected);
    final single = id == 'single';
    final size = input.choice('diameter');
    final hoses = single ? 1 : 2;
    final joints = single ? 3 : 4;
    final pipes = ceilCount(run * (1 + hotPipeAllowance) / pprLength);
    final fittings = run > 0
        ? ceilCount(run / pprFittingSpacing) + pprAdaptersPerHeater * count
        : 0;
    final sleeves = input.chose('insulation', 'yes')
        ? ceilCount(run * (1 + insulationWaste) / insulationLength)
        : 0;
    const piping = Work.piping;
    return CalcResult(
      label: heaterTypes.firstWhere((h) => h.id == id).name,
      quantity: count.toDouble(),
      unit: QuantityUnit.sets,
      unitPrice: input['price'],
      itemKey: heaterKey(id),
      details: [
        ResultDetail('Heaters', formatCount(count, 'heater')),
        ResultDetail(
          'Angle valve and ${hoses == 1 ? 'a hose' : '2 hoses'} each',
          formatCount(count * hoses, 'hose'),
        ),
        if (run > 0) ...[
          ResultDetail('Hot water pipe run', formatLength(run)),
          ResultDetail('PPR pipes of 4 m, + 10%', formatCount(pipes, 'pipe')),
          ResultDetail(
            'Fittings: 1 per 2 m + 2 adapters per heater',
            formatCount(fittings, 'fitting'),
          ),
        ],
      ],
      companions: [
        buy('angle_valve', count.toDouble()),
        buy('flexible_hose', (count * hoses).toDouble()),
        buy('wall_plug', (count * heaterPlugs).toDouble()),
        buy('teflon_tape', count * joints / teflonJointsPerRoll),
        if (run > 0) ...[
          buy(pprKey(size.id), pipes.toDouble(), work: piping),
          buy(pprFittingKey(size.id), fittings.toDouble(), work: piping),
          if (sleeves > 0)
            buy(pipeInsulationKey(size.id), sleeves.toDouble(), work: piping),
        ],
      ],
      note:
          'Each heater needs its own circuit with an earth-leakage breaker: '
          'add it in the Electrical Rough-in. Storage tanks need a pressure '
          'relief valve, which usually comes with the tank.',
      works: [
        WorkQuantity(HomeServiceWork.waterHeater, count.toDouble()),
        if (run > 0) WorkQuantity(piping, run),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Water heaters',
      'A single-point instant heater warms the water for one shower as it '
          'flows. A multi-point instant heater, larger, feeds a whole '
          'bathroom. A storage heater keeps a tank of hot water, 30 or 50 L, '
          'for several outlets and a kitchen.',
    ),
    InfoSection(
      'Hot water pipe',
      'PPR pipe rated PN20 for hot water, joined by heat fusion, from the '
          'heater to each hot outlet. Heaters fixed at the shower need none. '
          'Foam sleeves keep the heat in long runs.',
    ),
    InfoSection(
      'Dedicated circuit',
      'Every heater needs its own circuit from the panel board, protected '
          'by an earth-leakage breaker, sized at 125% of its current. A '
          '3.5 kW heater draws about 15 A at 230 V and takes a 20 A circuit '
          'on 3.5 mm² wire; a 4.5 kW heater a 30 A circuit on 5.5 mm²; a '
          '6–8 kW multi-point heater 40 A on 8.0 mm². A 1.5–2.5 kW storage '
          'tank takes 20 A. Add it as an appliance circuit in the Electrical '
          'Rough-in and have the electrician confirm its size.',
    ),
    InfoSection(
      'Connections',
      'Each heater gets an angle valve on its cold supply and a braided '
          'hose for each connection: one for a single-point heater, two for '
          'the others. Threaded joints are sealed with teflon tape.',
    ),
  ],
  solution: const [
    InfoSection(
      'Cost',
      'Multiply the heaters by the price per heater.',
      formula: 'cost = heaters × price per heater',
    ),
    InfoSection(
      'Connections',
      'One angle valve, one or two flexible hoses and four wall plugs per '
          'heater; 3 threaded joints for a single-point heater and 4 for the '
          'others, with a roll of teflon tape for 40.',
      formula: 'teflon = round up(heaters × joints ÷ 40)',
    ),
    InfoSection(
      'Pipe and fittings',
      'For the run entered: PPR pipe plus 10% in 4 m lengths, a fitting '
          'every 2 m and two threaded adapters per heater, and foam sleeves '
          'in 2 m lengths plus 5% when chosen. All of these are priced from '
          'your price book and added to the total.',
      formula:
          'pipes = round up(run × 1.10 ÷ 4)\n'
          'fittings = round up(run ÷ 2) + 2 × heaters\n'
          'sleeves = round up(run × 1.05 ÷ 2)',
    ),
  ],
  references: const [
    'https://productnation.co/ph/appliances/small/27543/best-water-heater-philippines',
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
    'https://www.neltex.com/products.do?item_id=51663',
  ],
);

// ---------------------------------------------------------------------------
// Bathroom accessories
// ---------------------------------------------------------------------------

/// The 4-piece set: towel bar, toilet paper holder, soap dish and robe
/// hook.
const setPieces = 4;

bool _byBathroom(Map<String, String> s) => s['by'] != 'piece';
bool _byPiece(Map<String, String> s) => s['by'] == 'piece';

String _grade(Map<String, String> s) =>
    bathGrades.any((g) => g.$1 == s['grade']) ? s['grade']! : 'standard';

final bathroomAccessories = MaterialSpec(
  id: 'bath_accessories',
  name: 'Bathroom Accessories',
  category: MaterialCategory.plumbing,
  icon: Icons.soap_outlined,
  blurb: 'Towel bars, holders, grab bars, mirrors and curtain rods',
  keywords: const [
    'bathroom accessories',
    'toilet accessories',
    'towel bar',
    'sabitan ng tuwalya',
    'tissue holder',
    'lalagyan ng sabon',
    'soap dish',
    'grab bar',
    'hawakan',
    'salamin',
    'mirror',
    'medicine cabinet',
    'shower curtain',
    'banyo',
    'CR',
  ],
  numbers: [
    NumberField(
      id: 'bathrooms',
      label: 'Number of bathrooms',
      unit: 'pcs',
      integer: true,
      max: 100,
      visibleWhen: _byBathroom,
    ),
    NumberField(
      id: 'quantity',
      label: 'Number of pieces',
      unit: 'pcs',
      integer: true,
      max: 10000,
      visibleWhen: _byPiece,
    ),
    priceField('Price per set', visibleWhen: _byBathroom),
    priceField('Price per piece', id: 'pricePiece', visibleWhen: _byPiece),
  ],
  choices: [
    const ChoiceField(
      id: 'by',
      label: 'Count by',
      initial: 'bathroom',
      leading: true,
      options: [
        ChoiceOption('bathroom', 'Bathroom'),
        ChoiceOption('piece', 'Piece, one kind'),
      ],
    ),
    ChoiceField(
      id: 'grade',
      label: 'Grade',
      initial: 'standard',
      helper:
          'Economy is plated zinc or plastic; standard chrome-plated brass '
          'or stainless; premium SUS 304 or solid brass',
      options: [for (final (id, label) in bathGrades) ChoiceOption(id, label)],
    ),
    ChoiceField(
      id: 'accessory',
      label: 'Accessory',
      initial: 'towel_bar',
      visibleWhen: _byPiece,
      options: [
        for (final a in bathAccessories)
          if (a.id != 'set4') ChoiceOption(a.id, a.label),
      ],
    ),
    const ChoiceField(
      id: 'mirror',
      label: 'Mirror',
      initial: 'mirror',
      visibleWhen: _byBathroom,
      options: [
        ChoiceOption('mirror', 'Mirror', 1),
        ChoiceOption('cabinet', 'Medicine cabinet with mirror', 1),
        ChoiceOption('none', 'None', 0),
      ],
    ),
    const ChoiceField(
      id: 'grabBars',
      label: 'Grab bars per bathroom',
      initial: '0',
      helper: 'Beside the toilet and in the shower, for older people',
      visibleWhen: _byBathroom,
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('1', '1', 1),
        ChoiceOption('2', '2', 2),
      ],
    ),
    const ChoiceField(
      id: 'curtain',
      label: 'Shower curtain rod',
      initial: 'no',
      visibleWhen: _byBathroom,
      options: [ChoiceOption('no', 'No', 0), ChoiceOption('yes', 'Yes', 1)],
    ),
  ],
  priceRef: (s) => PriceRef(
    _byPiece(s)
        ? bathAccessoryKey(
            bathAccessories.any((a) => a.id == s['accessory'])
                ? s['accessory']!
                : 'towel_bar',
            _grade(s),
          )
        : bathAccessoryKey('set4', _grade(s)),
  ),
  compute: (input) {
    final grade = input.choice('grade');
    const work = HomeServiceWork.bathAccessory;
    if (input.chose('by', 'piece')) {
      final count = input['quantity'].round();
      final a = _bathAccessory(input.choice('accessory').id);
      return CalcResult(
        label: '${a.label}, ${grade.label.toLowerCase()}',
        quantity: count.toDouble(),
        unit: QuantityUnit.pieces,
        unitPrice: input['pricePiece'],
        itemKey: bathAccessoryKey(a.id, grade.id),
        details: [ResultDetail(a.label, formatCount(count, 'piece'))],
        works: [WorkQuantity(work, count.toDouble())],
      );
    }
    final bathrooms = input['bathrooms'].round();
    final mirror = input.choice('mirror');
    final grabs = input.choice('grabBars').value.round();
    final rods = input.choice('curtain').value.round();
    final perBathroom = setPieces + mirror.value.round() + grabs + rods;
    final pieces = bathrooms * perBathroom;
    return CalcResult(
      label: 'Bathroom accessories, ${grade.label.toLowerCase()}',
      quantity: bathrooms.toDouble(),
      unit: QuantityUnit.sets,
      unitPrice: input['price'],
      itemKey: bathAccessoryKey('set4', grade.id),
      details: [
        ResultDetail(
          '4-piece sets, one per bathroom',
          formatCount(bathrooms, 'set'),
        ),
        ResultDetail('Pieces per bathroom', '$perBathroom'),
        ResultDetail('Pieces to mount', formatCount(pieces, 'piece')),
      ],
      companions: [
        if (mirror.id != 'none')
          buy(bathAccessoryKey(mirror.id, grade.id), bathrooms.toDouble()),
        if (grabs > 0)
          buy(
            bathAccessoryKey('grab_bar', grade.id),
            (bathrooms * grabs).toDouble(),
          ),
        if (rods > 0)
          buy(bathAccessoryKey('curtain_rod', grade.id), bathrooms.toDouble()),
      ],
      note:
          'Accessories come with their screws and wall plugs. Mount grab '
          'bars into solid wall, never into tile alone.',
      works: [WorkQuantity(work, pieces.toDouble())],
    );
  },
  definitions: const [
    InfoSection(
      'Bathroom accessories',
      'The fittings mounted on a bathroom wall: a towel bar, a toilet paper '
          'holder, a soap dish, a robe hook, a mirror or medicine cabinet, '
          'grab bars and a shower curtain rod.',
    ),
    InfoSection(
      'Per bathroom',
      'Each bathroom gets a 4-piece set (towel bar, toilet paper holder, '
          'soap dish and robe hook), plus the mirror or medicine cabinet, '
          'grab bars and curtain rod you choose. To price other pieces, count '
          'them by the piece.',
    ),
    InfoSection(
      'Grades',
      'Economy pieces are plastic or chrome-plated zinc; standard ones '
          'chrome-plated brass or stainless steel; premium ones SUS 304 '
          'stainless or solid brass with a better finish. The grade sets the '
          'price book items used.',
    ),
    InfoSection(
      'Grab bars',
      'Stainless bars beside the toilet and in the shower that older people '
          'and anyone unsteady can hold. They must be anchored into solid '
          'wall.',
    ),
  ],
  solution: const [
    InfoSection(
      'Per bathroom',
      'One set per bathroom; mirrors or cabinets, grab bars and curtain '
          'rods as chosen, at the same grade.',
      formula:
          'sets = bathrooms\n'
          'pieces = bathrooms × (4 + mirror + grab bars + rod)',
    ),
    InfoSection(
      'Cost',
      'Multiply the sets by the price per set, or the pieces by the price '
          'per piece. Mirrors, grab bars and rods are priced from your price '
          'book and added to the total.',
      formula: 'cost = sets × price per set + other pieces',
    ),
  ],
  references: const [
    'https://www.wilcon.com.ph/',
    'https://www.handyman.com.ph/',
  ],
);
