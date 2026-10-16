// Waterproofing, floor finishes, cabinets and countertops.

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';
import 'work_items.dart';

/// Keys of the work items these calculators measure.
abstract final class InteriorsWork {
  static const waterproofing = 'waterproofing';
  static const waterproofingTorch = 'waterproofing_torch';
  static const floorTopping = 'floor_topping';
  static const plankFlooring = 'plank_flooring';
  static const cabinets = 'cabinets';
  static const cabinetsBuilt = 'cabinets_built';
  static const countertop = 'countertop';
}

/// Price book items these calculators buy. Prices are Metro Manila retail
/// in pesos for late 2026, all our own estimates; see docs/calculations.md.
final List<Item> interiorsItems = [
  // Waterproofing.
  const Item(
    'wp_cementitious_set',
    'Cementitious waterproofing, 2-component, 25 kg set',
    'set',
    ItemGroup.paint,
    plural: 'sets',
    price: 3200,
    estimate: true,
  ),
  const Item(
    'wp_liquid_gallon',
    'Elastomeric liquid waterproofing, 4 L',
    'gallon',
    ItemGroup.paint,
    plural: 'gallons',
    price: 1400,
    estimate: true,
  ),
  const Item(
    'wp_liquid_pail',
    'Elastomeric liquid waterproofing, 16 L',
    'pail',
    ItemGroup.paint,
    plural: 'pails',
    price: 5200,
    estimate: true,
  ),
  const Item(
    'wp_torch_roll',
    'Torch-on APP membrane 4 mm, 1 × 10 m',
    'roll',
    ItemGroup.paint,
    plural: 'rolls',
    price: 3600,
    estimate: true,
  ),
  const Item(
    'wp_primer',
    'Waterproofing primer, acrylic, 4 L',
    'gallon',
    ItemGroup.paint,
    plural: 'gallons',
    price: 950,
    estimate: true,
  ),
  const Item(
    'wp_bitumen_primer',
    'Bituminous primer, 4 L',
    'gallon',
    ItemGroup.paint,
    plural: 'gallons',
    price: 850,
    estimate: true,
  ),
  const Item(
    'wp_mesh',
    'Fiberglass reinforcing mesh, 1 m wide',
    'm',
    ItemGroup.paint,
    price: 45,
    estimate: true,
  ),
  const Item(
    'wp_lpg_11kg',
    'LPG, 11 kg tank refill',
    'tank',
    ItemGroup.other,
    plural: 'tanks',
    price: 1050,
    estimate: true,
  ),

  // Floor finishes.
  const Item(
    'floor_spc_box',
    'SPC plank flooring, box of 2.2 m²',
    'box',
    ItemGroup.tiles,
    plural: 'boxes',
    price: 1700,
    estimate: true,
  ),
  const Item(
    'floor_laminate_box',
    'Laminated wood flooring 8 mm, box of 2 m²',
    'box',
    ItemGroup.tiles,
    plural: 'boxes',
    price: 1300,
    estimate: true,
  ),
  const Item(
    'floor_underlay_roll',
    'Foam underlay 2 mm, 1 × 20 m',
    'roll',
    ItemGroup.tiles,
    plural: 'rolls',
    price: 900,
    estimate: true,
  ),
  const Item(
    'floor_skirting',
    'Floor skirting, PVC 80 mm × 2.4 m',
    'pc',
    ItemGroup.tiles,
    plural: 'pcs',
    price: 280,
    estimate: true,
  ),
  const Item(
    'floor_trim',
    'Floor transition trim, 2.4 m',
    'pc',
    ItemGroup.tiles,
    plural: 'pcs',
    price: 450,
    estimate: true,
  ),
  const Item(
    'floor_hardener',
    'Floor hardener, dry-shake, 25 kg',
    'bag',
    ItemGroup.tiles,
    plural: 'bags',
    price: 1400,
    estimate: true,
  ),

  // Cabinets and countertops.
  const Item(
    'cabinet_base_lm',
    'Base cabinet, made to order',
    'm',
    ItemGroup.other,
    step: 0.01,
    price: 14000,
    estimate: true,
  ),
  const Item(
    'cabinet_upper_lm',
    'Wall cabinet, made to order',
    'm',
    ItemGroup.other,
    step: 0.01,
    price: 10000,
    estimate: true,
  ),
  const Item(
    'counter_granite_m2',
    'Granite countertop, fabricated',
    'm²',
    ItemGroup.other,
    step: 0.01,
    price: 6500,
    estimate: true,
  ),
  const Item(
    'counter_quartz_m2',
    'Quartz countertop, fabricated',
    'm²',
    ItemGroup.other,
    step: 0.01,
    price: 12000,
    estimate: true,
  ),
  const Item(
    'counter_solid_m2',
    'Solid surface countertop, fabricated',
    'm²',
    ItemGroup.other,
    step: 0.01,
    price: 9000,
    estimate: true,
  ),
  const Item(
    'counter_laminate_m2',
    'Laminated plywood countertop, fabricated',
    'm²',
    ItemGroup.other,
    step: 0.01,
    price: 3500,
    estimate: true,
  ),
  const Item(
    'hpl_laminate',
    'High-pressure laminate 0.8 mm 4×8',
    'sheet',
    ItemGroup.lumber,
    plural: 'sheets',
    price: 1800,
    estimate: true,
  ),
  const Item(
    'edge_band',
    'PVC edge band 22 mm × 50 m',
    'roll',
    ItemGroup.lumber,
    plural: 'rolls',
    price: 450,
    estimate: true,
  ),
  const Item(
    'contact_cement',
    'Contact cement, 1 L',
    'L',
    ItemGroup.lumber,
    price: 300,
    estimate: true,
  ),
  const Item(
    'cabinet_hinge',
    'Concealed cabinet hinge 35 mm, soft-close',
    'pc',
    ItemGroup.other,
    plural: 'pcs',
    price: 150,
    estimate: true,
  ),
  const Item(
    'drawer_slide',
    'Drawer slide 18", full extension',
    'pair',
    ItemGroup.other,
    plural: 'pairs',
    price: 350,
    estimate: true,
  ),
  const Item(
    'cabinet_handle',
    'Cabinet handle',
    'pc',
    ItemGroup.other,
    plural: 'pcs',
    price: 80,
    estimate: true,
  ),
];

