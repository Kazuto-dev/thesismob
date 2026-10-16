// Earthworks, concrete stairs and steel works.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'architectural.dart'
    show
        litresPerGallon,
        paintWaste,
        primerCoverage,
        thinnerCleanup,
        thinnerShare;
import 'calc_helpers.dart';
import 'concrete.dart' show coverSlab, formNails, slabFrameLumber, stockBars;
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';
import 'work_items.dart';

/// Keys of the work items these calculators add to the bill of
/// quantities.
abstract final class SiteWork {
  static const excavationHard = 'excavation_hard';
  static const stairsConcrete = 'stairs_concrete';
  static const steelRailing = 'steel_railing';
  static const steelTruss = 'steel_truss';
}

/// Price book items these calculators buy.
final List<Item> siteworkItems = [
  const Item(
    'soil_disposal',
    'Hauling of excess soil, 6-wheeler truck',
    'm³',
    ItemGroup.other,
    step: 0.5,
    price: 650,
    estimate: true,
  ),
  const Item(
    'square_tube_1',
    'Square steel tube 1" × 1" × 1.2 mm, 6 m',
    'length',
    ItemGroup.steel,
    plural: 'lengths',
    price: 400,
    estimate: true,
  ),
  const Item(
    'square_tube_1_5',
    'Square steel tube 1½" × 1½" × 1.2 mm, 6 m',
    'length',
    ItemGroup.steel,
    plural: 'lengths',
    price: 600,
    estimate: true,
  ),
  const Item(
    'angle_bar_1_5',
    'Angle bar 1½" × 1½" × 3/16", 6 m',
    'length',
    ItemGroup.steel,
    plural: 'lengths',
    price: 950,
    estimate: true,
  ),
  const Item(
    'angle_bar_2',
    'Angle bar 2" × 2" × 3/16", 6 m',
    'length',
    ItemGroup.steel,
    plural: 'lengths',
    price: 1300,
    estimate: true,
  ),
  const Item(
    'gusset_plate',
    'Gusset plate 150 × 150 × 6 mm, cut',
    'pc',
    ItemGroup.steel,
    plural: 'pcs',
    price: 90,
    estimate: true,
  ),
  const Item(
    'base_plate',
    'Base plate 100 × 100 × 6 mm, drilled',
    'pc',
    ItemGroup.steel,
    plural: 'pcs',
    price: 60,
    estimate: true,
  ),
  const Item(
    'anchor_bolt_10',
    'Expansion anchor ⅜" × 3"',
    'pc',
    ItemGroup.steel,
    plural: 'pcs',
    price: 30,
    estimate: true,
  ),
  const Item(
    'anchor_bolt_16',
    'Anchor bolt 16 mm × 300 mm, nut and washer',
    'pc',
    ItemGroup.steel,
    plural: 'pcs',
    price: 90,
    estimate: true,
  ),
  const Item(
    'welding_rod',
    'Welding rod E6013, 2.5–3.2 mm',
    'kg',
    ItemGroup.steel,
    price: 200,
    estimate: true,
  ),
  const Item(
    'red_oxide_primer',
    'Red oxide metal primer, 4 L',
    'gallon',
    ItemGroup.paint,
    plural: 'gallons',
    price: 780,
    estimate: true,
  ),
];

/// Work items these calculators measure.
const siteworkWorkItems = <WorkItem>[
  WorkItem(
    SiteWork.excavationHard,
    'Structure excavation, hard soil or soft rock, by hand',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, helpers: 1),
    output: 1.5,
    reference: '103',
  ),
  WorkItem(
    SiteWork.stairsConcrete,
    'Structural concrete, stairs',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(
      foreman: 0.5,
      skilled: 1,
      helpers: 4,
      equipment: {DailyRates.mixer: 1, DailyRates.vibrator: 1},
    ),
    output: 2,
    reference: '900',
  ),
  WorkItem(
    SiteWork.steelRailing,
    'Steel tube railing, fabricated and installed',
    'm',
    trade: MaterialCategory.structural,
    crew: Crew(skilled: 1, helpers: 1, equipment: {DailyRates.welding: 1}),
    output: 6,
  ),
  WorkItem(
    SiteWork.steelTruss,
    'Steel roof trusses, fabricated and erected',
    'kg',
    trade: MaterialCategory.structural,
    crew: Crew(
      foreman: 0.2,
      skilled: 1,
      helpers: 2,
      equipment: {DailyRates.welding: 1},
    ),
    output: 150,
    reference: '1047',
  ),
];

/// The calculators.
final List<MaterialSpec> siteworkMaterials = [
  earthworks,
  stairs,
  railing,
  trusses,
];

/// Rounds a measured quantity to [decimals] places.
double _rounded(double value, int decimals) {
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).roundToDouble() / factor;
}

// ---------------------------------------------------------------------------
// Earthworks

/// A 6-wheeler dump truck carries about 6 m³ of loose soil.
const truckLoad = 6.0;

