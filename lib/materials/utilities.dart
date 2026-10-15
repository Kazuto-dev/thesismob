// Drainage, water pumps, auxiliary electrical systems and lighting fixtures.
// Sources are listed in docs/calculations.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'fixtures.dart' show jointsPer100cc, jointsPerMetre, teflonJointsPerRoll;
import 'items.dart';
import 'material_spec.dart';
import 'services.dart' show conduitAllowance, conduitLength;
import 'work_items.dart';

/// Keys of the work items these calculators measure.
abstract final class UtilityWork {
  static const catchBasin = 'catch_basin';
  static const pumpInstall = 'pump_install';
  static const auxPoint = 'aux_point';
  static const cctvCamera = 'cctv_camera';
}

/// Work items these calculators measure.
const utilitiesWorkItems = <WorkItem>[
  WorkItem(
    UtilityWork.catchBasin,
    'Catch basin with grating, built or set in place',
    'set',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1, helpers: 1),
    output: 1,
    reference: '502',
  ),
  WorkItem(
    UtilityWork.pumpInstall,
    'Water pump set with valves, installed and tested',
    'set',
    trade: MaterialCategory.plumbing,
    crew: Crew(skilled: 1, helpers: 1),
    output: 1,
  ),
  WorkItem(
    UtilityWork.auxPoint,
    'Data, TV or doorbell point, cabled and terminated',
    'pt',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 8,
  ),
  WorkItem(
    UtilityWork.cctvCamera,
    'CCTV camera, mounted, cabled and set up',
    'set',
    trade: MaterialCategory.electrical,
    crew: Crew(skilled: 1, helpers: 1),
    output: 4,
  ),
];

// ---------------------------------------------------------------------------
// Price book
// ---------------------------------------------------------------------------

/// Drain pipe diameters, in inches.
const drainSizes = ['2', '3', '4', '6'];

/// Series 1000 sanitary pipe, 3 m, by diameter.
String s1000PipeKey(String size) => 'pvc_s1000_$size';

const _s1000Prices = {'2': 330.0, '3': 520.0, '4': 720.0, '6': 1600.0};

/// Pump sizes offered, with the pressure tank and breaker each one takes.
typedef PumpSize = ({String id, String label, int tank, int breaker});

const pumpSizes = <PumpSize>[
  (id: '0_5', label: '½ HP', tank: 24, breaker: 15),
  (id: '1', label: '1 HP', tank: 60, breaker: 20),
  (id: '1_5', label: '1½ HP', tank: 100, breaker: 20),
];

String pumpKey(String type, String size) => '${type}_pump_${size}hp';
String pressureTankKey(int litres) => 'pressure_tank_$litres';

const _jetPumpPrices = {'0_5': 4500.0, '1': 7500.0, '1_5': 11500.0};
const _boosterPumpPrices = {'0_5': 12000.0, '1': 20000.0, '1_5': 28000.0};
const _tankPrices = {24: 2200.0, 60: 4800.0, 100: 8000.0};

/// CCTV recorder sizes, in channels.
const recorderChannels = [4, 8, 16];

/// Surveillance hard disk for each recorder size, in TB.
const recorderDiskTb = {4: 1, 8: 2, 16: 4};

String dvrKey(int channels) => 'dvr_$channels';
String nvrKey(int channels) => 'nvr_$channels';
String poeSwitchKey(int ports) => 'poe_switch_$ports';
String hardDiskKey(int tb) => 'hdd_${tb}tb';

const _dvrPrices = {4: 3200.0, 8: 5200.0, 16: 9500.0};
const _nvrPrices = {4: 3800.0, 8: 5800.0, 16: 10500.0};
const _poePrices = {4: 2500.0, 8: 4500.0, 16: 10000.0};
const _diskPrices = {1: 3300.0, 2: 4800.0, 4: 7800.0};

/// An LED fixture type: its price book key, wattage and rated lumens.
typedef LedFixture = ({
  String id,
  String label,
  String name,
  int watts,
  double lumens,
  double price,
});

const ledFixtures = <LedFixture>[
  (
    id: 'downlight_4',
    label: '4" downlight, 9 W, 750 lm',
    name: 'LED downlight 4", 9 W',
    watts: 9,
    lumens: 750,
    price: 280,
  ),
  (
    id: 'downlight_6',
    label: '6" downlight, 12 W, 1,000 lm',
    name: 'LED downlight 6", 12 W',
    watts: 12,
    lumens: 1000,
    price: 420,
  ),
  (
    id: 'pin_light',
    label: 'Pin light, 5 W, 400 lm',
    name: 'LED pin light, 5 W',
    watts: 5,
    lumens: 400,
    price: 180,
  ),
  (
    id: 'ceiling_lamp',
    label: 'Surface ceiling lamp, 24 W, 2,000 lm',
    name: 'LED ceiling lamp, surface, 24 W',
    watts: 24,
    lumens: 2000,
    price: 950,
  ),
  (
    id: 'batten',
    label: 'T8 batten, 18 W, 1,800 lm',
    name: 'LED T8 batten, 4 ft, 18 W',
    watts: 18,
    lumens: 1800,
    price: 480,
  ),
];

String ledFixtureKey(String id) => 'led_$id';

LedFixture _ledFixture(String? id) =>
    ledFixtures.firstWhere((f) => f.id == id, orElse: () => ledFixtures.first);

Item _pc(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'pc', group, plural: 'pcs', price: price, estimate: true);

Item _set(String key, String name, ItemGroup group, double price) =>
    Item(key, name, 'set', group, plural: 'sets', price: price, estimate: true);

Item _box(String key, String name, double price) => Item(
  key,
  name,
  'box',
  ItemGroup.electrical,
  plural: 'boxes',
  price: price,
  estimate: true,
);

Item _metre(String key, String name, double price) =>
    Item(key, name, 'm', ItemGroup.electrical, price: price, estimate: true);

