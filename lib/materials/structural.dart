import '../core/format.dart';
import 'calc_helpers.dart';
import 'material_spec.dart';

/// Face of a hollow block with its mortar joint: 0.40 × 0.20 m, or
/// 12.5 blocks per m², whatever its thickness.
const chbFaceArea = 0.08;

/// Class B mortar (1:3) to lay one m² of wall, by block thickness:
/// 40 kg cement bags and m³ of sand. Fajardo, Simplified Construction
/// Estimate, Table 2-2.
const chbMortar = {
  '4': (cement: 0.522, sand: 0.0435),
  '6': (cement: 1.018, sand: 0.0844),
  '8': (cement: 1.500, sand: 0.1250),
};

/// Class B plaster, 16 mm thick, per m² of each plastered face.
const plasterCement = 0.192;
const plasterSand = 0.016;

/// 10 mm bars per m² of wall: vertical every 0.60 m (2.13 m) plus
/// horizontal every third course (2.15 m), laps included.
const chbRebar = 4.28;

/// Commercial length of reinforcing bars.
const rebarLength = 6.0;

/// A 4' × 8' plywood sheet as sold in the Philippines: 1.22 × 2.44 m.
const plywoodSheetArea = 1.22 * 2.44;

/// Foam rolls are 1 m wide; a 50 mm taped lap leaves 0.95 m of cover.
const foamRollWidth = 1.0;
const foamLap = 0.05;

final chb = MaterialSpec(
  id: 'chb',
  name: 'Concrete Hollow Blocks',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/chb.png',
  blurb: 'Blocks for a wall, with mortar, plaster and rebar',
  keywords: const ['hollow blocks', 'CHB', 'block', 'wall', 'pader', 'masonry'],
  numbers: const [
    NumberField(id: 'length', label: 'Wall length', unit: 'm', max: 10000),
    NumberField(id: 'height', label: 'Wall height', unit: 'm', max: 100),
    openingsField,
    NumberField(
      id: 'price',
      label: 'Price per block',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'size',
      label: 'Block size',
      initial: '4',
      helper: '4" for partitions, 6" for exterior and load-bearing walls',
      options: [
        ChoiceOption('4', '4"'),
        ChoiceOption('6', '6"'),
        ChoiceOption('8', '8"'),
      ],
    ),
    wasteField(initial: '5', helper: 'About 5% of blocks break or are cut'),
    const ChoiceField(
      id: 'plaster',
      label: 'Plaster',
      initial: '2',
      helper: 'Adds cement and sand for 16 mm of plaster',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('1', 'One face', 1),
        ChoiceOption('2', 'Both faces', 2),
      ],
    ),
  ],
  compute: (input) {
    final gross = input['length'] * input['height'];
    final openings = input.optional('openings');
    final net = gross - openings;
    if (net <= 0) {
      throw ArgumentError('Doors and windows must be smaller than the wall');
    }
    final size = input.choice('size');
    final waste = input.choice('waste').value;
    final faces = input.choice('plaster').value;
    final count = withWaste(ceilCount(net / chbFaceArea), waste);
    final mortar = chbMortar[size.id]!;
    final cement = ceilCount(net * (mortar.cement + faces * plasterCement));
    final sand = roundUp(net * (mortar.sand + faces * plasterSand));
    final rebar = roundUp(net * chbRebar, 1);
    return CalcResult(
      label: 'CHB ${size.label}',
      area: net,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.blocks,
      unitPrice: input['price'],
      details: [
        if (openings > 0) ...[
          ResultDetail('Wall area', formatArea(gross)),
          ResultDetail('Less doors and windows', '−${formatArea(openings)}'),
        ],
        ResultDetail('Area to build', formatArea(net)),
        const ResultDetail('Blocks per m²', '12.5'),
        ResultDetail(
          'Blocks for ${formatArea(net)}',
          formatQuantity(count.base.toDouble(), QuantityUnit.blocks),
        ),
        ...wasteDetail(count, waste, QuantityUnit.blocks),
      ],
      companions: [
        ResultDetail(
          faces > 0 ? 'Cement, 40 kg (laying and plaster)' : 'Cement, 40 kg',
          formatCount(cement, 'bag'),
        ),
        ResultDetail('Sand', formatVolume(sand)),
        ResultDetail(
          'Rebar, 10 mm × 6 m',
          formatCount(ceilCount(rebar / rebarLength), 'bar'),
        ),
      ],
      note: 'Cement and sand use Class B mortar (1:3).',
    );
  },
  definitions: const [
    InfoSection(
      'Concrete hollow block (CHB)',
      'A precast block with hollow cores, 40 cm long and 20 cm high '
          'including its mortar joint. Sold by thickness: 4" for partitions, '
          '6" for exterior and load-bearing walls, 8" for fences and '
          'retaining walls.',
    ),
    InfoSection(
      'Wall length and height',
      'Measure the wall from end to end and from the floor slab to the top '
          'of the wall, in metres. For several walls, add up their lengths '
          'if they share the same height.',
    ),
    InfoSection(
      'Doors and windows',
      'Openings have no blocks, so their area is left out. A standard door '
          'is about 0.9 × 2.1 m (1.9 m²) and a window 1.0 × 1.2 m (1.2 m²).',
    ),
    InfoSection(
      'Waste allowance',
      'Extra blocks for breakage during delivery and cutting at corners and '
          'openings. 5% is the usual allowance.',
    ),
    InfoSection(
      'Mortar, plaster and rebar',
      'Blocks are laid in Class B mortar (1 part cement to 3 parts sand), '
          'reinforced with 10 mm bars and usually plastered 16 mm thick on '
          'both faces. These quantities are listed under "Also needed" to '
          'help you plan; they are not part of the cost.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area to build',
      'Multiply the wall length by its height, then subtract doors and '
          'windows.',
      formula: 'area = length × height − openings',
    ),
    InfoSection(
      'Blocks',
      'Each block with its joint covers 0.40 × 0.20 m = 0.08 m², so a '
          'square metre takes 12.5 blocks. Round up, then add the waste '
          'allowance, also rounded up.',
      formula:
          'blocks = round up(area × 12.5)\n'
          'total = blocks + round up(blocks × waste)',
    ),
    InfoSection(
      'Cement and sand',
      'Class B mortar per m² of wall: 0.522 bags of cement and 0.0435 m³ of '
          'sand for 4" blocks, 1.018 bags and 0.0844 m³ for 6", 1.500 bags '
          'and 0.125 m³ for 8". Plaster 16 mm thick adds 0.192 bags and '
          '0.016 m³ per m² of each face.',
      formula:
          'cement = round up(area × (mortar + faces × 0.192))\n'
          'sand = area × (mortar sand + faces × 0.016)',
    ),
    InfoSection(
      'Reinforcing bars',
      '10 mm bars spaced 0.60 m vertically and every third course '
          'horizontally need 2.13 + 2.15 = 4.28 m of bar per m², including '
          'laps. Bars are sold 6 m long.',
      formula: 'rebar = area × 4.28 m;  bars = round up(rebar ÷ 6)',
    ),
    InfoSection(
      'Cost',
      'Multiply the total number of blocks by the price per block.',
      formula: 'cost = total blocks × price per block',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/',
    'https://aedoconstruction.com/blog/chb-size-dimensions-philippines/',
    'https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/',
  ],
);