final earthworks = MaterialSpec(
  id: 'earthworks',
  name: 'Earthworks',
  category: MaterialCategory.structural,
  icon: Icons.landscape_outlined,
  blurb: 'Excavation for footings and trenches, backfill and soil to haul',
  keywords: const [
    'excavation',
    'earthworks',
    'hukay',
    'paghuhukay',
    'backfill',
    'tambak',
    'lupa',
    'soil',
    'trench',
    'kanal',
    'hauling',
    'tapon ng lupa',
    'gravel bedding',
  ],
  numbers: [
    const NumberField(
      id: 'count',
      label: 'Number of pits or trenches',
      unit: 'pcs',
      hint: 'Footing pits of the same size, or wall trench runs',
      integer: true,
      max: 10000,
    ),
    const NumberField(
      id: 'length',
      label: 'Footing or trench length',
      unit: 'm',
      hint: 'Of the footing itself, without working space',
      typical: (min: 0.3, max: 100),
      max: 1000,
    ),
    const NumberField(
      id: 'width',
      label: 'Footing or trench width',
      unit: 'm',
      typical: (min: 0.2, max: 6),
      max: 50,
    ),
    const NumberField(
      id: 'depth',
      label: 'Excavation depth',
      unit: 'm',
      hint: 'From the ground to the bottom, gravel bed included',
      typical: (min: 0.2, max: 4),
      max: 20,
    ),
    NumberField(
      id: 'structure',
      label: 'Volume of the structure below ground',
      unit: 'm³',
      hint: 'All pits: footings and columns below the ground line',
      max: 100000,
      visibleWhen: (s) => s['fill'] != 'haul',
    ),
    const NumberField(
      id: 'price',
      label: 'Price per m³ to haul away',
      unit: '₱',
      hint: 'Loose soil, by 6-wheeler truck',
      isPrice: true,
      max: 100000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'fill',
      label: 'Excavated soil',
      initial: 'backfill',
      leading: true,
      helper: 'Soil not needed for backfill is hauled away',
      options: [
        ChoiceOption('backfill', 'Backfill around the structure'),
        ChoiceOption('haul', 'Haul all of it away'),
      ],
    ),
    ChoiceField(
      id: 'soil',
      label: 'Soil',
      initial: 'common',
      helper: 'Hard soil needs a pick or a jackhammer and swells more',
      options: [
        ChoiceOption('common', 'Common soil', 1.25),
        ChoiceOption('hard', 'Hard soil or soft rock', 1.40),
      ],
    ),
    ChoiceField(
      id: 'space',
      label: 'Working space',
      initial: '0.3',
      helper: 'Room around the footing to set bars and forms',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.3', '0.30 m each side', 0.30),
        ChoiceOption('0.5', '0.50 m each side', 0.50),
      ],
    ),
    ChoiceField(
      id: 'bedding',
      label: 'Gravel bed',
      initial: '0',
      helper: 'Compacted gravel under the footing',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.05', '5 cm', 0.05),
        ChoiceOption('0.1', '10 cm', 0.10),
      ],
    ),
  ],
  priceRef: (_) => const PriceRef('soil_disposal'),
  compute: (input) {
    final count = input['count'].round();
    final length = input['length'];
    final width = input['width'];
    final depth = input['depth'];
    final space = input.choice('space').value;
    final soil = input.choice('soil');
    final hard = soil.id == 'hard';
    final haulAll = input.chose('fill', 'haul');
    final bed = input.choice('bedding').value;
    if (bed >= depth) {
      throw ArgumentError('The excavation must be deeper than its gravel bed');
    }

    final pitLength = length + 2 * space;
    final pitWidth = width + 2 * space;
    final excavated = count * pitLength * pitWidth * depth;
    final bedding = count * length * width * bed;
    final structure = haulAll ? 0.0 : input['structure'];
    if (structure + bedding > excavated + 1e-9) {
      throw ArgumentError('The structure must be smaller than the excavation');
    }
    final backfill = haulAll ? 0.0 : excavated - structure - bedding;
    final excess = excavated - backfill;
    final loose = excess * soil.value;
    // Hauling is paid by the half m³ of loose soil, like sand.
    final haul = ceilCount(loose * 2) / 2;

    return CalcResult(
      label:
          'Excess soil, ${formatCount(count, 'pit')} '
          '${formatNumber(length)} × ${formatNumber(width)} m, '
          '${formatNumber(depth)} m deep',
      quantity: haul,
      unit: QuantityUnit.cubicMetres,
      unitPrice: input['price'],
      itemKey: 'soil_disposal',
      details: [
        ResultDetail(
          'Pit with working space',
          '${formatNumber(pitLength)} × ${formatNumber(pitWidth)} × '
              '${formatNumber(depth)} m',
        ),
        ResultDetail('Excavation, in place', formatVolume(roundUp(excavated))),
        if (!haulAll) ...[
          ResultDetail('Less the structure', '−${formatVolume(structure)}'),
          if (bedding > 0)
            ResultDetail(
              'Less the gravel bed',
              '−${formatVolume(roundUp(bedding, 3))}',
            ),
          ResultDetail('Backfill', formatVolume(_rounded(backfill, 2))),
        ],
        ResultDetail('Excess soil, in place', formatVolume(roundUp(excess))),
        ResultDetail(
          'Swell, ${soil.label.toLowerCase()}',
          '× ${formatNumber(soil.value)}',
        ),
        ResultDetail('Loose soil to haul', formatVolume(roundUp(loose))),
        ResultDetail(
          '6-wheeler loads of about 6 m³',
          formatCount(ceilCount(loose / truckLoad), 'load'),
        ),
      ],
      companions: [
        if (bedding > 0)
          buy('gravel_bedding', bedding, work: Work.gravelBedding),
      ],
      note:
          'Backfill is placed and compacted in layers with the excavated '
          'soil. Swell factors vary with the soil: ask the hauler how they '
          'count a load.',
      works: [
        WorkQuantity(
          hard ? SiteWork.excavationHard : Work.excavation,
          _rounded(excavated, 3),
        ),
        if (_rounded(backfill, 3) > 0)
          WorkQuantity(Work.backfill, _rounded(backfill, 3)),
        if (_rounded(bedding, 3) > 0)
          WorkQuantity(Work.gravelBedding, _rounded(bedding, 3)),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Pits and trenches',
      'Enter the size of the footing or wall footing that goes in each pit, '
          'and how deep the pit is dug. Isolated footings are dug as pits; '
          'wall footings as long trenches. Enter pits of the same size '
          'together.',
    ),
    InfoSection(
      'Working space',
      'Workers need room around a footing to tie bars and set forms, so '
          'the pit is dug wider than the footing on every side. Footings '
          'cast against firm soil may need none.',
    ),
    InfoSection(
      'Structure below ground',
      'The concrete that will stay in the ground: footings, wall footings, '
          'tie beams and the part of the columns below the ground line, in '
          'm³. The Footings and Columns calculators give their volumes. The '
          'soil it displaces cannot go back and is hauled away.',
    ),
    InfoSection(
      'Swell',
      'Dug soil loosens and takes up more room than it did in the ground. '
          'Common soil swells about 25%; hard clay, hardpan and soft rock '
          'about 40%. Trucks carry loose soil, so the soil to haul is the '
          'in-place volume times the swell factor.',
    ),
    InfoSection(
      'Hard soil or soft rock',
      'Soil that needs a pick, a crowbar or a jackhammer. A worker digs '
          'about half as much of it in a day as of common soil.',
    ),
  ],
  solution: const [
    InfoSection(
      'Excavation',
      'The pit is the footing size plus the working space on each side, '
          'times the depth.',
      formula:
          'excavation = count × (length + 2 × space) × '
          '(width + 2 × space) × depth',
    ),
    InfoSection(
      'Gravel bed',
      'When chosen, a gravel bed of the chosen thickness covers the bottom '
          'of each footing.',
      formula: 'gravel bed = count × length × width × thickness',
    ),
    InfoSection(
      'Backfill',
      'Everything dug that the structure and the gravel bed do not fill is '
          'backfilled with the excavated soil. When all soil is hauled away '
          'there is no backfill.',
      formula: 'backfill = excavation − structure − gravel bed',
    ),
    InfoSection(
      'Soil to haul',
      'The rest of the soil is hauled away, loosened by the swell factor '
          'and rounded up to the half m³.',
      formula:
          'excess in place = excavation − backfill\n'
          'loose soil = excess × 1.25 (common) or 1.40 (hard)\n'
          'loads = round up(loose soil ÷ 6 m³)',
    ),
  ],
  references: const [
    'DPWH Standard Specifications, Item 103 (Structure Excavation) and '
        'Item 104 (Embankment)',
    'R. L. Peurifoy et al., Construction Planning, Equipment, and Methods, '
        'soil swell factors',
    'Max B. Fajardo Jr., Simplified Construction Estimate',
  ],
);