/// Work items these calculators measure. Outputs are for small jobs; no
/// DPWH item number was confirmed for them.
const interiorsWorkItems = <WorkItem>[
  // Output for the whole system in 2 coats, the mesh included; a third
  // coat counts as half as much again.
  WorkItem(
    InteriorsWork.waterproofing,
    'Waterproofing coating, 2 coats with reinforcing mesh',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 25,
  ),
  WorkItem(
    InteriorsWork.waterproofingTorch,
    'Torch-on bituminous membrane, primed and lapped',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 30,
  ),
  // Output at 25 mm; a 50 mm screed counts twice.
  WorkItem(
    InteriorsWork.floorTopping,
    'Cement floor topping, troweled finish',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 25,
  ),
  WorkItem(
    InteriorsWork.plankFlooring,
    'SPC or laminate plank flooring with underlay and skirting',
    'm²',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 0.5),
    output: 20,
  ),
  WorkItem(
    InteriorsWork.cabinets,
    'Cabinets made to order, installed',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 3,
  ),
  WorkItem(
    InteriorsWork.cabinetsBuilt,
    'Cabinets built on site, laminated, with hardware',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 0.6,
  ),
  WorkItem(
    InteriorsWork.countertop,
    'Countertop with backsplash, installed',
    'm',
    trade: MaterialCategory.architectural,
    crew: Crew(skilled: 1, helpers: 1),
    output: 4,
  ),
];

/// A measured work quantity, to the nearest hundredth of its unit.
double _hundredths(double value) => (value * 100).roundToDouble() / 100;

/// Litres in a Philippine paint "gallon" and in a pail.
const _gallonLitres = 4.0;
const _pailLitres = 16.0;

// ---------------------------------------------------------------------------
// Waterproofing

/// Two-component cementitious coating: about 2 kg/m² per coat of about
/// 1 mm, sold in 25 kg sets of liquid and powder.
const _cementitiousPerCoat = 2.0;
const _cementitiousSet = 25.0;

/// Elastomeric acrylic liquid membrane: about 0.5 L/m² per coat, over an
/// acrylic primer at about 0.2 L/m².
const _liquidPerCoat = 0.5;
const _liquidPrimer = 0.2;

/// Torch-on rolls are 1 × 10 m and lap 10 cm at the sides and ends, so
/// each covers 0.9 × 9.9 = 8.91 m².
const _rollCover = (1.0 - 0.10) * (10.0 - 0.10);

/// A 0.25 m strip of membrane is torched over corners and joints first.
const _torchStrip = 0.25;

/// Bituminous primer under torch-on membrane, L/m².
const _bitumenPrimer = 0.3;

/// LPG burned per roll of membrane, in kg; sold in 11 kg tanks.
const _lpgPerRoll = 2.0;
const _lpgTank = 11.0;

/// Coatings are reinforced with mesh strips 0.20 m wide, cut from 1 m
/// wide mesh, over the wall corners and joints.
const _meshStrip = 0.20;

bool _liquid(Map<String, String> s) => s['system'] == 'liquid';
bool _torch(Map<String, String> s) => s['system'] == 'torch';
bool _cementitious(Map<String, String> s) => !_liquid(s) && !_torch(s);
bool _pail(Map<String, String> s) => _liquid(s) && s['pack'] == 'pail';
bool _gallon(Map<String, String> s) => _liquid(s) && s['pack'] != 'pail';