/// Price book items these calculators buy. Every price is our estimate of
/// Metro Manila retail for late 2026; see the docs for what it rests on.
final List<Item> utilitiesItems = [
  // Drainage.
  _pc(
    pipeKey('6'),
    'PVC sanitary pipe (orange) 6", 3 m',
    ItemGroup.plumbing,
    1000,
  ),
  for (final size in drainSizes)
    _pc(
      s1000PipeKey(size),
      'PVC sanitary pipe Series 1000 $size", 3 m',
      ItemGroup.plumbing,
      _s1000Prices[size]!,
    ),
  _pc(
    'grating_cast_iron',
    'Catch basin grating, cast iron, with frame, 0.50 × 0.50 m',
    ItemGroup.plumbing,
    3500,
  ),
  _pc(
    'grating_steel',
    'Catch basin grating, steel bars on angle frame, 0.50 × 0.50 m',
    ItemGroup.plumbing,
    2000,
  ),
  _pc(
    'catch_basin_box',
    'Catch basin box with grating, precast or PVC',
    ItemGroup.plumbing,
    2500,
  ),

  // Water pumps.
  for (final s in pumpSizes)
    _set(
      pumpKey('jet', s.id),
      'Jet pump, shallow well, ${s.label}',
      ItemGroup.plumbing,
      _jetPumpPrices[s.id]!,
    ),
  for (final s in pumpSizes)
    _set(
      pumpKey('booster', s.id),
      'Booster pump with built-in pressure controller, ${s.label}',
      ItemGroup.plumbing,
      _boosterPumpPrices[s.id]!,
    ),
  for (final s in pumpSizes)
    _pc(
      pressureTankKey(s.tank),
      'Pressure tank, diaphragm, ${s.tank} L',
      ItemGroup.plumbing,
      _tankPrices[s.tank]!,
    ),
  _pc(
    'pressure_switch',
    'Pressure switch, 1.4–2.8 bar',
    ItemGroup.plumbing,
    750,
  ),
  _pc('pressure_gauge', 'Pressure gauge, 0–10 bar', ItemGroup.plumbing, 350),
  _pc(
    'tank_connector',
    'Five-way tank connector, 1", brass',
    ItemGroup.plumbing,
    450,
  ),
  _pc('check_valve_1', 'Check valve 1", brass', ItemGroup.plumbing, 600),
  _pc('gate_valve_1', 'Gate valve 1", brass', ItemGroup.plumbing, 700),
  _pc('union_1', 'Union 1", PVC, threaded', ItemGroup.plumbing, 95),
  _pc(
    'pump_hose_1',
    'Flexible hose 1", braided, for pumps',
    ItemGroup.plumbing,
    450,
  ),
  _set(
    'pump_base',
    'Pump base: concrete pad with anchor bolts',
    ItemGroup.plumbing,
    600,
  ),

  // Data, TV and CCTV.
  _box('cat6_box', 'CAT6 UTP cable, copper, box of 305 m', 7500),
  _metre('cat6_m', 'CAT6 UTP cable, cut', 30),
  _box('rg6_box', 'RG6 coaxial cable, box of 305 m', 4500),
  _metre('rg6_m', 'RG6 coaxial cable, cut', 20),
  _box('rg59_box', 'CCTV cable, RG59 with power wires, box of 305 m', 3800),
  _metre('rg59_m', 'CCTV cable, RG59 with power wires, cut', 18),
  _pc('keystone_cat6', 'Keystone jack, CAT6', ItemGroup.electrical, 120),
  _pc('keystone_f', 'Keystone jack, F-type (TV)', ItemGroup.electrical, 80),
  _pc(
    'faceplate_keystone',
    'Faceplate for 1 keystone jack',
    ItemGroup.electrical,
    80,
  ),
  _pc('rj45_plug', 'RJ45 plug, CAT6', ItemGroup.electrical, 15),
  _pc('f_connector', 'F connector, RG6', ItemGroup.electrical, 20),
  _pc('tv_splitter_4', 'TV splitter, 4-way', ItemGroup.electrical, 280),
  _pc(
    'network_switch_8',
    'Network switch, 8-port gigabit',
    ItemGroup.electrical,
    1600,
  ),
  _pc(
    'cctv_camera_hd',
    'CCTV camera, HD analog, 2 MP',
    ItemGroup.electrical,
    1500,
  ),
  _pc('cctv_camera_ip', 'IP camera, 4 MP, PoE', ItemGroup.electrical, 3200),
  for (final ch in recorderChannels)
    _pc(dvrKey(ch), 'DVR, $ch-channel', ItemGroup.electrical, _dvrPrices[ch]!),
  for (final ch in recorderChannels)
    _pc(nvrKey(ch), 'NVR, $ch-channel', ItemGroup.electrical, _nvrPrices[ch]!),
  for (final tb in {...recorderDiskTb.values})
    _pc(
      hardDiskKey(tb),
      'Surveillance hard disk, $tb TB',
      ItemGroup.electrical,
      _diskPrices[tb]!,
    ),
  for (final ch in recorderChannels)
    _pc(
      poeSwitchKey(ch),
      'PoE switch, $ch ports',
      ItemGroup.electrical,
      _poePrices[ch]!,
    ),
  _pc(
    'cctv_psu',
    'CCTV power supply 12 V, 5 A, for 4 cameras',
    ItemGroup.electrical,
    700,
  ),
  _set(
    'cctv_connectors',
    'BNC and DC plugs for one camera',
    ItemGroup.electrical,
    80,
  ),
  _set(
    'doorbell',
    'Doorbell chime with push button',
    ItemGroup.electrical,
    650,
  ),

  // Lighting fixtures.
  for (final f in ledFixtures)
    _pc(ledFixtureKey(f.id), f.name, ItemGroup.electrical, f.price),
  _metre('flex_conduit_m', 'Flexible conduit ½", cut', 22),
];

// ---------------------------------------------------------------------------
// Drainage and catch basins
// ---------------------------------------------------------------------------

/// Drain pipes are sold in 3 m lengths.
const drainPipeLength = 3.0;

/// Extra pipe for cuts and offsets.
const drainPipeAllowance = 0.05;

/// Bends, wyes and sanitary tees on a drain cost about 30% of its pipe:
/// fewer fittings per metre than water supply lines.
const drainFittingsShare = 0.30;

/// Solvent-cemented joints one 100 cc can makes, by drain diameter
/// (Oatey's joints per quart, scaled to 100 cc).
const drainJointsPer100cc = {...jointsPer100cc, '6': 1};

/// Inside size of a block catch basin and the block wall around it.
const basinInside = 0.45;
const basinDepth = 0.60;
const basinWall = 0.10;

/// Class A concrete floor, 0.10 m thick, under the walls.
const basinSlabThickness = 0.10;

/// Block wall of one basin, measured on its centre line: 1.32 m².
const basinWallArea = 4 * (basinInside + basinWall) * basinDepth;

/// Plaster on the four inside faces of one basin: 1.08 m².
const basinPlasterArea = 4 * basinInside * basinDepth;

/// Floor slab of one basin, to the outside of the walls: 0.04225 m³.
const basinSlabVolume =
    (basinInside + 2 * basinWall) *
    (basinInside + 2 * basinWall) *
    basinSlabThickness;

String _drainKey(Map<String, String> s) {
  final size = drainSizes.contains(s['diameter']) ? s['diameter']! : '4';
  return s['class'] == 's1000' ? s1000PipeKey(size) : pipeKey(size);
}