// ---------------------------------------------------------------------------
// Concrete stairs

/// Distribution bars across the stair: 10 mm at 25 cm.
const stairDistributionMm = 10;
const stairDistributionSpacing = 0.25;

/// Main bars run into the support at each end by 40 bar diameters, and
/// bars longer than 6 m are lapped by as much.
const stairAnchorage = 40;

/// Metres of bar placed in [pieces] bars each [length] metres long, with
/// the laps [stockBars] adds where a bar longer than 6 m is spliced.
double _barMetres(int pieces, double length, double lap) {
  if (pieces <= 0 || length <= 0) return 0;
  if (length <= rebarStockLength) return pieces * length;
  final splices = ceilCount(length / rebarStockLength) - 1;
  return pieces * (length + splices * lap);
}

final stairs = MaterialSpec(
  id: 'stairs',
  name: 'Concrete Stairs',
  category: MaterialCategory.structural,
  icon: Icons.stairs_outlined,
  blurb: 'A straight reinforced concrete stair, with bars and forms',
  keywords: const [
    'stairs',
    'staircase',
    'hagdan',
    'hagdanan',
    'baitang',
    'steps',
    'landing',
    'concrete',
    'rebar',
  ],
  numbers: [
    const NumberField(
      id: 'width',
      label: 'Stair width',
      unit: 'm',
      hint: 'Usually 0.90–1.20 m',
      typical: (min: 0.6, max: 3),
      max: 10,
    ),
    const NumberField(
      id: 'height',
      label: 'Floor-to-floor height',
      unit: 'm',
      hint: 'From the floor below to the floor above',
      typical: (min: 1, max: 6),
      max: 20,
    ),
    NumberField(
      id: 'landing',
      label: 'Landing length',
      unit: 'm',
      hint: 'Along the stair, usually at least the stair width',
      typical: (min: 0.6, max: 4),
      max: 20,
      visibleWhen: (s) => s['landings'] == 'one',
    ),
    const NumberField(
      id: 'price',
      label: 'Price per bag of cement',
      unit: '₱',
      hint: '40 kg bag',
      isPrice: true,
      max: 100000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'landings',
      label: 'Landing',
      initial: 'none',
      leading: true,
      options: [
        ChoiceOption('none', 'None, one straight flight'),
        ChoiceOption('one', 'One landing between two flights'),
      ],
    ),
    const ChoiceField(
      id: 'riser',
      label: 'Riser height, at most',
      initial: '0.175',
      helper: 'The Building Code allows up to 20 cm',
      options: [
        ChoiceOption('0.175', '17.5 cm', 0.175),
        ChoiceOption('0.18', '18 cm', 0.18),
        ChoiceOption('0.2', '20 cm', 0.20),
      ],
    ),
    const ChoiceField(
      id: 'tread',
      label: 'Tread',
      initial: '0.25',
      helper: 'The Building Code asks for at least 25 cm',
      options: [
        ChoiceOption('0.25', '25 cm', 0.25),
        ChoiceOption('0.275', '27.5 cm', 0.275),
        ChoiceOption('0.3', '30 cm', 0.30),
      ],
    ),
    const ChoiceField(
      id: 'waist',
      label: 'Waist slab thickness',
      initial: '0.15',
      helper: 'The slab under the steps; follow the plans',
      options: [
        ChoiceOption('0.125', '125 mm', 0.125),
        ChoiceOption('0.15', '150 mm', 0.15),
        ChoiceOption('0.2', '200 mm', 0.20),
      ],
    ),
    ChoiceField(
      id: 'class',
      label: 'Concrete mix',
      initial: 'A',
      helper: 'Fajardo site-mix classes: cement : sand : gravel',
      options: [
        for (final m in concreteMixes)
          ChoiceOption(m.id, '${m.label}, ${m.ratio}', m.cement),
      ],
    ),
    const ChoiceField(
      id: 'bar',
      label: 'Main bar size',
      initial: '12',
      options: [
        ChoiceOption('10', '10 mm', 10),
        ChoiceOption('12', '12 mm', 12),
      ],
    ),
    const ChoiceField(
      id: 'spacing',
      label: 'Main bar spacing',
      initial: '0.15',
      helper: 'Follow the plans',
      options: [
        ChoiceOption('0.1', '10 cm', 0.10),
        ChoiceOption('0.125', '12.5 cm', 0.125),
        ChoiceOption('0.15', '15 cm', 0.15),
        ChoiceOption('0.2', '20 cm', 0.20),
      ],
    ),
    const ChoiceField(
      id: 'plywood',
      label: 'Form plywood',
      initial: '12',
      options: [
        ChoiceOption('6', '6 mm (¼") marine'),
        ChoiceOption('12', '12 mm (½") marine'),
      ],
    ),
    const ChoiceField(
      id: 'reuse',
      label: 'Forms used',
      initial: '2',
      helper: 'Stair forms are cut to fit the steps, so 2 uses is usual',
      options: [
        ChoiceOption('1', 'Once', 1),
        ChoiceOption('2', '2 times', 2),
        ChoiceOption('3', '3 times', 3),
        ChoiceOption('4', '4 times', 4),
      ],
    ),
    wasteField(
      initial: '5',
      helper: 'Spillage and uneven ground',
      percents: const [0, 5, 10],
    ),
  ],
  priceRef: (_) => const PriceRef('cement_40kg'),
  compute: (input) {
    final width = input['width'];
    final height = input['height'];
    final hasLanding = input.chose('landings', 'one');
    final landing = hasLanding ? input['landing'] : 0.0;
    final tread = input.choice('tread').value;
    final waist = input.choice('waist').value;
    final risers = ceilCount(height / input.choice('riser').value);
    if (risers < (hasLanding ? 4 : 2)) {
      throw ArgumentError(
        hasLanding
            ? 'A stair with a landing must rise at least four steps'
            : 'A stair must rise at least two steps',
      );
    }
    if (width <= 2 * coverSlab) {
      throw ArgumentError('The stair must be wider than its bar cover');
    }
    final riser = height / risers;
    // The landing takes the place of one tread.
    final treads = risers - (hasLanding ? 2 : 1);
    final going = treads * tread;
    final slope = math.sqrt(going * going + height * height);

    final waistVolume = slope * width * waist;
    final stepVolume = 0.5 * riser * tread * width * treads;
    final landingVolume = landing * width * waist;
    final volume = waistVolume + stepVolume + landingVolume;
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final mixed = volume * (1 + waste);
    final cement = ceilCount(mixed * mix.cement);

    final barMm = int.parse(input.choice('bar').id);
    final spacing = input.choice('spacing').value;
    final lap = stairAnchorage * barMm / 1000;
    final mainLength = slope + landing + 2 * lap;
    final mainCount = ((width - 2 * coverSlab) / spacing + 1e-9).floor() + 1;
    final mainBars = stockBars(mainCount, mainLength, lap);
    const distMm = stairDistributionMm;
    final distLap = stairAnchorage * distMm / 1000;
    final distLength = width - 2 * coverSlab;
    final distCount =
        ((slope + landing) / stairDistributionSpacing + 1e-9).floor() + 1;
    final distBars = stockBars(distCount, distLength, distLap);
    final rebarKg =
        _barMetres(mainCount, mainLength, lap) * rebarKgPerMetre(barMm) +
        _barMetres(distCount, distLength, distLap) * rebarKgPerMetre(distMm);
    final ties = mainCount * distCount;

    // The soffit, every riser face and both sides of the flight, whose
    // profile is the concrete volume divided by the width.
    final soffit = (slope + landing) * width;
    final riserFaces = height * width;
    final sides = 2 * volume / width;
    final formArea = soffit + riserFaces + sides;
    final uses = input.choice('reuse').value;
    final sheets = math.max(1, ceilCount(formArea / sheetFormArea / uses));
    final plywood = input.choice('plywood').id;

    return CalcResult(
      label:
          'Concrete stair ${formatNumber(width)} m wide, '
          '${formatNumber(height)} m high, ${mix.label}',
      quantity: cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ResultDetail(
          'Risers of ${formatNumber(_rounded(riser * 100, 1))} cm',
          '$risers',
        ),
        ResultDetail('Treads of ${formatNumber(tread * 100)} cm', '$treads'),
        if (hasLanding) ResultDetail('Landing', formatLength(landing)),
        ResultDetail(
          'Length along the slope',
          formatLength(_rounded(slope, 2)),
        ),
        ResultDetail('Concrete volume', formatVolume(roundUp(volume, 3))),
        if (waste > 0)
          ResultDetail(
            'With ${formatPercent(waste)} waste',
            formatVolume(roundUp(mixed, 3)),
          ),
        ResultDetail(
          '${mix.label} cement, ${formatNumber(mix.cement)} bags per m³',
          formatCount(cement, 'bag'),
        ),
        ResultDetail(
          'Main bars, $mainCount × $barMm mm, '
          '${formatLength(roundUp(mainLength))} each',
          formatCount(mainBars, 'bar'),
        ),
        ResultDetail(
          'Distribution bars, $distCount × $distMm mm, '
          '${formatLength(roundUp(distLength))} each',
          formatCount(distBars, 'bar'),
        ),
        ResultDetail('Form contact area', formatArea(roundUp(formArea))),
        if (uses > 1) ResultDetail('Forms reused', '× ${formatNumber(uses)}'),
      ],
      companions: [
        buy('sand', mixed * mix.sand),
        buy('gravel', mixed * mix.gravel),
        if (barMm == distMm)
          buy(rebarKey(barMm), (mainBars + distBars).toDouble())
        else ...[
          buy(rebarKey(barMm), mainBars.toDouble()),
          buy(rebarKey(distMm), distBars.toDouble()),
        ],
        buy('tie_wire', ties * tieWirePerTie(barMm) / tieWireMetresPerKg),
        buy(marinePlywoodKey(plywood), sheets.toDouble()),
        buy('coco_lumber', sheets * slabFrameLumber),
        buy('nails', formArea * formNails),
      ],
      note:
          'Extra top bars at the supports, nosing bars and the beam or '
          'footing at the foot of the stair are not counted. Bars and '
          'thicknesses must follow the structural plans.',
      works: [
        WorkQuantity(SiteWork.stairsConcrete, _rounded(volume, 3)),
        WorkQuantity(Work.rebar, _rounded(rebarKg, 2)),
        WorkQuantity(Work.formwork, _rounded(formArea, 2)),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Straight stair',
      'A reinforced concrete flight that rises from one floor to the next '
          'in a straight line, optionally broken by one landing halfway. '
          'The steps sit on an inclined slab, the waist slab.',
    ),
    InfoSection(
      'Risers and treads',
      'The riser is the height of each step; the tread is its depth. Under '
          'the National Building Code (PD 1096) a step may rise at most '
          '20 cm and a tread must be at least 25 cm deep. The calculator '
          'uses as many risers as it takes to stay under the chosen height, '
          'all equal.',
    ),
    InfoSection(
      'Waist slab and bars',
      'The main bars run along the slope in the bottom of the waist slab '
          'and into the supports at each end; 10 mm distribution bars cross '
          'them every 25 cm. Typical house plans use 12 mm main bars at '
          '15 cm in a 150 mm waist. Always follow the plans.',
    ),
    InfoSection(
      'Landing',
      'A flat slab, as thick as the waist slab, where the stair rests '
          'halfway. It takes the place of one tread.',
    ),
  ],
  solution: const [
    InfoSection(
      'Steps',
      'Divide the height by the largest riser allowed and round up; every '
          'riser is then the height divided by that count. A straight '
          'flight has one tread fewer than risers; with a landing, two '
          'fewer.',
      formula:
          'risers = round up(height ÷ riser)\n'
          'treads = risers − 1 (or − 2 with a landing)\n'
          'slope length = √((treads × tread)² + height²)',
    ),
    InfoSection(
      'Concrete',
      'The inclined waist slab, the triangle of each step above it and the '
          'landing, with the waste allowance, times the mix factors.',
      formula:
          'volume = slope × width × waist + ½ × riser × tread × width × '
          'treads + landing × width × waist\n'
          'cement = round up(volume × (1 + waste) × bags per m³)',
    ),
    InfoSection(
      'Bars',
      'Main bars at the chosen spacing across the width, inside 20 mm of '
          'cover, each the slope length plus the landing plus 40 bar '
          'diameters into the support at each end. 10 mm distribution bars '
          'every 25 cm along the slope. Tie wire at each crossing.',
      formula:
          'main bars = round down((width − 0.04) ÷ spacing) + 1\n'
          'main bar = slope + landing + 2 × 40 × d\n'
          'distribution bars = round down((slope + landing) ÷ 0.25) + 1',
    ),
    InfoSection(
      'Forms',
      'Plywood covers the soffit, every riser face and both sides of the '
          'flight. The soffit is shored like a suspended slab: 28.8 bd ft '
          'of coco lumber per sheet and 0.20 kg of nails per m². Stair '
          'forms are cut to fit the steps, so they are shared by 2 uses by '
          'default rather than the 3 of other forms.',
      formula:
          'form area = (slope + landing) × width + height × width + '
          '2 × volume ÷ width\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'National Building Code of the Philippines (PD 1096), Rule XII, '
        'Sec. 1207 (stairs)',
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2 and '
        'forms tables',
    'NSCP 2015, Table 420.6.1.3.1 (concrete cover)',
  ],
);

// ---------------------------------------------------------------------------
// Steel railing and trusses

/// Square steel tubes 1.2 mm thick: side in metres, mass per metre and
/// price book item.
typedef _Tube = ({String label, double side, double kgPerMetre, String key});

const _tubes = <String, _Tube>{
  '1': (label: '1" × 1"', side: 0.0254, kgPerMetre: 0.91, key: 'square_tube_1'),
  '1.5': (
    label: '1½" × 1½"',
    side: 0.0381,
    kgPerMetre: 1.39,
    key: 'square_tube_1_5',
  ),
};

/// Railing posts are always 1½" × 1½" tube.
const _postTube = '1.5';

/// The bottom rail sits 10 cm above the floor; the rails take about 5 cm,
/// so balusters are the railing height less 15 cm.
const railBottomClearance = 0.15;

/// Steel tube and angle bar are sold in 6 m lengths, bought with 5% for
/// cutting waste.
const steelStockLength = 6.0;
const steelWaste = 0.05;

/// About one 2.5 mm rod (0.02 kg) welds one tube joint all round.
const railingRodPerJoint = 0.02;

/// Welding rods for a truss: about 2% of the weight of steel.
const trussRodPerKg = 0.02;

/// Anchors per railing post and per truss.
const railingAnchorsPerPost = 4;
const trussAnchors = 4;

/// One coat of enamel covers about 25 m² per 4 L, like primer.
const enamelCoverage = 25.0;

/// Weight of a 150 × 150 × 6 mm gusset plate, and both its faces.
const gussetKg = 0.15 * 0.15 * 0.006 * 7850;
const gussetPaintArea = 2 * 0.15 * 0.15;

/// Howe truss panels are at most 1.2 m wide.
const trussPanelWidth = 1.2;

/// Stock lengths to buy for [metres] of tube or angle, with 5% waste.
int _steelLengths(double metres) =>
    ceilCount(metres * (1 + steelWaste) / steelStockLength);

/// Primer and enamel, both thinned, for [area] m² of steel with one coat
/// of primer and [coats] of enamel, all going to the painting work.
List<Companion> _steelPaint(double area, int coats) {
  final primer = area / (primerCoverage / litresPerGallon) * (1 + paintWaste);
  final enamel =
      area * coats / (enamelCoverage / litresPerGallon) * (1 + paintWaste);
  return [
    buy('red_oxide_primer', primer / litresPerGallon, work: Work.painting),
    buy('paint_enamel', enamel / litresPerGallon, work: Work.painting),
    buy(
      'paint_thinner',
      (primer + enamel) * thinnerShare + thinnerCleanup,
      work: Work.painting,
    ),
  ];
}

final railing = MaterialSpec(
  id: 'railing',
  name: 'Steel Railing',
  category: MaterialCategory.structural,
  icon: Icons.fence_outlined,
  blurb: 'Stair or balcony railing of square steel tube',
  keywords: const [
    'railing',
    'rehas',
    'barandilya',
    'handrail',
    'hawakan',
    'balcony',
    'balkonahe',
    'tubular',
    'steel tube',
    'welding',
    'grills',
  ],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Railing length',
      unit: 'm',
      hint: 'Along the slope on stairs; add up all runs',
      typical: (min: 0.5, max: 100),
      max: 1000,
    ),
    NumberField(
      id: 'price',
      label: 'Price per 6 m length',
      unit: '₱',
      hint: 'Of the rail tube',
      isPrice: true,
      max: 100000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'height',
      label: 'Railing height',
      initial: '1',
      helper: 'About 0.90 m on stairs, 1.0–1.1 m at balconies',
      options: [
        ChoiceOption('0.9', '0.90 m', 0.90),
        ChoiceOption('1', '1.00 m', 1.00),
        ChoiceOption('1.1', '1.10 m', 1.10),
      ],
    ),
    const ChoiceField(
      id: 'posts',
      label: 'Post spacing',
      initial: '1.2',
      helper: 'Posts are 1½" × 1½" tube on base plates',
      options: [
        ChoiceOption('1', '1.0 m', 1.0),
        ChoiceOption('1.2', '1.2 m', 1.2),
        ChoiceOption('1.5', '1.5 m', 1.5),
      ],
    ),
    const ChoiceField(
      id: 'infill',
      label: 'Infill',
      initial: 'balusters',
      options: [
        ChoiceOption('balusters', 'Vertical balusters'),
        ChoiceOption('rails', 'Horizontal rails'),
        ChoiceOption('none', 'None, top and bottom rails only'),
      ],
    ),
    ChoiceField(
      id: 'gap',
      label: 'Clear gap',
      initial: '0.1',
      helper: 'Small enough that a child cannot slip through',
      visibleWhen: (s) => s['infill'] != 'none',
      options: const [
        ChoiceOption('0.1', '10 cm', 0.10),
        ChoiceOption('0.12', '12 cm', 0.12),
      ],
    ),
    const ChoiceField(
      id: 'tube',
      label: 'Rail and infill tube',
      initial: '1',
      helper: 'Square steel tube, 1.2 mm thick',
      options: [ChoiceOption('1', '1" × 1"'), ChoiceOption('1.5', '1½" × 1½"')],
    ),
  ],
  priceRef: (s) => PriceRef(_tubes[s['tube']]?.key ?? 'square_tube_1'),
  compute: (input) {
    final length = input['length'];
    final height = input.choice('height').value;
    final infill = input.choice('infill').id;
    final tubeId = input.choice('tube').id;
    final tube = _tubes[tubeId]!;
    final post = _tubes[_postTube]!;
    final sameTube = tubeId == _postTube;

    final bays = ceilCount(length / input.choice('posts').value);
    final posts = bays + 1;
    final bay = length / bays;
    final infillHeight = height - railBottomClearance;
    var balusters = 0;
    var rails = 0;
    if (infill != 'none') {
      final gap = input.choice('gap').value;
      final pitch = gap + tube.side;
      if (infill == 'balusters') {
        final clear = bay - post.side;
        final perBay = clear <= gap ? 0 : ceilCount((clear - gap) / pitch);
        balusters = bays * perBay;
      } else {
        rails = infillHeight <= gap
            ? 0
            : ceilCount((infillHeight - gap) / pitch);
      }
    }

    final postMetres = posts * height;
    final railMetres = (2 + rails) * length;
    final balusterMetres = balusters * infillHeight;
    final tubeMetres =
        railMetres + balusterMetres + (sameTube ? postMetres : 0);
    final lengths = _steelLengths(tubeMetres);
    // Each post is welded to its base plate and to every rail; each
    // baluster at both ends.
    final joints = posts * (1 + 2 + rails) + 2 * balusters;
    final paintArea =
        (railMetres + balusterMetres) * 4 * tube.side +
        postMetres * 4 * post.side;

    return CalcResult(
      label:
          'Steel railing ${formatLength(length)}, '
          '${formatNumber(height)} m high, ${tube.label} tube',
      quantity: lengths.toDouble(),
      unit: QuantityUnit.lengths,
      unitPrice: input['price'],
      itemKey: tube.key,
      details: [
        ResultDetail('Posts, 1½" × 1½"', '$posts'),
        ResultDetail('Top and bottom rails', formatLength(2 * length)),
        if (rails > 0)
          ResultDetail('Middle rails', '$rails × ${formatLength(length)}'),
        if (balusters > 0)
          ResultDetail(
            'Balusters of ${formatLength(_rounded(infillHeight, 2))}',
            '$balusters',
          ),
        ResultDetail(
          '${tube.label} tube${sameTube ? ', posts included' : ''}',
          formatLength(roundUp(tubeMetres)),
        ),
        ResultDetail(
          'With 5% waste, in 6 m lengths',
          formatQuantity(lengths.toDouble(), QuantityUnit.lengths),
        ),
        ResultDetail('Welded joints', '$joints'),
        ResultDetail('Steel surface to paint', formatArea(roundUp(paintArea))),
      ],
      companions: [
        if (!sameTube) buy(post.key, _steelLengths(postMetres).toDouble()),
        buy('base_plate', posts.toDouble()),
        buy('anchor_bolt_10', (posts * railingAnchorsPerPost).toDouble()),
        buy('welding_rod', joints * railingRodPerJoint),
        ..._steelPaint(paintArea, 2),
      ],
      note:
          'Railing height and openings must follow the plans and the '
          'Building Code. Posts set on base plates with expansion anchors; '
          'posts cast into the slab need no plates.',
      works: [
        WorkQuantity(SiteWork.steelRailing, _rounded(length, 2)),
        WorkQuantity(Work.painting, _rounded(paintArea, 2), effort: 3),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Railing',
      'A welded steel guard along a stair or the open side of a balcony: '
          'posts on base plates, a top rail, a bottom rail and infill '
          'between them. Measure the railing along the slope on a stair.',
    ),
    InfoSection(
      'Infill and clear gap',
      'Vertical balusters or horizontal rails fill the space between the '
          'top and bottom rails. Building codes and good practice keep '
          'openings to about 10 cm so a small child cannot slip through.',
    ),
    InfoSection(
      'Square tube',
      'Hollow square steel tube ("tubular"), 1.2 mm thick, sold in 6 m '
          'lengths. Posts are 1½" × 1½"; rails and infill are the tube '
          'chosen.',
    ),
    InfoSection(
      'Paint',
      'One coat of red oxide primer and two coats of enamel, thinned with '
          'paint thinner.',
    ),
  ],
  solution: const [
    InfoSection(
      'Posts',
      'Bays as long as the post spacing at most; one more post than bays.',
      formula:
          'bays = round up(length ÷ spacing); posts = bays + 1\n'
          'post tube = posts × height',
    ),
    InfoSection(
      'Rails and infill',
      'A top and a bottom rail run the full length; the bottom rail is '
          '10 cm above the floor. Balusters fill each bay, between the '
          'posts, so that no gap is wider than chosen; horizontal rails do '
          'the same over the height.',
      formula:
          'infill height = height − 0.15 m\n'
          'balusters per bay = round up((bay − post − gap) ÷ (gap + tube))\n'
          'middle rails = round up((infill height − gap) ÷ (gap + tube))',
    ),
    InfoSection(
      'Tube to buy',
      'Add up the metres of each tube size, add 5% for cutting and round '
          'up to 6 m lengths.',
      formula: 'lengths = round up(metres × 1.05 ÷ 6)',
    ),
    InfoSection(
      'Welding, plates and anchors',
      'About 0.02 kg of rod (one 2.5 mm E6013 rod) for each welded joint: '
          'each post to its plate and to every rail, each baluster at both '
          'ends. A 100 × 100 × 6 mm base plate with 4 expansion anchors per '
          'post.',
      formula:
          'joints = posts × (3 + middle rails) + 2 × balusters\n'
          'welding rod = joints × 0.02 kg',
    ),
    InfoSection(
      'Paint',
      'The outside of every tube: 4 × side × metres. Primer and enamel '
          'each cover about 25 m² per 4 L coat, with 10% waste; thinner is '
          '1 part in 8 plus 0.5 L for cleaning.',
      formula:
          'primer = area ÷ 6.25 L per m² × 1.10\n'
          'enamel = area × 2 coats ÷ 6.25 × 1.10',
    ),
  ],
  references: const [
    'National Building Code of the Philippines (PD 1096), Rule XII '
        '(stairs and railings)',
    'ASTM A500 / PNS square steel tube dimensions and weights',
    'Boysen Red Oxide Primer and Quick Drying Enamel data sheets',
  ],
);