final waterproofing = MaterialSpec(
  id: 'waterproofing',
  name: 'Waterproofing',
  category: MaterialCategory.architectural,
  icon: Icons.water_damage_outlined,
  blurb: 'Coatings or torch-on membrane for decks, baths and planters',
  keywords: const [
    'waterproofing',
    'tagas',
    'tulo',
    'leak',
    'roof deck',
    'balcony',
    'balkonahe',
    'banyo',
    'CR',
    'toilet',
    'planter box',
    'membrane',
    'torch-on',
    'elastomeric',
    'cementitious',
    'bitumen',
    'aspalto',
  ],
  priceRef: (s) => PriceRef(switch (s['system']) {
    'liquid' => s['pack'] == 'pail' ? 'wp_liquid_pail' : 'wp_liquid_gallon',
    'torch' => 'wp_torch_roll',
    _ => 'wp_cementitious_set',
  }),
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Area length',
      typical: (min: 0.5, max: 100),
      unit: 'm',
      hint: 'The floor, deck or planter box to waterproof',
      max: 10000,
    ),
    const NumberField(
      id: 'width',
      label: 'Area width',
      typical: (min: 0.5, max: 100),
      unit: 'm',
      max: 10000,
    ),
    const NumberField(
      id: 'joints',
      label: 'Joints and cracks',
      typical: (min: 0.3, max: 500),
      unit: 'm',
      hint: 'Optional. Slab joints and cracks to reinforce',
      optional: true,
      max: 10000,
    ),
    priceField(
      'Price per 25 kg set',
      id: 'setPrice',
      visibleWhen: _cementitious,
    ),
    priceField(
      'Price per gallon (4 L)',
      id: 'gallonPrice',
      visibleWhen: _gallon,
    ),
    priceField('Price per pail (16 L)', id: 'pailPrice', visibleWhen: _pail),
    priceField('Price per roll', id: 'rollPrice', visibleWhen: _torch),
  ],
  choices: [
    const ChoiceField(
      id: 'system',
      label: 'Waterproofing system',
      initial: 'cementitious',
      leading: true,
      options: [
        ChoiceOption('cementitious', 'Cementitious coating, 2-component'),
        ChoiceOption('liquid', 'Elastomeric liquid membrane'),
        ChoiceOption('torch', 'Torch-on bituminous membrane'),
      ],
    ),
    const ChoiceField(
      id: 'upturn',
      label: 'Upturn on walls',
      initial: '0.30',
      helper: 'Carried up the walls, curbs and parapets all around',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.15', '0.15 m', 0.15),
        ChoiceOption('0.30', '0.30 m', 0.30),
        ChoiceOption('0.60', '0.60 m, planter boxes', 0.60),
      ],
    ),
    ChoiceField(
      id: 'coats',
      label: 'Coats',
      initial: '2',
      options: const [
        ChoiceOption('2', '2 coats', 2),
        ChoiceOption('3', '3 coats', 3),
      ],
      visibleWhen: (s) => !_torch(s),
    ),
    ChoiceField(
      id: 'pack',
      label: 'Container',
      initial: 'gallon',
      options: const [
        ChoiceOption('gallon', '4 L gallon'),
        ChoiceOption('pail', '16 L pail'),
      ],
      visibleWhen: _liquid,
    ),
    wasteField(
      initial: '10',
      helper: 'Rough surfaces, laps and spillage',
      percents: const [0, 5, 10, 15],
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final floor = length * width;
    final perimeter = 2 * (length + width);
    final upturn = input.choice('upturn').value;
    final walls = perimeter * upturn;
    final area = floor + walls;
    final reinforce = perimeter + input.optional('joints');
    final waste = input.choice('waste').value;
    final withWasteLabel = waste > 0 ? ', +${formatPercent(waste)} waste' : '';
    final areaDetails = [
      ResultDetail('Floor area', formatArea(roundUp(floor))),
      if (walls > 0)
        ResultDetail(
          'Upturn, ${formatLength(roundUp(perimeter))} × '
              '${formatLength(upturn)}',
          '+${formatArea(roundUp(walls))}',
        ),
      ResultDetail('Area to waterproof', formatArea(roundUp(area))),
    ];
    final reinforceDetail = ResultDetail(
      'Corners and joints to reinforce',
      formatLength(roundUp(reinforce)),
    );

    if (input.chose('system', 'torch')) {
      final strips = reinforce * _torchStrip;
      final membrane = (area + strips) * (1 + waste);
      final rolls = ceilCount(membrane / _rollCover);
      return CalcResult(
        label: 'Torch-on membrane 4 mm, 1 × 10 m rolls',
        area: area,
        quantity: rolls.toDouble(),
        unit: QuantityUnit.rolls,
        unitPrice: input['rollPrice'],
        itemKey: 'wp_torch_roll',
        details: [
          ...areaDetails,
          reinforceDetail,
          ResultDetail('Strips 0.25 m wide', '+${formatArea(roundUp(strips))}'),
          ResultDetail(
            'Membrane$withWasteLabel',
            formatArea(roundUp(membrane)),
          ),
          ResultDetail(
            'Rolls of 8.91 m² (10 cm laps)',
            formatQuantity(rolls.toDouble(), QuantityUnit.rolls),
          ),
        ],
        companions: [
          buy(
            'wp_bitumen_primer',
            area * _bitumenPrimer * (1 + waste) / _gallonLitres,
          ),
          buy('wp_lpg_11kg', rolls * _lpgPerRoll / _lpgTank),
        ],
        note:
            'Torch-on membrane is laid by a trained applicator on a dry, '
            'primed slab. Protect it with a screed or tiles where it will be '
            'walked on, unless it has a mineral finish.',
        works: [
          WorkQuantity(InteriorsWork.waterproofingTorch, _hundredths(area)),
        ],
      );
    }

    final coats = input.choice('coats').value;
    final coatLabel = '${formatNumber(coats)} coats';
    final mesh = buy('wp_mesh', reinforce * _meshStrip * (1 + waste));
    final works = [
      WorkQuantity(
        InteriorsWork.waterproofing,
        _hundredths(area),
        effort: coats / 2,
      ),
    ];
    const flood =
        'Flood-test the area with water for 24 hours before it is covered.';

    if (input.chose('system', 'liquid')) {
      final litres = area * _liquidPerCoat * coats * (1 + waste);
      final pail = input.chose('pack', 'pail');
      final size = pail ? _pailLitres : _gallonLitres;
      final count = ceilCount(litres / size);
      return CalcResult(
        label:
            'Elastomeric waterproofing, $coatLabel, '
            '${pail ? '16 L pails' : '4 L gallons'}',
        area: area,
        quantity: count.toDouble(),
        unit: pail ? QuantityUnit.pails : QuantityUnit.gallons,
        unitPrice: pail ? input['pailPrice'] : input['gallonPrice'],
        itemKey: pail ? 'wp_liquid_pail' : 'wp_liquid_gallon',
        details: [
          ...areaDetails,
          ResultDetail(
            '$coatLabel at 0.5 L/m²$withWasteLabel',
            '${formatNumber(roundUp(litres, 1))} L',
          ),
          ResultDetail(
            pail ? 'Pails of 16 L' : 'Gallons of 4 L',
            formatCount(count, pail ? 'pail' : 'gallon'),
          ),
          reinforceDetail,
        ],
        companions: [
          buy('wp_primer', area * _liquidPrimer * (1 + waste) / _gallonLitres),
          mesh,
        ],
        note: 'Prime the slab, then bed the mesh in the first coat. $flood',
        works: works,
      );
    }

    final kg = area * _cementitiousPerCoat * coats * (1 + waste);
    final sets = ceilCount(kg / _cementitiousSet);
    return CalcResult(
      label: 'Cementitious waterproofing, $coatLabel',
      area: area,
      quantity: sets.toDouble(),
      unit: QuantityUnit.sets,
      unitPrice: input['setPrice'],
      itemKey: 'wp_cementitious_set',
      details: [
        ...areaDetails,
        ResultDetail(
          '$coatLabel at 2 kg/m²$withWasteLabel',
          '${formatNumber(roundUp(kg, 1))} kg',
        ),
        ResultDetail(
          'Sets of 25 kg',
          formatQuantity(sets.toDouble(), QuantityUnit.sets),
        ),
        reinforceDetail,
      ],
      companions: [mesh],
      note:
          'Wet the concrete first; cementitious coatings need no primer. '
          '$flood',
      works: works,
    );
  },
  definitions: const [
    InfoSection(
      'Where it goes',
      'Roof decks, balconies, toilet and bath floors and planter boxes: any '
          'slab that is often wet. The coating or membrane goes on the '
          'concrete, under the screed or tiles, unless it is made to be left '
          'exposed.',
    ),
    InfoSection(
      'Upturn',
      'The waterproofing turns up the walls, curbs and parapets all around '
          'so water cannot get in at the edges: at least 0.15 m, and usually '
          '0.30 m in toilets and baths and at parapets. Planter boxes are '
          'coated up their sides. Shower walls coated higher can be added as '
          'their own area.',
    ),
    InfoSection(
      'Cementitious coating',
      'A polymer liquid mixed with a cement powder, sold as a set (commonly '
          '25 kg). It is brushed on in two or three coats about 1 mm each '
          'over damp concrete, needs no primer, and is covered with tiles or '
          'a screed.',
    ),
    InfoSection(
      'Elastomeric liquid membrane',
      'An acrylic coating that cures into a rubbery film that bridges small '
          'cracks. It goes on over a primer in 2 or 3 coats and is sold in '
          '4 L gallons and 16 L pails. Some grades can be left exposed on '
          'roofs.',
    ),
    InfoSection(
      'Torch-on membrane',
      'Sheets of APP-modified bitumen, 1 × 10 m, melted onto a primed slab '
          'with an LPG torch. Neighbouring sheets lap 10 cm at the sides and '
          'ends. A strip is torched over the corners and joints first.',
    ),
    InfoSection(
      'Corners and joints',
      'Coatings crack first where the floor meets the wall, at slab joints '
          'and cracks, and around drains and pipes. Strips of fiberglass mesh '
          'about 20 cm wide are bedded in the first coat there.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area to waterproof',
      'The floor plus the upturn all around it.',
      formula:
          'perimeter = 2 × (length + width)\n'
          'area = length × width + perimeter × upturn',
    ),
    InfoSection(
      'Cementitious coating',
      'About 2 kg/m² for each coat, plus waste, in 25 kg sets.',
      formula:
          'kg = area × 2 × coats × (1 + waste)\n'
          'sets = round up(kg ÷ 25)',
    ),
    InfoSection(
      'Liquid membrane',
      'About 0.5 L/m² for each coat, plus waste, in 4 L gallons or 16 L '
          'pails. The primer takes about 0.2 L/m².',
      formula:
          'litres = area × 0.5 × coats × (1 + waste)\n'
          'containers = round up(litres ÷ 4 or 16)\n'
          'primer = round up(area × 0.2 × (1 + waste) ÷ 4) gallons',
    ),
    InfoSection(
      'Mesh',
      'Strips 0.20 m wide along the perimeter and the joints, cut from 1 m '
          'wide mesh.',
      formula: 'mesh = round up((perimeter + joints) × 0.20 × (1 + waste)) m',
    ),
    InfoSection(
      'Torch-on membrane',
      'Each 1 × 10 m roll covers 0.9 × 9.9 = 8.91 m² once lapped. Strips '
          '0.25 m wide go over the perimeter and joints first. Bituminous '
          'primer takes about 0.3 L/m², and each roll burns about 2 kg of '
          'LPG.',
      formula:
          'membrane = (area + (perimeter + joints) × 0.25) × (1 + waste)\n'
          'rolls = round up(membrane ÷ 8.91)\n'
          'primer = round up(area × 0.3 × (1 + waste) ÷ 4) gallons\n'
          'LPG = round up(rolls × 2 ÷ 11) tanks of 11 kg',
    ),
    InfoSection(
      'Cost',
      'Sets, gallons, pails or rolls × the price. Primer, mesh and LPG are '
          'priced from your price list and added to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'Sika Philippines, SikaTop Seal-107 product data sheet (two-component '
        'cementitious waterproofing)',
    'Sika, Sikalastic-560 product data sheet (liquid-applied membrane)',
    'BS 6229:2018, Flat roofs with continuously supported flexible '
        'waterproof coverings (150 mm minimum upstands)',
    'Manufacturers\' installation guides for APP torch-on membranes '
        '(1 × 10 m rolls, 100 mm side and end laps)',
  ],
);

// ---------------------------------------------------------------------------
// Floor finishes

/// Box coverage when none is entered, m².
const _spcBox = 2.2;
const _laminateBox = 2.0;

/// Foam underlay rolls are 1 × 20 m, butted and taped, with 5% for
/// trimming.
const _underlayRoll = 20.0;
const _underlayWaste = 0.05;

/// Skirting and transition trims come in 2.4 m lengths; a doorway takes
/// 0.90 m of trim.
const _trimLength = 2.4;
const _doorwayWidth = 0.90;

/// Sand per m³ of mortar, for both 1:2 and 1:3 (Fajardo).
const _toppingSand = 1.0;

/// Dry-shake hardener for light traffic, kg/m², in 25 kg bags.
const _hardenerRate = 3.0;
const _hardenerBag = 25.0;

/// The floor topping output is per m² at 25 mm.
const _toppingBase = 0.025;

/// Neat cement slurry brushed on the slab to bond the topping, bags per
/// m², as under a tile bed.
const _toppingSlurry = 0.025;

bool _topping(Map<String, String> s) => s['type'] == 'topping';
bool _laminate(Map<String, String> s) => s['type'] == 'laminate';
bool _spc(Map<String, String> s) => !_topping(s) && !_laminate(s);
bool _planks(Map<String, String> s) => !_topping(s);

final flooring = MaterialSpec(
  id: 'flooring',
  name: 'Floor Finishes',
  category: MaterialCategory.architectural,
  icon: Icons.view_stream_outlined,
  blurb: 'SPC, laminate or cement topping, with underlay and skirting',
  keywords: const [
    'sahig',
    'flooring',
    'SPC',
    'vinyl',
    'vinyl plank',
    'laminate',
    'laminated flooring',
    'wood floor',
    'kahoy',
    'floor topping',
    'screed',
    'semento',
    'hardener',
    'underlay',
    'skirting',
  ],
  priceRef: (s) => PriceRef(
    _topping(s)
        ? 'cement_40kg'
        : _laminate(s)
        ? 'floor_laminate_box'
        : 'floor_spc_box',
  ),
  numbers: [
    const NumberField(
      id: 'length',
      label: 'Room length',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
    ),
    const NumberField(
      id: 'width',
      label: 'Room width',
      typical: (min: 0.5, max: 40),
      unit: 'm',
      max: 1000,
    ),
    NumberField(
      id: 'skirting',
      label: 'Skirting length',
      typical: (min: 0.3, max: 300),
      unit: 'm',
      hint: 'Optional. Room perimeter less doors',
      optional: true,
      max: 10000,
      visibleWhen: _planks,
    ),
    NumberField(
      id: 'doorways',
      label: 'Doorways',
      unit: 'pcs',
      hint: 'Optional. Each gets a transition trim',
      integer: true,
      optional: true,
      max: 1000,
      visibleWhen: _planks,
    ),
    NumberField(
      id: 'coverage',
      label: 'Coverage per box',
      unit: 'm²',
      hint: 'Optional. Printed on the box',
      optional: true,
      max: 100,
      visibleWhen: _planks,
    ),
    priceField('Price per box', id: 'spcPrice', visibleWhen: _spc),
    priceField('Price per box', id: 'laminatePrice', visibleWhen: _laminate),
    NumberField(
      id: 'cementPrice',
      label: 'Price per bag of cement',
      unit: '₱',
      hint: '40 kg bag',
      isPrice: true,
      max: 100000,
      visibleWhen: _topping,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Floor finish',
      initial: 'spc',
      leading: true,
      options: [
        ChoiceOption('spc', 'SPC or vinyl planks'),
        ChoiceOption('laminate', 'Laminated wood planks'),
        ChoiceOption('topping', 'Cement topping or screed'),
      ],
    ),
    ChoiceField(
      id: 'underlay',
      label: 'Underlay',
      initial: 'roll',
      helper: 'Many SPC planks come with a foam pad attached',
      options: const [
        ChoiceOption('roll', 'Foam underlay rolls'),
        ChoiceOption('attached', 'Pad attached to the planks'),
      ],
      visibleWhen: _planks,
    ),
    ChoiceField(
      id: 'thickness',
      label: 'Topping thickness',
      initial: '25',
      helper: '25 mm bonded to a level slab; 50 mm to level an uneven one',
      options: const [
        ChoiceOption('25', '25 mm', 0.025),
        ChoiceOption('50', '50 mm', 0.050),
      ],
      visibleWhen: _topping,
    ),
    // The value is bags of 40 kg cement per m³ of mortar (Fajardo).
    ChoiceField(
      id: 'mix',
      label: 'Mortar mix',
      initial: '2',
      helper: 'Cement to sand: 1:2 for a wearing floor, 1:3 under a finish',
      options: const [
        ChoiceOption('2', '1:2, Class A', 18),
        ChoiceOption('3', '1:3, Class B', 12),
      ],
      visibleWhen: _topping,
    ),
    ChoiceField(
      id: 'hardener',
      label: 'Floor hardener',
      initial: 'none',
      helper: 'Dry-shake hardener troweled into the fresh topping',
      options: const [
        ChoiceOption('none', 'None'),
        ChoiceOption('dry', 'Dry-shake hardener'),
      ],
      visibleWhen: _topping,
    ),
    wasteField(
      initial: '10',
      helper: 'Plank offcuts, or spillage and low spots for a topping',
      percents: const [5, 7, 10, 15],
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    final waste = input.choice('waste').value;
    final areaDetail = ResultDetail('Floor area', formatArea(roundUp(area)));

    if (input.chose('type', 'topping')) {
      final thickness = input.choice('thickness').value;
      final mix = input.choice('mix');
      final mortar = area * thickness * (1 + waste);
      final slurry = area * _toppingSlurry;
      final cement = ceilCount(mortar * mix.value + slurry);
      final hardener = input.chose('hardener', 'dry');
      final mm = formatNumber(thickness * 1000);
      return CalcResult(
        label: 'Floor topping $mm mm, ${mix.label}',
        area: area,
        quantity: cement.toDouble(),
        unit: QuantityUnit.bags,
        unitPrice: input['cementPrice'],
        itemKey: 'cement_40kg',
        details: [
          areaDetail,
          ResultDetail(
            'Mortar $mm mm thick, +${formatPercent(waste)} waste',
            formatVolume(roundUp(mortar, 3)),
          ),
          ResultDetail(
            'Cement, ${formatNumber(mix.value)} bags per m³',
            formatCount(roundUp(mortar * mix.value), 'bag'),
          ),
          ResultDetail(
            'Bond coat, 0.025 bags per m²',
            '+${formatCount(roundUp(slurry), 'bag')}',
          ),
          ResultDetail('Cement to buy', formatCount(cement, 'bag')),
        ],
        companions: [
          buy('sand', mortar * _toppingSand),
          if (hardener)
            buy('floor_hardener', area * _hardenerRate / _hardenerBag),
        ],
        note:
            'Roughen and wet the slab and brush on the cement slurry just '
            'before the topping. Keep it wet for 7 days to cure.',
        works: [
          WorkQuantity(
            InteriorsWork.floorTopping,
            _hundredths(area),
            effort: thickness / _toppingBase,
          ),
        ],
      );
    }

    final spc = !input.chose('type', 'laminate');
    final entered = input.optional('coverage');
    final coverage = entered > 0 ? entered : (spc ? _spcBox : _laminateBox);
    final needed = area * (1 + waste);
    final boxes = ceilCount(needed / coverage);
    final skirting = input.optional('skirting');
    final doorways = input.optional('doorways');
    return CalcResult(
      label: spc
          ? 'SPC plank flooring, box of ${formatArea(coverage)}'
          : 'Laminated wood flooring, box of ${formatArea(coverage)}',
      area: area,
      quantity: boxes.toDouble(),
      unit: QuantityUnit.boxes,
      unitPrice: spc ? input['spcPrice'] : input['laminatePrice'],
      itemKey: spc ? 'floor_spc_box' : 'floor_laminate_box',
      details: [
        areaDetail,
        ResultDetail(
          'With ${formatPercent(waste)} waste',
          formatArea(roundUp(needed)),
        ),
        ResultDetail(
          'Boxes of ${formatArea(coverage)}',
          formatQuantity(boxes.toDouble(), QuantityUnit.boxes),
        ),
        if (skirting > 0) ResultDetail('Skirting', formatLength(skirting)),
      ],
      companions: [
        if (input.chose('underlay', 'roll'))
          buy(
            'floor_underlay_roll',
            area * (1 + _underlayWaste) / _underlayRoll,
          ),
        if (skirting > 0)
          buy('floor_skirting', skirting * (1 + waste) / _trimLength),
        if (doorways > 0)
          buy('floor_trim', doorways * _doorwayWidth / _trimLength),
      ],
      note:
          'Leave a 10 mm gap at the walls for the planks to move; the '
          'skirting hides it.',
      works: [WorkQuantity(InteriorsWork.plankFlooring, _hundredths(area))],
    );
  },
  definitions: const [
    InfoSection(
      'SPC and vinyl planks',
      'Stone-plastic composite (SPC) or vinyl planks click together and '
          'float on the floor. A box usually holds about 2.2 m²; the '
          'coverage is printed on the box. Many come with a foam pad '
          'attached and need no underlay.',
    ),
    InfoSection(
      'Laminated wood flooring',
      'Planks of HDF board with a printed wood surface, usually 8 or 12 mm '
          'thick and about 2 m² to a box. They float on a foam underlay.',
    ),
    InfoSection(
      'Cement topping or screed',
      'A layer of cement-sand mortar troweled smooth over the slab, as the '
          'finished floor or as a level base for another finish: 25 mm '
          'bonded to a sound slab, 50 mm over an uneven one. A dry-shake '
          'hardener troweled into the fresh surface makes it wear longer.',
    ),
    InfoSection(
      'Skirting and trims',
      'Skirting runs along the foot of the walls and hides the 10 mm gap '
          'the planks need. Enter the room perimeter less the doors. A '
          'transition trim covers the plank edge at each doorway.',
    ),
    InfoSection(
      'Waste',
      'Cut ends and offcuts of planks: about 7% in a plain room, 10% in '
          'most rooms and 15% for diagonal layouts. For a topping it covers '
          'spillage and low spots in the slab.',
    ),
  ],
  solution: const [
    InfoSection(
      'Planks',
      'Floor area plus waste, divided by the coverage per box: 2.2 m² for '
          'SPC and 2.0 m² for laminate unless you enter the number printed '
          'on the box.',
      formula: 'boxes = round up(length × width × (1 + waste) ÷ coverage)',
    ),
    InfoSection(
      'Underlay',
      'Foam underlay comes in 1 × 20 m rolls, butted and taped, with 5% for '
          'trimming.',
      formula: 'rolls = round up(area × 1.05 ÷ 20)',
    ),
    InfoSection(
      'Skirting and trims',
      'Skirting in 2.4 m lengths plus the waste allowance; 0.90 m of trim '
          'for each doorway, cut from 2.4 m lengths.',
      formula:
          'skirting = round up(skirting length × (1 + waste) ÷ 2.4)\n'
          'trims = round up(doorways × 0.90 ÷ 2.4)',
    ),
    InfoSection(
      'Cement topping',
      'Mortar volume plus waste. A 1:2 mix (Class A mortar) takes 18 bags '
          'of cement per m³ and a 1:3 mix (Class B) 12 bags, each with 1 m³ '
          'of sand. A neat cement slurry bonds it to the slab, 0.025 bags '
          'per m².',
      formula:
          'mortar = area × thickness × (1 + waste)\n'
          'cement = round up(mortar × 18 or 12 + area × 0.025) bags\n'
          'sand = mortar × 1.0 m³',
    ),
    InfoSection(
      'Hardener',
      'About 3 kg/m² of dry-shake hardener for light traffic, in 25 kg '
          'bags.',
      formula: 'bags = round up(area × 3 ÷ 25)',
    ),
    InfoSection(
      'Cost',
      'Boxes × the price per box, or bags of cement × the price per bag. '
          'Underlay, skirting, trims, sand and hardener are priced from your '
          'price list and added to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, mortar per m³ '
        '(Class A 1:2 and Class B 1:3)',
    'Sika, Sikafloor Chapdur product data sheet (dry-shake floor hardener)',
    'SPC and laminate flooring makers\' installation guides (10 mm '
        'expansion gap, underlay, 5–10% waste)',
  ],
);

// ---------------------------------------------------------------------------
// Cabinets and countertops

/// Countertops by option id: name and price book entry, priced per m².
const _countertops = {
  'granite': (label: 'Granite', key: 'counter_granite_m2'),
  'quartz': (label: 'Quartz', key: 'counter_quartz_m2'),
  'solid': (label: 'Solid surface', key: 'counter_solid_m2'),
  'laminate': (label: 'Laminated plywood', key: 'counter_laminate_m2'),
};

/// Panels of 18 mm plywood per metre of a base cabinet 0.60 m deep and
/// 0.75 m high on a 0.10 m toe kick (bottom, sides and partitions, a
/// shelf, doors, rails, toe kick and one drawer box), and of a wall
/// cabinet 0.35 m deep and 0.70 m high (top, bottom, sides, a shelf and
/// doors), in m².
const _basePanels = 3.5;
const _wallPanels = 2.2;

/// The 6 mm plywood back, m² per metre of cabinet.
const _backPanels = 0.75;

/// Laminate on the exposed faces, m² per metre of cabinet.
const _laminateFaces = 1.0;

/// Cutting waste on plywood and laminate sheets.
const _cutWaste = 0.15;

/// Contact cement per m² of laminate, both faces coated, in litres.
const _contactCement = 0.4;

/// Edge band per metre of cabinet, in rolls of 50 m with 10% waste.
const _edgePerMetre = 9.0;
const _edgeRoll = 50.0;
const _edgeWaste = 0.10;

/// Doors are about 0.50 m wide with 2 hinges each; base cabinets have one
/// drawer per metre.
const _doorWidth = 0.50;
const _hingesPerDoor = 2;
const _drawerEvery = 1.0;

/// Nails per metre of cabinet, kg.
const _cabinetNails = 0.2;

bool _onSite(Map<String, String> s) => s['build'] == 'site';
bool _hasTop(Map<String, String> s) => s['top'] != 'none';

final cabinets = MaterialSpec(
  id: 'cabinets',
  name: 'Cabinets and Countertops',
  category: MaterialCategory.architectural,
  icon: Icons.countertops_outlined,
  blurb: 'Kitchen or vanity cabinets per metre, with the countertop',
  keywords: const [
    'cabinet',
    'kabinet',
    'kitchen cabinet',
    'kusina',
    'lababo',
    'aparador',
    'paminggalan',
    'countertop',
    'granite',
    'quartz',
    'solid surface',
    'vanity',
    'built-in',
    'modular',
    'laminate',
  ],
  priceRef: (s) =>
      PriceRef(_onSite(s) ? marinePlywoodKey('18') : 'cabinet_base_lm'),
  numbers: [
    const NumberField(
      id: 'base',
      label: 'Base cabinet length',
      typical: (min: 0.3, max: 20),
      unit: 'm',
      hint: 'Along the wall; add both legs of an L',
      max: 1000,
    ),
    const NumberField(
      id: 'upper',
      label: 'Wall cabinet length',
      typical: (min: 0.3, max: 20),
      unit: 'm',
      hint: 'Optional. Upper cabinets above the counter',
      optional: true,
      max: 1000,
    ),
    NumberField(
      id: 'lmPrice',
      label: 'Price per metre of base cabinet',
      unit: '₱',
      hint: "Fabricator's price, without the countertop",
      isPrice: true,
      max: 10000000,
      visibleWhen: (s) => !_onSite(s),
    ),
    NumberField(
      id: 'sheetPrice',
      label: 'Price per sheet of plywood',
      unit: '₱',
      hint: '18 mm (¾") marine plywood, 4×8',
      isPrice: true,
      max: 1000000,
      visibleWhen: _onSite,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'build',
      label: 'Cabinets',
      initial: 'order',
      leading: true,
      helper: 'From a fabricator per metre, or built by a carpenter',
      options: [
        ChoiceOption('order', 'Made to order'),
        ChoiceOption('site', 'Built on site'),
      ],
    ),
    const ChoiceField(
      id: 'top',
      label: 'Countertop',
      initial: 'granite',
      options: [
        ChoiceOption('granite', 'Granite'),
        ChoiceOption('quartz', 'Quartz'),
        ChoiceOption('solid', 'Solid surface'),
        ChoiceOption('laminate', 'Laminated plywood'),
        ChoiceOption('none', 'No countertop'),
      ],
    ),
    ChoiceField(
      id: 'depth',
      label: 'Countertop depth',
      initial: '0.60',
      options: const [
        ChoiceOption('0.60', '0.60 m, kitchen', 0.60),
        ChoiceOption('0.50', '0.50 m, vanity', 0.50),
      ],
      visibleWhen: _hasTop,
    ),
    ChoiceField(
      id: 'backsplash',
      label: 'Backsplash',
      initial: '0.10',
      helper: 'Countertop material up the wall behind the counter',
      options: const [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.10', '0.10 m', 0.10),
        ChoiceOption('0.60', '0.60 m, up to the wall cabinets', 0.60),
      ],
      visibleWhen: _hasTop,
    ),
  ],
  compute: (input) {
    final base = input['base'];
    final upper = input.optional('upper');
    final metres = base + upper;
    final topId = input.choice('top').id;
    final top = _countertops[topId];
    final depth = top == null ? 0.0 : input.choice('depth').value;
    final splash = top == null ? 0.0 : input.choice('backsplash').value;
    final topArea = base * (depth + splash);
    final site = input.chose('build', 'site');
    // A carpenter makes a laminated top from the same plywood and laminate.
    final topOnSite = site && topId == 'laminate';
    final lengths = [
      ResultDetail('Base cabinets', formatLength(base)),
      if (upper > 0) ResultDetail('Wall cabinets', formatLength(upper)),
    ];
    final topDetails = [
      if (top != null) ...[
        ResultDetail(
          '${top.label} top, ${formatLength(base)} × ${formatLength(depth)}',
          formatArea(roundUp(base * depth)),
        ),
        if (splash > 0)
          ResultDetail(
            'Backsplash, ${formatLength(base)} × ${formatLength(splash)}',
            '+${formatArea(roundUp(base * splash))}',
          ),
      ],
    ];
    final countertop = [
      if (top != null && !topOnSite)
        buy(top.key, topArea, work: InteriorsWork.countertop),
    ];
    final works = [
      WorkQuantity(
        site ? InteriorsWork.cabinetsBuilt : InteriorsWork.cabinets,
        _hundredths(metres),
      ),
      if (top != null)
        WorkQuantity(InteriorsWork.countertop, _hundredths(base)),
    ];

    if (!site) {
      return CalcResult(
        label: 'Base cabinets, made to order',
        quantity: roundUp(base),
        unit: QuantityUnit.metres,
        unitPrice: input['lmPrice'],
        itemKey: 'cabinet_base_lm',
        details: [
          ...lengths,
          ...topDetails,
          if (top != null)
            ResultDetail('Countertop to order', formatArea(roundUp(topArea))),
        ],
        companions: [
          if (upper > 0) buy('cabinet_upper_lm', upper),
          ...countertop,
        ],
        note:
            'Ask whether the price per metre includes installation and the '
            'countertop. Sink and cooktop cut-outs are often charged '
            'separately.',
        works: works,
      );
    }

    final panels =
        base * _basePanels + upper * _wallPanels + (topOnSite ? topArea : 0);
    final sheets = ceilCount(panels * (1 + _cutWaste) / sheetArea);
    final laminate = metres * _laminateFaces + (topOnSite ? topArea : 0);
    final edge = metres * _edgePerMetre + (topOnSite ? base : 0);
    final doors = ceilCount(base / _doorWidth) + ceilCount(upper / _doorWidth);
    final drawers = ceilCount(base / _drawerEvery);
    return CalcResult(
      label: 'Cabinets built on site, marine plywood 18 mm',
      quantity: sheets.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['sheetPrice'],
      itemKey: marinePlywoodKey('18'),
      details: [
        ...lengths,
        ...topDetails,
        ResultDetail('18 mm panels', formatArea(roundUp(panels))),
        ResultDetail(
          'Sheets with 15% cutting waste',
          formatCount(sheets, 'sheet'),
        ),
        ResultDetail('Doors, 2 hinges each', '$doors'),
        ResultDetail('Drawers, 1 per metre of base', '$drawers'),
      ],
      companions: [
        buy(
          marinePlywoodKey('6'),
          metres * _backPanels * (1 + _cutWaste) / sheetArea,
          label: 'Marine plywood 6 mm (¼") 4×8, for backs',
        ),
        buy('hpl_laminate', laminate * (1 + _cutWaste) / sheetArea),
        buy('contact_cement', laminate * _contactCement),
        buy('edge_band', edge * (1 + _edgeWaste) / _edgeRoll),
        buy('cabinet_hinge', (doors * _hingesPerDoor).toDouble()),
        buy('drawer_slide', drawers.toDouble()),
        buy('cabinet_handle', (doors + drawers).toDouble()),
        buy('nails', metres * _cabinetNails),
        ...countertop,
      ],
      note: topOnSite
          ? 'The laminated top is built from the same plywood and laminate.'
          : null,
      works: works,
    );
  },
  definitions: const [
    InfoSection(
      'Base and wall cabinets',
      'Base cabinets stand on the floor under the counter, about 0.90 m '
          'high with the top. Wall (upper) cabinets hang above, about 0.35 m '
          'deep. Measure each along the wall; for an L-shaped kitchen add '
          'both legs.',
    ),
    InfoSection(
      'Made to order or built on site',
      'Fabricators build modular cabinets in their shop, price them per '
          'metre and install them. On site, a carpenter builds them from '
          '18 mm marine plywood with 6 mm backs, faced with laminate.',
    ),
    InfoSection(
      'Countertop',
      'Granite, quartz and solid surface tops are cut by a fabricator and '
          'priced here per m². A laminated top is plywood faced with '
          'laminate. Kitchen counters are about 0.60 m deep, vanities about '
          '0.50 m.',
    ),
    InfoSection(
      'Backsplash',
      'A strip of the countertop material up the wall behind the counter: '
          '0.10 m, or 0.60 m up to the wall cabinets.',
    ),
    InfoSection(
      'Hardware',
      'Concealed hinges with a 35 mm cup, two per door; drawer slides sold '
          'in pairs; one handle per door and drawer.',
    ),
  ],
  solution: const [
    InfoSection(
      'Countertop',
      'The base cabinet length times the depth plus the backsplash height.',
      formula: 'area = base length × (depth + backsplash)',
    ),
    InfoSection(
      'Made to order',
      'Metres of base cabinet × the price per metre. Wall cabinets and the '
          'countertop are priced from your price list.',
      formula: 'cost = base metres × price + wall cabinets + countertop',
    ),
    InfoSection(
      'Plywood, built on site',
      'A metre of base cabinet takes about 3.5 m² of 18 mm panels (bottom, '
          'sides, shelf, doors, rails, toe kick and a drawer) and a metre of '
          'wall cabinet about 2.2 m². Each metre has a 0.75 m² back of 6 mm '
          'plywood. A laminated top adds its area. 15% is added for cutting.',
      formula:
          '18 mm sheets = round up((base × 3.5 + wall × 2.2 + laminated top)'
          ' × 1.15 ÷ 2.977)\n'
          '6 mm sheets = round up((base + wall) × 0.75 × 1.15 ÷ 2.977)',
    ),
    InfoSection(
      'Laminate, glue and edge band',
      'About 1 m² of laminate on the exposed faces of each metre of '
          'cabinet, plus a laminated top; 0.4 L of contact cement per m² of '
          'laminate; 9 m of edge band per metre of cabinet.',
      formula:
          'laminate = round up(((base + wall) + laminated top) × 1.15 ÷ '
          '2.977)\n'
          'contact cement = round up(laminate m² × 0.4) L\n'
          'edge band = round up(((base + wall) × 9 + laminated top length)'
          ' × 1.10 ÷ 50) rolls',
    ),
    InfoSection(
      'Hardware',
      'Doors about 0.50 m wide, with 2 hinges each; one drawer per metre of '
          'base cabinet; one handle per door and drawer; 0.2 kg of nails per '
          'metre.',
      formula:
          'doors = round up(base ÷ 0.50) + round up(wall ÷ 0.50)\n'
          'hinges = doors × 2\n'
          'drawer slides = round up(base ÷ 1.0) pairs\n'
          'handles = doors + drawers',
    ),
    InfoSection(
      'Cost',
      'Metres of base cabinet × the price per metre, or sheets of 18 mm '
          'plywood × the price per sheet. Everything else is priced from '
          'your price list and added to the total.',
      formula: 'cost = quantity × price + other materials',
    ),
  ],
  references: const [
    'Architectural Graphic Standards: kitchen counters about 0.90 m high '
        'and 0.60 m deep, wall cabinets 0.30–0.35 m deep',
    'NKBA Kitchen Planning Guidelines',
    'Blum, CLIP top concealed hinge planning: 2 hinges for doors up to '
        'about 0.90 m high',
  ],
);

/// The calculators.
final List<MaterialSpec> interiorsMaterials = [
  waterproofing,
  flooring,
  cabinets,
];