bool _blockBasin(Map<String, String> s) => s['basin'] != 'box';

final drainage = MaterialSpec(
  id: 'drainage',
  name: 'Drainage and Catch Basins',
  category: MaterialCategory.plumbing,
  icon: Icons.waves_outlined,
  blurb: 'Storm and sanitary drain pipes, with catch basins and gratings',
  keywords: const [
    'kanal',
    'imburnal',
    'tubo',
    'drainage',
    'drain',
    'storm drain',
    'sanitary line',
    'sewer',
    'catch basin',
    'grating',
    'rehas',
    'orange pipe',
    'series 1000',
  ],
  numbers: [
    const NumberField(
      id: 'run',
      label: 'Drain pipe run',
      unit: 'm',
      hint: 'Add up every straight length of drain pipe',
      typical: (min: 1, max: 300),
      max: 10000,
    ),
    const NumberField(
      id: 'basins',
      label: 'Catch basins',
      unit: 'pcs',
      hint: 'Optional. Leave empty for a sanitary line with none',
      integer: true,
      optional: true,
      max: 1000,
    ),
    const NumberField(
      id: 'cleanouts',
      label: 'Cleanouts',
      unit: 'pcs',
      hint: 'Optional. At the upper end of each run and about every 15 m',
      integer: true,
      optional: true,
      max: 1000,
    ),
    const NumberField(
      id: 'drains',
      label: 'Floor drains',
      unit: 'pcs',
      hint: 'Optional. Garage, laundry and service area drains',
      integer: true,
      optional: true,
      max: 1000,
    ),
    priceField('Price per pipe'),
  ],
  choices: [
    const ChoiceField(
      id: 'diameter',
      label: 'Diameter',
      initial: '4',
      helper: '2" to 3" for sinks, showers and downspouts; 4" for toilets',
      options: [
        ChoiceOption('2', '2"'),
        ChoiceOption('3', '3"'),
        ChoiceOption('4', '4"'),
        ChoiceOption('6', '6"'),
      ],
    ),
    const ChoiceField(
      id: 'class',
      label: 'Pipe',
      initial: 'orange',
      helper: 'Series 1000 has a thicker wall, for pipes under driveways',
      options: [
        ChoiceOption('orange', 'Orange sanitary pipe, 3 m'),
        ChoiceOption('s1000', 'Series 1000, 3 m'),
      ],
    ),
    const ChoiceField(
      id: 'basin',
      label: 'Catch basin',
      initial: 'chb',
      helper: 'Used when you enter catch basins',
      options: [
        ChoiceOption('chb', 'CHB, 0.45 × 0.45 × 0.60 m inside'),
        ChoiceOption('box', 'Precast or PVC box with grating'),
      ],
    ),
    const ChoiceField(
      id: 'grating',
      label: 'Grating',
      initial: 'cast_iron',
      visibleWhen: _blockBasin,
      options: [
        ChoiceOption('cast_iron', 'Cast iron'),
        ChoiceOption('steel', 'Steel bars on an angle frame'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_drainKey(s)),
  compute: (input) {
    final run = input['run'];
    final diameter = input.choice('diameter');
    final s1000 = input.chose('class', 's1000');
    final basins = input.optional('basins').round();
    final cleanouts = input.optional('cleanouts').round();
    final drains = input.optional('drains').round();
    final needed = run * (1 + drainPipeAllowance);
    final pipes = ceilCount(needed / drainPipeLength);
    final price = input['price'];
    final joints = run * jointsPerMetre;
    final perCan = drainJointsPer100cc[diameter.id]!;

    final block = input.chose('basin', 'chb');
    final wall = basins * basinWallArea;
    final plaster = basins * basinPlasterArea;
    final slab = basins * basinSlabVolume;
    final blocks = withWaste(ceilCount(wall * chbPerSquareMetre), 0.05);
    final mix = concreteMix('A');
    final mortar = chbMortar['4']!;
    final grating = input.chose('grating', 'steel')
        ? 'grating_steel'
        : 'grating_cast_iron';
    const basinWork = UtilityWork.catchBasin;

    return CalcResult(
      label: s1000
          ? 'PVC drain pipe Series 1000 ${diameter.label}'
          : 'PVC drain pipe ${diameter.label}',
      quantity: pipes.toDouble(),
      unit: QuantityUnit.pipes,
      unitPrice: price,
      itemKey: s1000 ? s1000PipeKey(diameter.id) : pipeKey(diameter.id),
      details: [
        ResultDetail('Pipe run', formatLength(run)),
        ResultDetail(
          'With 5% for cuts and offsets',
          formatLength(roundUp(needed, 1)),
        ),
        ResultDetail(
          'Pipes of 3 m',
          formatQuantity(pipes.toDouble(), QuantityUnit.pipes),
        ),
        ResultDetail(
          'Joints, about 1 per metre ($perCan per 100 cc)',
          formatNumber(roundUp(joints, 0)),
        ),
        if (basins > 0 && block) ...[
          ResultDetail(
            'Basin walls, 4" CHB, 1.32 m² each',
            formatArea(roundUp(wall)),
          ),
          ResultDetail(
            'Blocks at 12.5 per m²',
            formatQuantity(blocks.base.toDouble(), QuantityUnit.blocks),
          ),
          ...wasteDetail(blocks, 0.05, QuantityUnit.blocks),
          ResultDetail(
            'Plaster inside, 1.08 m² each',
            formatArea(roundUp(plaster)),
          ),
          ResultDetail(
            'Floor slabs, 0.65 × 0.65 × 0.10 m',
            formatVolume(roundUp(slab, 3)),
          ),
        ],
      ],
      companions: [
        allowance(
          'pvc_fittings',
          drainFittingsShare * pipes * price,
          label: 'Fittings: bends, wyes, sanitary tees (30% of pipe cost)',
        ),
        buy('solvent_cement', joints / perCan),
        if (cleanouts > 0)
          buy(
            'cleanout',
            cleanouts.toDouble(),
            label: 'Cleanout plug, ${diameter.label}',
          ),
        if (drains > 0) buy('floor_drain', drains.toDouble()),
        if (basins > 0 && block) ...[
          buy('chb_4', blocks.total.toDouble(), work: basinWork),
          buy(
            'cement_40kg',
            slab * mix.cement + wall * mortar.cement + plaster * plasterCement,
            label: 'Cement for basin slabs, walls and plaster',
            work: basinWork,
          ),
          buy(
            'sand',
            slab * mix.sand + wall * mortar.sand + plaster * plasterSand,
            work: basinWork,
          ),
          buy('gravel', slab * mix.gravel, work: basinWork),
          buy(grating, basins.toDouble(), work: basinWork),
        ],
        if (basins > 0 && !block)
          buy('catch_basin_box', basins.toDouble(), work: basinWork),
      ],
      note:
          'Lay drains with a fall of at least 2% for 3" and smaller, 1% '
          'for 4" and larger. Trench digging and backfill are not included.',
      works: [
        WorkQuantity(Work.piping, run),
        if (basins > 0) WorkQuantity(basinWork, basins.toDouble()),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Drainage',
      'Storm drains carry rainwater from roofs, yards and driveways to the '
          'street canal; sanitary drains carry waste water to the septic '
          'tank or sewer. Both are usually orange PVC pipe laid in a trench '
          'or under the floor slab.',
    ),
    InfoSection(
      'Diameter',
      'The National Plumbing Code sizes drains by fixture units. In a '
          'house, 2" serves sinks, showers and floor drains, 3" downspouts '
          'and yard drains, 4" toilets and the main line, and 6" a storm '
          'main to the street.',
    ),
    InfoSection(
      'Orange or Series 1000',
      'Orange sanitary pipe suits most house drains. Series 1000 has a '
          'thicker wall for pipes under driveways or deep fill. Both come in '
          '3 m lengths and are joined with solvent cement.',
    ),
    InfoSection(
      'Catch basin',
      'A small pit with a grating that collects rainwater and lets silt '
          'settle before the water enters the pipe. The block type has '
          '4" CHB walls, plastered inside, on a 0.10 m concrete floor, '
          '0.45 × 0.45 m and 0.60 m deep inside, with a cast iron or steel '
          'grating. Precast and PVC boxes come with their own grating.',
    ),
    InfoSection(
      'Cleanouts and floor drains',
      'A cleanout is a plugged opening for rodding a blocked drain, at the '
          'upper end of each run, at sharp turns and about every 15 m. Floor '
          'drains collect water from garages, laundries and service areas.',
    ),
    InfoSection(
      'Fall',
      'Drains slope toward the outlet: at least 2% (2 cm per metre) for 3" '
          'and smaller pipes and 1% for 4" and larger.',
    ),
  ],
  solution: const [
    InfoSection(
      'Pipes',
      'Add 5% to the run for cuts and offsets, divide by 3 m and round up.',
      formula: 'pipes = round up(run × 1.05 ÷ 3)',
    ),
    InfoSection(
      'Cost',
      'Multiply the pipes by the price per pipe.',
      formula: 'cost = pipes × price per pipe',
    ),
    InfoSection(
      'Fittings and solvent cement',
      'Bends, wyes and sanitary tees are an allowance of 30% of the pipe '
          'cost. About one glued joint per metre of run; a 100 cc can makes '
          '6 joints at 2", 4 at 3", 3 at 4" and 1 at 6".',
      formula:
          'fittings = 0.30 × pipes × price per pipe\n'
          'cans = round up(run ÷ joints per can)',
    ),
    InfoSection(
      'Block catch basins',
      'Each basin has 1.32 m² of 4" block wall on its centre line, '
          '1.08 m² of plaster inside and a 0.65 × 0.65 × 0.10 m Class A '
          'floor. 12.5 blocks per m² plus 5%. Mortar for 4" blocks takes '
          '0.522 bags of cement and 0.0435 m³ of sand per m²; plaster 0.192 '
          'bags and 0.016 m³; concrete 9 bags, 0.5 m³ of sand and 1 m³ of '
          'gravel per m³.',
      formula:
          'walls = basins × 4 × 0.55 × 0.60\n'
          'blocks = round up(walls × 12.5) + round up(5%)\n'
          'slab = basins × 0.65 × 0.65 × 0.10\n'
          'cement = slab × 9 + walls × 0.522 + plaster × 0.192\n'
          'sand = slab × 0.5 + walls × 0.0435 + plaster × 0.016',
    ),
    InfoSection(
      'Also needed',
      'A grating per block basin, or a precast or PVC box per basin, plus '
          'the cleanout plugs and floor drains you enter. Everything is '
          'priced from your price book and added to the total.',
      formula: 'gratings = basins',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/',
    'https://www.neltex.com/products.do?item_id=51663',
    'https://mpi.moldex.com.ph/mb-pipes-and-fittings',
    'https://www.commercial-industrial-supply.com/resource-center/how-much-pvc-glue-to-use/',
    'https://dpwh.gov.ph/DPWH/sites/default/files/issuances/do_028_s2025.pdf',
  ],
);

// ---------------------------------------------------------------------------
// Water pump and pressure tank
// ---------------------------------------------------------------------------

/// Pump size step for the bathrooms and storeys: up to 2 bathrooms ½ HP,
/// up to 4 1 HP, more 1½ HP; a third storey moves up one size.
int pumpStep(String? bathrooms, String? storeys) {
  final base = switch (bathrooms) {
    '4' => 1,
    '6' => 2,
    _ => 0,
  };
  return math.min(base + (storeys == '3' ? 1 : 0), pumpSizes.length - 1);
}

/// Threaded joints of a pump set: pump, check valve, two gate valves, two
/// unions and two hoses; a jet pump adds the five-way tank connector, the
/// tank, the pressure switch and the gauge.
const pumpJoints = 16;
const tankJoints = 5;

/// Pump circuit: line, neutral and ground of 3.5 mm² in ½" conduit.
const pumpWire = '3.5';
const pumpConductors = 3;
const pumpWireAllowance = 0.10;

String _pumpType(Map<String, String> s) =>
    s['type'] == 'booster' ? 'booster' : 'jet';

final waterPump = MaterialSpec(
  id: 'water_pump',
  name: 'Water Pump',
  category: MaterialCategory.plumbing,
  icon: Icons.plumbing,
  blurb: 'A booster pump set sized for the house, with tank and valves',
  keywords: const [
    'bomba',
    'bomba ng tubig',
    'water pump',
    'jet pump',
    'booster pump',
    'pressure tank',
    'mahinang tubig',
    'tubig',
    'pressure switch',
  ],
  numbers: [
    const NumberField(
      id: 'distance',
      label: 'Distance from the panel board',
      unit: 'm',
      hint: 'Along the wiring path, for the pump circuit',
      initial: '10',
      typical: (min: 1, max: 60),
      max: 1000,
    ),
    priceField('Price of the pump'),
  ],
  choices: const [
    ChoiceField(
      id: 'type',
      label: 'Pump',
      initial: 'jet',
      helper: 'A booster with a built-in controller needs no pressure tank',
      options: [
        ChoiceOption('jet', 'Jet pump with pressure tank'),
        ChoiceOption('booster', 'Booster pump with built-in controller'),
      ],
    ),
    ChoiceField(
      id: 'bathrooms',
      label: 'Bathrooms',
      initial: '2',
      helper: 'Sets the pump size',
      options: [
        ChoiceOption('2', 'Up to 2 bathrooms'),
        ChoiceOption('4', '3 or 4 bathrooms'),
        ChoiceOption('6', '5 or 6 bathrooms'),
      ],
    ),
    ChoiceField(
      id: 'storeys',
      label: 'Storeys',
      initial: '2',
      helper: 'A third storey needs the next pump size up',
      options: [
        ChoiceOption('1', '1 storey', 1),
        ChoiceOption('2', '2 storeys', 2),
        ChoiceOption('3', '3 storeys', 3),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(
    pumpKey(_pumpType(s), pumpSizes[pumpStep(s['bathrooms'], s['storeys'])].id),
  ),
  compute: (input) {
    final jet = !input.chose('type', 'booster');
    final bathrooms = input.choice('bathrooms');
    final storeys = input.choice('storeys');
    final base = pumpStep(bathrooms.id, '1');
    final step = pumpStep(bathrooms.id, storeys.id);
    final size = pumpSizes[step];
    final distance = input['distance'];
    final wire = distance * pumpConductors * (1 + pumpWireAllowance);
    final joints = pumpJoints + (jet ? tankJoints : 0);
    return CalcResult(
      label: jet
          ? 'Jet pump ${size.label} with ${size.tank} L pressure tank'
          : 'Booster pump ${size.label} with built-in controller',
      quantity: 1,
      unit: QuantityUnit.sets,
      unitPrice: input['price'],
      itemKey: pumpKey(jet ? 'jet' : 'booster', size.id),
      details: [
        ResultDetail(bathrooms.label, pumpSizes[base].label),
        if (step != base) ResultDetail('One size up for 3 storeys', size.label),
        if (jet) ResultDetail('Pressure tank', '${size.tank} L'),
        ResultDetail(
          'Pump circuit, 3.5 mm², 3 wires + 10%',
          formatLength(roundUp(wire, 1)),
        ),
        ResultDetail('Breaker', '${size.breaker} A'),
      ],
      companions: [
        if (jet) ...[
          buy(pressureTankKey(size.tank), 1),
          buy('tank_connector', 1),
          buy('pressure_switch', 1),
          buy('pressure_gauge', 1),
        ],
        buy('check_valve_1', 1),
        buy('gate_valve_1', 2),
        buy('union_1', 2),
        buy('pump_hose_1', 2),
        buy('teflon_tape', joints / teflonJointsPerRoll),
        buy('pump_base', 1),
        buy(wireMetreKey(pumpWire), wire, work: Work.wiring),
        buy(
          'conduit_half',
          distance * (1 + conduitAllowance) / conduitLength,
          work: Work.wiring,
        ),
        buy(breakerKey(size.breaker), 1, work: Work.wiring),
      ],
      note:
          'Pipes to the pump and from it to the house are not included; add '
          'them with the PVC Pipe calculator. Check the pump ports: some '
          '1½ HP pumps take 1¼" pipe.',
      works: [
        const WorkQuantity(UtilityWork.pumpInstall, 1),
        WorkQuantity(Work.wiring, roundUp(wire, 1)),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Booster pump set',
      'A pump that draws from the water tank or the city line and pushes '
          'water to every faucet at a steady pressure, for houses where the '
          'supply is weak or upper floors run dry.',
    ),
    InfoSection(
      'Jet pump or booster',
      'A jet pump runs with a pressure tank and a pressure switch that '
          'starts it when the pressure drops. A booster pump with a built-in '
          'controller senses flow and pressure itself, so it needs no tank, '
          'switch or gauge.',
    ),
    InfoSection(
      'Pump size',
      'Up to 2 bathrooms take a ½ HP pump with a 24 L tank, 3 or 4 '
          'bathrooms 1 HP with 60 L, and 5 or 6 bathrooms 1½ HP with 100 L. '
          'Each storey adds about 3 m of lift, so a 3-storey house moves up '
          'one size. Larger houses need a plumbing engineer.',
    ),
    InfoSection(
      'Valves and fittings',
      'A check valve stops water flowing back. Gate valves on both sides '
          'and unions let the pump be removed without draining the lines; '
          'braided hoses keep its vibration out of the pipes. The pump sits '
          'on a small concrete pad.',
    ),
    InfoSection(
      'Pump circuit',
      'The pump gets its own circuit from the panel board: 3.5 mm² wire with '
          'a ground in ½" conduit, on a 15 A breaker for ½ HP and 20 A for '
          '1 to 1½ HP.',
    ),
  ],
  solution: const [
    InfoSection(
      'Pump and tank',
      'Pick the size from the bathrooms, one size up for 3 storeys, at most '
          '1½ HP. A jet pump gets the pressure tank of its size.',
      formula:
          'up to 2 bathrooms: ½ HP, 24 L\n'
          '3 or 4: 1 HP, 60 L\n'
          '5 or 6: 1½ HP, 100 L',
    ),
    InfoSection(
      'Cost',
      'One pump set at the price of the pump.',
      formula: 'cost = 1 × price of the pump',
    ),
    InfoSection(
      'Valves and fittings',
      'One check valve, two gate valves, two unions, two braided hoses and '
          'a pump base. A jet pump adds a five-way tank connector, a pressure '
          'switch and a gauge. The set has about 16 threaded joints (21 with '
          'a tank), and a roll of teflon tape wraps about 40.',
      formula: 'teflon rolls = round up(joints ÷ 40)',
    ),
    InfoSection(
      'Pump circuit',
      'Three 3.5 mm² wires along the distance from the panel, plus 10%, '
          'in ½" conduit of 3 m lengths plus 10%, and one breaker. All of '
          'these are priced from your price book and added to the total.',
      formula:
          'wire = distance × 3 × 1.10\n'
          'conduit = round up(distance × 1.10 ÷ 3)',
    ),
  ],
  references: const [
    'https://www1.agric.gov.ab.ca/\$Department/deptdocs.nsf/all/agdex15866/\$FILE/716_B01_ws2.pdf',
    'https://khmtools.com.ph/collections/pressure-tank',
    'https://khmtools.com.ph/collections/booster-pump',
    'https://www.shopbuildmate.com/products/powerhouse-water-jet-pump-1hp-with-24l-pressure-tank-set-for-water-transfer-supply-phco-jet24l-tnk',
    'https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits',
  ],
);

// ---------------------------------------------------------------------------
// Auxiliary electrical: data, TV, CCTV and doorbell
// ---------------------------------------------------------------------------

/// Cable is sold in 305 m (1,000 ft) boxes.
const cableBoxLength = 305.0;

/// Extra cable for slack and termination at both ends.
const cableAllowance = 0.10;

/// Below this many metres left over, cable is cut by the metre instead
/// of bought by the box.
const cableBoxMinimum = 200.0;

/// LAN ports on the internet provider's router; more data outlets need a
/// switch, each 8-port switch serving 7 outlets.
const routerLanPorts = 4;
const outletsPerSwitch = 7;

/// TV outlets per 4-way splitter.
const outletsPerSplitter = 4;

/// Cameras per 12 V, 5 A power supply.
const camerasPerSupply = 4;

/// Buys [metres] of cable: whole boxes, and the rest by the metre unless
/// it is at least [cableBoxMinimum], when another box is cheaper.
List<Companion> _buyCable(
  String boxKey,
  String metreKey,
  double metres, {
  String? work,
}) {
  if (metres <= 0) return const [];
  var boxes = (metres / cableBoxLength + 1e-9).floor();
  var rest = metres - boxes * cableBoxLength;
  if (rest >= cableBoxMinimum) {
    boxes++;
    rest = 0;
  }
  return [
    if (boxes > 0) buy(boxKey, boxes.toDouble(), work: work),
    if (rest > 1e-6) buy(metreKey, rest, work: work),
  ];
}

/// Recorders for [cameras]: the smallest of 4, 8 or 16 channels that
/// takes them all, or as many 16-channel recorders as needed.
({int channels, int count}) recordersFor(int cameras) {
  for (final ch in recorderChannels) {
    if (cameras <= ch) return (channels: ch, count: 1);
  }
  return (channels: 16, count: ceilCount(cameras / 16));
}

bool _byBox(Map<String, String> s) => s['buy'] == 'box';

final auxiliary = MaterialSpec(
  id: 'auxiliary',
  name: 'Data, TV and CCTV',
  category: MaterialCategory.electrical,
  icon: Icons.router_outlined,
  blurb: 'Low-voltage cabling for internet, TV, CCTV and a doorbell',
  keywords: const [
    'CCTV',
    'camera',
    'internet',
    'LAN',
    'UTP',
    'CAT6',
    'cable TV',
    'coaxial',
    'doorbell',
    'timbre',
    'kable',
    'auxiliary',
    'low voltage',
  ],
  numbers: [
    const NumberField(
      id: 'data',
      label: 'Data outlets (CAT6)',
      unit: 'pcs',
      hint: 'Wired internet points; count one for the CCTV recorder',
      integer: true,
      max: 1000,
    ),
    const NumberField(
      id: 'tv',
      label: 'TV outlets (coaxial)',
      unit: 'pcs',
      hint: 'Optional',
      integer: true,
      optional: true,
      max: 1000,
    ),
    const NumberField(
      id: 'cameras',
      label: 'CCTV cameras',
      unit: 'pcs',
      hint: 'Optional',
      integer: true,
      optional: true,
      max: 256,
    ),
    const NumberField(
      id: 'run',
      label: 'Average cable run per point',
      unit: 'm',
      hint: 'From the router or recorder to each outlet or camera',
      initial: '15',
      typical: (min: 2, max: 80),
      max: 1000,
    ),
    priceField('Price per metre', visibleWhen: (s) => !_byBox(s)),
    priceField('Price per box', id: 'boxPrice', visibleWhen: _byBox),
  ],
  choices: const [
    ChoiceField(
      id: 'cctv',
      label: 'CCTV system',
      initial: 'hd',
      helper: 'Used when you enter cameras',
      options: [
        ChoiceOption('hd', 'HD analog with DVR'),
        ChoiceOption('ip', 'IP with NVR and PoE switch'),
      ],
    ),
    ChoiceField(
      id: 'doorbell',
      label: 'Doorbell',
      initial: 'no',
      options: [ChoiceOption('no', 'No'), ChoiceOption('yes', 'Yes')],
    ),
    ChoiceField(
      id: 'buy',
      label: 'Buy CAT6',
      initial: 'metre',
      options: [
        ChoiceOption('metre', 'By the metre'),
        ChoiceOption('box', 'By the box (305 m)'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_byBox(s) ? 'cat6_box' : 'cat6_m'),
  compute: (input) {
    final data = input['data'].round();
    final tv = input.optional('tv').round();
    final cameras = input.optional('cameras').round();
    final run = input['run'];
    final ip = input.chose('cctv', 'ip');
    final doorbell = input.chose('doorbell', 'yes') ? 1 : 0;
    const cctvWork = UtilityWork.cctvCamera;

    final cat6Runs = data + (ip ? cameras : 0);
    final cat6 = cat6Runs * run * (1 + cableAllowance);
    final points = data + tv + doorbell;
    final switches = data > routerLanPorts
        ? ceilCount(data / outletsPerSwitch)
        : 0;
    final splitters = tv > 1 ? ceilCount(tv / outletsPerSplitter) : 0;
    final recorders = cameras > 0 ? recordersFor(cameras) : null;

    final details = <ResultDetail>[
      ResultDetail(
        'CAT6 runs: data${ip && cameras > 0 ? ' + IP cameras' : ''}',
        formatNumber(cat6Runs.toDouble()),
      ),
      ResultDetail(
        'CAT6, runs × ${formatLength(run)} + 10%',
        formatLength(roundUp(cat6, 1)),
      ),
      if (tv > 0)
        ResultDetail(
          'RG6 coax, TV outlets × run + 10%',
          formatLength(roundUp(tv * run * (1 + cableAllowance), 1)),
        ),
      if (recorders != null)
        ResultDetail(
          ip ? 'NVR and PoE switch' : 'DVR',
          '${recorders.count} × ${recorders.channels} channels',
        ),
      if (switches > 0)
        ResultDetail(
          'Network switches, 7 outlets each',
          formatNumber(switches.toDouble()),
        ),
    ];

    final companions = <Companion>[
      buy('keystone_cat6', data.toDouble()),
      buy('faceplate_keystone', (data + tv).toDouble()),
      buy('utility_box', points.toDouble()),
      buy('rj45_plug', data.toDouble()),
      if (switches > 0) buy('network_switch_8', switches.toDouble()),
      if (tv > 0) ...[
        ..._buyCable('rg6_box', 'rg6_m', tv * run * (1 + cableAllowance)),
        buy('keystone_f', tv.toDouble()),
        buy('f_connector', (2 * tv + splitters).toDouble()),
        if (splitters > 0) buy('tv_splitter_4', splitters.toDouble()),
      ],
      if (doorbell > 0) ...[
        buy('doorbell', 1),
        buy(wireMetreKey('2.0'), run * 2 * (1 + cableAllowance)),
      ],
      buy(
        'conduit_half',
        points * run * (1 + conduitAllowance) / conduitLength,
      ),
      if (recorders != null) ...[
        buy(
          ip ? 'cctv_camera_ip' : 'cctv_camera_hd',
          cameras.toDouble(),
          work: cctvWork,
        ),
        buy(
          ip ? nvrKey(recorders.channels) : dvrKey(recorders.channels),
          recorders.count.toDouble(),
          work: cctvWork,
        ),
        buy(
          hardDiskKey(recorderDiskTb[recorders.channels]!),
          recorders.count.toDouble(),
          work: cctvWork,
        ),
        if (ip) ...[
          buy(
            poeSwitchKey(recorders.channels),
            recorders.count.toDouble(),
            work: cctvWork,
          ),
          buy(
            'rj45_plug',
            2.0 * cameras,
            label: 'RJ45 plugs for the cameras',
            work: cctvWork,
          ),
        ] else ...[
          ..._buyCable(
            'rg59_box',
            'rg59_m',
            cameras * run * (1 + cableAllowance),
            work: cctvWork,
          ),
          buy('cctv_connectors', cameras.toDouble(), work: cctvWork),
          buy('cctv_psu', cameras / camerasPerSupply, work: cctvWork),
        ],
        buy('junction_box', cameras.toDouble(), work: cctvWork),
        buy(
          'conduit_half',
          cameras * run * (1 + conduitAllowance) / conduitLength,
          label: 'PVC conduit ½" for the cameras',
          work: cctvWork,
        ),
      ],
    ];

    final works = [
      WorkQuantity(UtilityWork.auxPoint, points.toDouble()),
      if (cameras > 0) WorkQuantity(cctvWork, cameras.toDouble()),
    ];
    const note =
        'Run low-voltage cables in their own conduit, never with power '
        'wires. The internet provider supplies the modem-router.';
    if (input.chose('buy', 'box')) {
      final boxes = ceilCount(cat6 / cableBoxLength);
      return CalcResult(
        label: 'CAT6 UTP cable, box of 305 m',
        quantity: boxes.toDouble(),
        unit: QuantityUnit.boxes,
        unitPrice: input['boxPrice'],
        itemKey: 'cat6_box',
        details: [
          ...details,
          ResultDetail('Boxes of 305 m', formatCount(boxes, 'box', 'boxes')),
        ],
        companions: companions,
        note: note,
        works: works,
      );
    }
    return CalcResult(
      label: 'CAT6 UTP cable',
      quantity: ceilCount(cat6).toDouble(),
      unit: QuantityUnit.metres,
      unitPrice: input['price'],
      itemKey: 'cat6_m',
      details: details,
      companions: companions,
      note: note,
      works: works,
    );
  },
  definitions: const [
    InfoSection(
      'Auxiliary systems',
      'The low-voltage systems of a house: wired internet (data), cable or '
          'antenna TV, CCTV cameras and a doorbell. Each has its own cable '
          'and conduit, separate from the power wiring.',
    ),
    InfoSection(
      'Data outlet',
      'A wall plate with a CAT6 keystone jack, cabled back to the router or '
          'a network switch. Count one for the CCTV recorder so it can be '
          'viewed on a phone. CAT6 is the main item here, priced by the '
          'metre or by the 305 m box.',
    ),
    InfoSection(
      'TV outlet',
      'A wall plate with an F-type keystone, cabled with RG6 coax from a '
          'splitter near the antenna or cable box.',
    ),
    InfoSection(
      'CCTV system',
      'HD analog cameras (TVI, AHD or CVI) run on RG59 cable with power '
          'wires to a DVR and a 12 V power supply. IP cameras run on CAT6 '
          'and take power from a PoE switch, recorded by an NVR. The '
          'recorder has 4, 8 or 16 channels, one per camera, and a '
          'surveillance hard disk.',
    ),
    InfoSection(
      'Cable run',
      'The average cable length from the router, splitter or recorder to '
          'each point, along the conduit. About 15 m in a two-storey house.',
    ),
  ],
  solution: const [
    InfoSection(
      'CAT6 cable',
      'One run per data outlet and per IP camera, each the average run plus '
          '10% for slack and termination. By the metre, round up; by the box, '
          'divide by 305 m and round up.',
      formula:
          'CAT6 = (data + IP cameras) × run × 1.10\n'
          'boxes = round up(CAT6 ÷ 305)',
    ),
    InfoSection(
      'Cost',
      'Multiply the CAT6 by the price per metre or per box.',
      formula: 'cost = CAT6 × price',
    ),
    InfoSection(
      'Outlets',
      'Each data outlet has a CAT6 keystone, a faceplate, a utility box and '
          'an RJ45 plug at the router end. Each TV outlet has an F keystone, '
          'a faceplate, a utility box, an F connector at each end, and a '
          '4-way splitter per 4 outlets. More than 4 data outlets need an '
          '8-port switch per 7 outlets.',
      formula:
          'faceplates = data + TV\n'
          'RG6 = TV × run × 1.10\n'
          'splitters = round up(TV ÷ 4), when TV > 1',
    ),
    InfoSection(
      'CCTV',
      'One recorder of 4, 8 or 16 channels with a 1, 2 or 4 TB disk. HD '
          'analog: RG59 cable, BNC and DC plugs per camera and a 12 V power '
          'supply per 4 cameras. IP: a PoE switch the size of the NVR and two '
          'RJ45 plugs per camera. Each camera gets a junction box.',
      formula: 'CCTV cable = cameras × run × 1.10',
    ),
    InfoSection(
      'Doorbell and conduit',
      'A doorbell has a chime, a push button in a utility box and two '
          '2.0 mm² wires along the run. Every point gets ½" conduit along '
          'its run plus 10%, in 3 m lengths. Cable left over after whole '
          '305 m boxes is cut by the metre, unless it is 200 m or more. All '
          'of these are priced from your price book and added to the total.',
      formula:
          'conduit = round up(points × run × 1.10 ÷ 3)\n'
          'doorbell wire = run × 2 × 1.10',
    ),
  ],
  references: const [
    'https://cctvdesigntool.com/calculators/storage',
    'https://videos.cctvcamerapros.com/video-storage-calculator.md',
    'https://villman.com/Product-Detail/hikvidion_tvi-8ch4d4b-2mp',
  ],
);

// ---------------------------------------------------------------------------
// Lighting fixtures
// ---------------------------------------------------------------------------

/// Share of a fixture's lumens reaching the work plane in a small room
/// with light walls (coefficient of utilisation).
const fixtureUtilisation = 0.6;

/// Light kept after dust and LED ageing (maintenance factor).
const fixtureMaintenance = 0.8;

/// Flexible conduit and 2.0 mm² wire from the junction box to each
/// fixture: 1.5 m of conduit carrying two wires.
const fixtureWhip = 1.5;
const fixtureWires = 2;

bool _fixturesByRoom(Map<String, String> s) => s['mode'] != 'count';
bool _fixturesByCount(Map<String, String> s) => s['mode'] == 'count';

final lightFixtures = MaterialSpec(
  id: 'light_fixtures',
  name: 'Lighting Fixtures',
  category: MaterialCategory.electrical,
  icon: Icons.light_outlined,
  blurb: 'LED downlights, pin lights, ceiling lamps and battens for a room',
  keywords: const [
    'ilaw',
    'pailaw',
    'downlight',
    'pin light',
    'pinlight',
    'ceiling lamp',
    'batten',
    'tube light',
    'LED',
    'lighting',
    'kisame',
  ],
  numbers: [
    NumberField(
      id: 'length',
      label: 'Room length',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
      visibleWhen: _fixturesByRoom,
    ),
    NumberField(
      id: 'width',
      label: 'Room width',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
      visibleWhen: _fixturesByRoom,
    ),
    NumberField(
      id: 'quantity',
      label: 'Number of fixtures',
      unit: 'pcs',
      integer: true,
      max: 100000,
      visibleWhen: _fixturesByCount,
    ),
    priceField('Price per fixture'),
  ],
  choices: [
    const ChoiceField(
      id: 'mode',
      label: 'Count by',
      initial: 'room',
      leading: true,
      options: [
        ChoiceOption('room', 'Room size'),
        ChoiceOption('count', 'Number of fixtures'),
      ],
    ),
    const ChoiceField(
      id: 'room',
      label: 'Room',
      initial: 'living',
      helper: 'Sets how bright the room should be',
      options: [
        ChoiceOption('bedroom', 'Bedroom, 100 lx', 100),
        ChoiceOption('living', 'Living room, 150 lx', 150),
        ChoiceOption('bath', 'Bathroom, 200 lx', 200),
        ChoiceOption('kitchen', 'Kitchen, 300 lx', 300),
        ChoiceOption('study', 'Study or office, 500 lx', 500),
      ],
      visibleWhen: _fixturesByRoom,
    ),
    ChoiceField(
      id: 'type',
      label: 'Fixture',
      initial: 'downlight_4',
      helper: 'Lumens (lm) are printed on the box',
      options: [
        for (final f in ledFixtures) ChoiceOption(f.id, f.label, f.lumens),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(ledFixtureKey(_ledFixture(s['type']).id)),
  compute: (input) {
    final fixture = _ledFixture(input.choice('type').id);
    final label = fixture.name;
    final itemKey = ledFixtureKey(fixture.id);
    final details = <ResultDetail>[];
    double? area;
    final int count;
    if (input.chose('mode', 'count')) {
      count = input['quantity'].round();
    } else {
      area = input['length'] * input['width'];
      final lux = input.choice('room').value;
      final needed = lux * area;
      final useful = fixture.lumens * fixtureUtilisation * fixtureMaintenance;
      count = ceilCount(needed / useful);
      details.addAll([
        ResultDetail('Room area', formatArea(area)),
        ResultDetail(
          'Light needed (${formatNumber(lux)} lx × area)',
          '${formatNumber(needed.roundToDouble())} lm',
        ),
        ResultDetail(
          'Useful light per fixture (× 0.6 × 0.8)',
          '${formatNumber(useful)} lm',
        ),
      ]);
    }
    details.addAll([
      ResultDetail('Fixtures', formatCount(count, 'fixture')),
      ResultDetail(
        'Lighting load, ${fixture.watts} W each',
        '${formatNumber(count * fixture.watts.toDouble())} W',
      ),
    ]);
    return CalcResult(
      label: label,
      area: area,
      quantity: count.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      itemKey: itemKey,
      details: details,
      companions: [
        buy('flex_conduit_m', count * fixtureWhip),
        buy(wireMetreKey('2.0'), count * fixtureWhip * fixtureWires),
      ],
      note:
          'Spread the fixtures evenly, no farther apart than about 1.5 times '
          'the ceiling height. Junction boxes and circuits come with the '
          'Electrical Rough-in calculator.',
      works: [if (count > 0) WorkQuantity(Work.lightFixture, count.toDouble())],
    );
  },
  definitions: const [
    InfoSection(
      'LED fixtures',
      'Fixtures with built-in LEDs instead of a screw-in bulb: recessed '
          'downlights (4" or 6") and small pin lights set into the ceiling '
          'board, surface ceiling lamps, and T8 battens with a 4 ft tube.',
    ),
    InfoSection(
      'Lux and lumens',
      'Lux is the light falling on the floor or table: about 100 lx for '
          'bedrooms, 150 for living rooms, 200 for bathrooms, 300 for '
          'kitchens and 500 for desks. Lumens are the light a fixture gives, '
          'printed on its box.',
    ),
    InfoSection(
      'Utilisation and maintenance',
      'In a small room with light walls about 60% of a fixture\'s light '
          'reaches the work plane (utilisation factor 0.6), and dust and LED '
          'ageing take away another 20% (maintenance factor 0.8).',
    ),
    InfoSection(
      'Fixture wiring',
      'Each fixture is wired from a ceiling junction box with about 1.5 m '
          'of flexible conduit carrying two 2.0 mm² wires. Downlights need '
          'a hole cut in the ceiling board, which needs no material.',
    ),
  ],
  solution: const [
    InfoSection(
      'Light needed',
      'Multiply the brightness the room needs by its area.',
      formula: 'lumens needed = lux × length × width',
    ),
    InfoSection(
      'Fixtures',
      'Divide by the useful light of one fixture, its rated lumens × 0.6 × '
          '0.8, and round up. You can also enter the number of fixtures.',
      formula: 'fixtures = round up(lumens needed ÷ (lumens × 0.6 × 0.8))',
    ),
    InfoSection(
      'Cost',
      'Multiply the fixtures by the price per fixture.',
      formula: 'cost = fixtures × price per fixture',
    ),
    InfoSection(
      'Also needed',
      'Each fixture takes 1.5 m of flexible conduit and 3 m of 2.0 mm² wire. '
          'Both are priced from your price book and added to the total.',
      formula:
          'flexible conduit = round up(fixtures × 1.5)\n'
          'wire = round up(fixtures × 3)',
    ),
  ],
  references: const [
    'https://www.engineeringtoolbox.com/light-level-rooms-d_708.html',
    'https://tools.viox.com/lighting-calculator/',
    'https://www.lrc.rpi.edu/programs/solidstate/assist/pdf/led-lighting-apps-guide-2002.pdf',
  ],
);

/// The calculators.
final List<MaterialSpec> utilitiesMaterials = [
  drainage,
  waterPump,
  auxiliary,
  lightFixtures,
];