/// Equal-leg angle bars 3/16" thick: leg in metres, mass per metre
/// (AISC: 1.80 and 2.44 lb/ft) and price book item.
typedef _Angle = ({String label, double leg, double kgPerMetre, String key});

const _angles = <String, _Angle>{
  '1.5': (
    label: '1½" × 1½" × 3/16"',
    leg: 0.0381,
    kgPerMetre: 2.68,
    key: 'angle_bar_1_5',
  ),
  '2': (
    label: '2" × 2" × 3/16"',
    leg: 0.0508,
    kgPerMetre: 3.63,
    key: 'angle_bar_2',
  ),
};

final trusses = MaterialSpec(
  id: 'trusses',
  name: 'Steel Roof Trusses',
  category: MaterialCategory.structural,
  icon: Icons.roofing_outlined,
  blurb: 'Light angle-bar trusses for a house roof',
  keywords: const [
    'truss',
    'trusses',
    'kilo',
    'salo',
    'angle bar',
    'roof frame',
    'balangkas ng bubong',
    'welding',
    'steel',
  ],
  numbers: const [
    NumberField(
      id: 'span',
      label: 'Building span',
      unit: 'm',
      hint: 'Between the walls or beams the trusses sit on',
      typical: (min: 2, max: 15),
      max: 40,
    ),
    NumberField(
      id: 'length',
      label: 'Building length',
      unit: 'm',
      hint: 'Along the ridge, end wall to end wall',
      typical: (min: 2, max: 60),
      max: 500,
    ),
    NumberField(
      id: 'price',
      label: 'Price per 6 m length',
      unit: '₱',
      hint: 'Of the angle bar',
      isPrice: true,
      max: 100000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'spacing',
      label: 'Truss spacing',
      initial: '1.2',
      options: [
        ChoiceOption('1', '1.0 m', 1.0),
        ChoiceOption('1.2', '1.2 m', 1.2),
        ChoiceOption('1.5', '1.5 m', 1.5),
      ],
    ),
    ChoiceField(
      id: 'pitch',
      label: 'Roof pitch',
      initial: '4',
      helper: 'Rise per 12 of run, from the plans',
      options: [
        ChoiceOption('3', '3:12 (14°)', 3 / 12),
        ChoiceOption('4', '4:12 (18°)', 4 / 12),
        ChoiceOption('5', '5:12 (23°)', 5 / 12),
        ChoiceOption('6', '6:12 (27°)', 6 / 12),
      ],
    ),
    ChoiceField(
      id: 'overhang',
      label: 'Eave overhang',
      initial: '0.6',
      helper: 'Measured level from the wall; the top chords run over it',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('0.6', '0.60 m', 0.6),
        ChoiceOption('0.8', '0.80 m', 0.8),
        ChoiceOption('1', '1.00 m', 1.0),
      ],
    ),
    ChoiceField(
      id: 'angle',
      label: 'Angle bar',
      initial: '1.5',
      helper: 'All members of the size the plans give for the chords',
      options: [
        ChoiceOption('1.5', '1½" × 1½" × 3/16"'),
        ChoiceOption('2', '2" × 2" × 3/16"'),
      ],
    ),
  ],
  priceRef: (s) => PriceRef(_angles[s['angle']]?.key ?? 'angle_bar_1_5'),
  compute: (input) {
    final span = input['span'];
    final buildingLength = input['length'];
    final spacing = input.choice('spacing').value;
    final pitch = input.choice('pitch').value;
    final overhang = input.choice('overhang').value;
    final angle = _angles[input.choice('angle').id]!;

    final count = (buildingLength / spacing + 1e-9).floor() + 1;
    final topChords = 2 * (span / 2 + overhang) * math.sqrt(1 + pitch * pitch);
    // A Howe truss: panels at most 1.2 m wide, a vertical at every panel
    // point and a diagonal in every panel but the two at the ends.
    final half = ceilCount(span / 2 / trussPanelWidth);
    final panels = 2 * half;
    final panel = span / panels;
    var verticals = 0.0;
    var diagonals = 0.0;
    for (var i = 1; i <= half; i++) {
      final rise = pitch * i * panel;
      verticals += (i == half ? 1 : 2) * rise;
      if (i >= 2) diagonals += 2 * math.sqrt(panel * panel + rise * rise);
    }
    final webs = verticals + diagonals;
    final perTruss = topChords + span + webs;
    final metres = count * perTruss;
    final lengths = _steelLengths(metres);
    // One gusset at each joint: panels + 1 along the bottom chord and
    // panels − 1 along the top.
    final gussets = count * 2 * panels;
    final steelKg = metres * angle.kgPerMetre + gussets * gussetKg;
    final paintArea = metres * 4 * angle.leg + gussets * gussetPaintArea;

    return CalcResult(
      label:
          '${formatCount(count, 'truss', 'trusses')} '
          '${formatLength(span)} span, ${angle.label}',
      quantity: lengths.toDouble(),
      unit: QuantityUnit.lengths,
      unitPrice: input['price'],
      itemKey: angle.key,
      details: [
        ResultDetail(
          'Trusses at ${formatNumber(spacing)} m',
          formatCount(count, 'truss', 'trusses'),
        ),
        ResultDetail(
          'Top chords, with overhang',
          formatLength(_rounded(topChords, 2)),
        ),
        ResultDetail('Bottom chord', formatLength(span)),
        ResultDetail(
          'Webs, Howe, $panels panels of ${formatLength(_rounded(panel, 2))}',
          formatLength(_rounded(webs, 2)),
        ),
        ResultDetail(
          'Angle bar per truss',
          formatLength(_rounded(perTruss, 2)),
        ),
        ResultDetail('All trusses', formatLength(roundUp(metres))),
        ResultDetail(
          'With 5% waste, in 6 m lengths',
          formatQuantity(lengths.toDouble(), QuantityUnit.lengths),
        ),
        ResultDetail(
          'Steel with gussets',
          '${formatNumber(roundUp(steelKg))} kg',
        ),
      ],
      companions: [
        buy('gusset_plate', gussets.toDouble()),
        buy('welding_rod', steelKg * trussRodPerKg),
        buy('anchor_bolt_16', (count * trussAnchors).toDouble()),
        ..._steelPaint(paintArea, 1),
      ],
      note:
          'This is not a structural design: member sizes, the web pattern, '
          'connections and bracing must follow the engineer\'s plans. '
          'Purlins and cross bracing are not counted.',
      works: [
        WorkQuantity(SiteWork.steelTruss, _rounded(steelKg, 2)),
        WorkQuantity(Work.painting, _rounded(paintArea, 2), effort: 2),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Steel roof truss',
      'A triangular frame of welded angle bars that carries the purlins '
          'and roofing: two top chords along the roof slope, a bottom chord '
          'across the span and web members between them. This calculator '
          'estimates materials only; it is not a structural design.',
    ),
    InfoSection(
      'Span, spacing and pitch',
      'The span is the distance between the walls or beams the trusses sit '
          'on. Trusses repeat along the building at the chosen spacing, one '
          'at each end. The pitch is the rise per 12 of horizontal run.',
    ),
    InfoSection(
      'Angle bar',
      'Equal-leg angle bar 3/16" (4.8 mm) thick, sold in 6 m lengths. '
          '1½" × 1½" weighs about 2.68 kg/m and 2" × 2" about 3.63 kg/m. '
          'All members are counted in the chosen size; smaller web members '
          'in the plans use a little less steel.',
    ),
    InfoSection(
      'Gussets, anchors and paint',
      'A 6 mm steel gusset plate joins the members at each joint. Each '
          'truss is held down by two anchor bolts at each end. Steel gets '
          'one coat of red oxide primer and one of enamel.',
    ),
  ],
  solution: const [
    InfoSection(
      'Number of trusses',
      'One at each end and one at every spacing between.',
      formula: 'trusses = round down(length ÷ spacing) + 1',
    ),
    InfoSection(
      'Chords',
      'The top chords run along the slope from the eave overhang to the '
          'ridge on both sides; the bottom chord spans wall to wall.',
      formula:
          'top chords = 2 × (span ÷ 2 + overhang) × √(1 + pitch²)\n'
          'bottom chord = span',
    ),
    InfoSection(
      'Webs',
      'A Howe pattern with panels at most 1.2 m wide: a vertical at each '
          'panel point, as tall as the roof there, and a diagonal in each '
          'panel except the two end panels.',
      formula:
          'panels = 2 × round up(span ÷ 2 ÷ 1.2); panel = span ÷ panels\n'
          'vertical at panel point i = pitch × i × panel\n'
          'diagonal in panel i = √(panel² + (pitch × i × panel)²)',
    ),
    InfoSection(
      'Angle bars and steel',
      'Add 5% for cutting and round up to 6 m lengths. The steel weight '
          'adds a 150 × 150 × 6 mm gusset (1.06 kg) at each of the 2 × '
          'panels joints.',
      formula:
          'lengths = round up(trusses × per truss × 1.05 ÷ 6)\n'
          'steel = metres × kg per m + gussets × 1.06 kg',
    ),
    InfoSection(
      'Welding, anchors and paint',
      'Welding rod is about 2% of the steel weight. Four 16 mm anchor '
          'bolts per truss. Paint covers 4 × leg per metre of angle plus '
          'both faces of the gussets; primer and enamel each about 25 m² '
          'per 4 L coat, with 10% waste.',
      formula:
          'welding rod = steel × 0.02\n'
          'paint area = metres × 4 × leg + gussets × 0.045 m²',
    ),
  ],
  references: const [
    'AISC Steel Construction Manual, angle dimensions and weights',
    'NSCP 2015, Chapter 5 (structural steel)',
    'DPWH Standard Specifications, Item 1047 (structural steel)',
    'Boysen Red Oxide Primer and Quick Drying Enamel data sheets',
  ],
);