final plywood = MaterialSpec(
  id: 'plywood',
  name: 'Plywood',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/plywood.png',
  blurb: "4' × 8' sheets for a floor, wall or ceiling",
  keywords: const ['playwud', 'ceiling', 'kisame', 'marine plywood', 'board'],
  numbers: const [
    NumberField(id: 'length', label: 'Surface length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Surface width', unit: 'm', max: 10000),
    NumberField(
      id: 'price',
      label: 'Price per sheet',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    descriptor('thickness', 'Thickness', [
      ('6', '6 mm (¼")'),
      ('9', '9 mm (⅜")'),
      ('12', '12 mm (½")'),
      ('18', '18 mm (¾")'),
    ], helper: '6 mm for ceilings, 12–18 mm for floors and cabinets'),
    wasteField(
      initial: '10',
      helper: '10% for normal layouts, 15% for many openings',
    ),
  ],
  compute: (input) {
    final area = input['length'] * input['width'];
    final waste = input.choice('waste').value;
    final count = withWaste(ceilCount(area / plywoodSheetArea), waste);
    return CalcResult(
      label: describe("Plywood 4' × 8'", [input.choices['thickness']]),
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      details: [
        ResultDetail('Area to cover', formatArea(area)),
        const ResultDetail('Area per sheet (1.22 × 2.44 m)', '2.98 m²'),
        ResultDetail(
          'Sheets for ${formatArea(area)}',
          formatQuantity(count.base.toDouble(), QuantityUnit.sheets),
        ),
        ...wasteDetail(count, waste, QuantityUnit.sheets),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Plywood',
      'Thin wood veneers glued in layers with the grain crossed, making a '
          'strong, stable board. Sheets are 4 × 8 ft (1.22 × 2.44 m). Use '
          'marine plywood where it can get wet.',
    ),
    InfoSection(
      'Surface length and width',
      'The size of the floor, wall or ceiling to cover, in metres.',
    ),
    InfoSection(
      'Thickness',
      '6 mm (¼") for ceilings, 9–12 mm for walls and partitions, 18 mm (¾") '
          'for floors, shelves and cabinets. Thickness does not change the '
          'number of sheets.',
    ),
    InfoSection(
      'Waste allowance',
      'Offcuts at edges and openings: 5% for a plain rectangle, 10% for '
          'normal layouts, 15–20% for rooms with many openings.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area to cover',
      'Multiply the length by the width.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Sheets',
      "A 4' × 8' sheet is 1.22 × 2.44 m = 2.977 m². Divide the area by it "
          'and round up, then add the waste allowance.',
      formula:
          'sheets = round up(area ÷ 2.977)\n'
          'total = sheets + round up(sheets × waste)',
    ),
    InfoSection(
      'Cost',
      'Multiply the total sheets by the price per sheet.',
      formula: 'cost = total sheets × price per sheet',
    ),
  ],
  references: const [
    'https://www.filtratimber.com/brochure/pdf/plywood-presentation-2025.pdf',
  ],
);

final insulation = MaterialSpec(
  id: 'insulation',
  name: 'Foam Insulation',
  category: MaterialCategory.structural,
  image: 'assets/images/materials/insulation.png',
  blurb: 'Foil-faced PE foam under a roof, with laps and tape',
  keywords: const ['foam', 'foil', 'roof insulation', 'init', 'PE foam'],
  numbers: const [
    NumberField(
      id: 'eave',
      label: 'Roof length',
      unit: 'm',
      hint: 'Along the eaves',
      max: 10000,
    ),
    NumberField(
      id: 'rafter',
      label: 'Rafter length',
      unit: 'm',
      hint: 'From the eaves to the ridge, overhang included',
      max: 1000,
    ),
    NumberField(
      id: 'price',
      label: 'Price per roll',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    slopeField,
    sidesField,
    const ChoiceField(
      id: 'roll',
      label: 'Roll size',
      initial: '50',
      options: [
        ChoiceOption('50', '1 × 50 m', 50),
        ChoiceOption('25', '1 × 25 m', 25),
      ],
    ),
    descriptor('thickness', 'Thickness', [('5', '5 mm'), ('10', '10 mm')]),
    descriptor('foil', 'Foil', [
      ('single', 'One side'),
      ('double', 'Both sides'),
    ]),
  ],
  compute: (input) {
    final eave = input['eave'];
    final factor = input.choice('measured').value;
    final slope = input['rafter'] * factor;
    final sides = input.choice('sides').value;
    final rollLength = input.choice('roll').value;
    final strips = ceilCount(eave / (foamRollWidth - foamLap));
    final stripLength = slope + foamLap;
    final foam = roundUp(strips * stripLength * sides * 1.05, 1);
    final rolls = ceilCount(foam / rollLength);
    final tape = roundUp((strips - 1) * stripLength * sides, 1);
    return CalcResult(
      label: describe('PE foam insulation', [
        input.choices['thickness'],
        input.choices['foil'],
      ]),
      area: eave * slope * sides,
      quantity: rolls.toDouble(),
      unit: QuantityUnit.rolls,
      unitPrice: input['price'],
      details: [
        if (factor != 1)
          ResultDetail(
            'Slope length (\u00D7\u00A0${formatNumber(factor)})',
            formatLength(roundUp(slope)),
          ),
        ResultDetail(
          'Strips per side (0.95 m each)',
          formatCount(strips, 'strip'),
        ),
        ResultDetail(
          'Strip length (with 5 cm lap)',
          formatLength(roundUp(stripLength)),
        ),
        ResultDetail('Foam with 5% waste', formatLength(foam)),
        ResultDetail(
          'Rolls of ${formatLength(rollLength)}',
          formatQuantity(rolls.toDouble(), QuantityUnit.rolls),
        ),
      ],
      companions: [
        if (tape > 0)
          ResultDetail('Foil tape for the laps', formatLength(tape)),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'PE foam insulation',
      'Closed-cell polyethylene foam, usually faced with aluminium foil, laid '
          'over the purlins under the roof sheets to block heat. Sold in '
          '1 m wide rolls, 50 m or 25 m long, 5 or 10 mm thick.',
    ),
    InfoSection(
      'Roof length and rafter length',
      'Roof length runs along the eaves. Rafter length runs from the eaves '
          'up to the ridge, overhang included.',
    ),
    InfoSection(
      'Rafter length measured',
      'Measured on the roof itself, the rafter length is already along the '
          'slope. Taken from a floor plan it is horizontal, so choose the '
          'roof pitch (rise per 12 of run) and the app converts it.',
    ),
    InfoSection(
      'Laps and tape',
      'Neighbouring strips overlap by 5 cm and the joint is sealed with '
          'foil tape, so each 1 m strip covers 0.95 m.',
    ),
  ],
  solution: const [
    InfoSection(
      'Length along the slope',
      'Multiply a plan measurement by the pitch factor √(1 + (rise ÷ run)²): '
          '1.054 for 4:12, 1.118 for 6:12, 1.414 for 12:12.',
      formula: 'slope = rafter × pitch factor',
    ),
    InfoSection(
      'Strips',
      'Strips run from eaves to ridge. Each covers 0.95 m of roof length and '
          'is cut 5 cm longer than the slope for the top lap.',
      formula:
          'strips = round up(roof length ÷ 0.95)\n'
          'strip length = slope + 0.05',
    ),
    InfoSection(
      'Rolls',
      'Add 5% for waste and divide by the roll length.',
      formula: 'rolls = round up(strips × strip length × sides × 1.05 ÷ roll)',
    ),
    InfoSection(
      'Foil tape',
      'Every lap between strips is taped along its full length.',
      formula: 'tape = (strips − 1) × strip length × sides',
    ),
  ],
  references: const [
    'https://www.lazada.com.ph/products/pe-foam-insulation-10mm-double-sided-1meter-x-50meter-i276479065.html',
    'https://roofonline.com/roof-pitch-factor/',
  ],
);
