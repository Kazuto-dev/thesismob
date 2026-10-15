import 'package:material_ui/material_ui.dart' show Icons;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'factors.dart';
import 'items.dart';
import 'material_spec.dart';

/// Vertical bars in a block wall, metres of bar per m² (laps included),
/// by spacing.
const chbVerticalBars = {'0.4': 2.93, '0.6': 2.13, '0.8': 1.60};

/// Horizontal bars in a block wall, metres per m², by how many courses
/// apart they are laid.
const chbHorizontalBars = {'2': 3.30, '3': 2.15, '4': 1.72};

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
    const ChoiceField(
      id: 'bar',
      label: 'Bar size',
      initial: '10',
      options: [
        ChoiceOption('10', '10 mm', 10),
        ChoiceOption('12', '12 mm', 12),
      ],
    ),
    const ChoiceField(
      id: 'vertical',
      label: 'Vertical bars',
      initial: '0.6',
      helper: 'Follow the plans; 60 cm is usual for houses',
      options: [
        ChoiceOption('0.4', 'Every 40 cm', 0.4),
        ChoiceOption('0.6', 'Every 60 cm', 0.6),
        ChoiceOption('0.8', 'Every 80 cm', 0.8),
      ],
    ),
    const ChoiceField(
      id: 'horizontal',
      label: 'Horizontal bars',
      initial: '3',
      options: [
        ChoiceOption('2', 'Every 2nd course', 2),
        ChoiceOption('3', 'Every 3rd course', 3),
        ChoiceOption('4', 'Every 4th course', 4),
      ],
    ),
  ],
  priceRef: (s) => PriceRef('chb_${s['size'] ?? '4'}'),
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
    final count = withWaste(ceilCount(net * chbPerSquareMetre), waste);
    final mortar = chbMortar[size.id]!;
    final cement = net * (mortar.cement + faces * plasterCement);
    final sand = net * (mortar.sand + faces * plasterSand);
    final vertical = input.choice('vertical');
    final horizontal = input.choice('horizontal');
    final barPerM2 =
        chbVerticalBars[vertical.id]! + chbHorizontalBars[horizontal.id]!;
    final barMm = int.parse(input.choice('bar').id);
    final rebar = net * barPerM2;
    final bars = ceilCount(rebar / rebarStockLength);
    // A tie wherever a vertical bar crosses a horizontal one.
    final ties = net / vertical.value / (horizontal.value * 0.20);
    return CalcResult(
      label: 'CHB ${size.label}',
      area: net,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.blocks,
      unitPrice: input['price'],
      itemKey: 'chb_${size.id}',
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
        ResultDetail(
          '$barMm mm bars, ${formatNumber(barPerM2)} m per m²',
          formatLength(roundUp(rebar, 1)),
        ),
      ],
      companions: [
        buy(
          'cement_40kg',
          cement,
          label: faces > 0 ? 'Cement for laying and plaster' : null,
        ),
        buy('sand', sand),
        buy(rebarKey(barMm), bars.toDouble()),
        buy('tie_wire', ties * tieWirePerTie(barMm) / tieWireMetresPerKg),
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
          'reinforced with 10 or 12 mm bars and usually plastered 16 mm thick '
          'on both faces. These materials are priced from your price book '
          'and added to the total.',
    ),
    InfoSection(
      'Bar spacing',
      'Vertical bars stand in the block cores, usually every 60 cm. '
          'Horizontal bars lie in the mortar joints, usually every third '
          'course. Use the spacing on your plans.',
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
      'Bar per m² of wall, laps included: vertical bars every 40, 60 or '
          '80 cm need 2.93, 2.13 or 1.60 m; horizontal bars every 2nd, 3rd '
          'or 4th course need 3.30, 2.15 or 1.72 m. Bars are sold 6 m long.',
      formula:
          'rebar = area × (vertical + horizontal)\n'
          'bars = round up(rebar ÷ 6)',
    ),
    InfoSection(
      'Tie wire',
      'Each crossing of a vertical and a horizontal bar is tied with about '
          '30 cm of #16 wire. A kilogram is about 53 m.',
      formula:
          'crossings = area ÷ vertical spacing ÷ (courses × 0.20)\n'
          'tie wire = crossings × 0.30 ÷ 53 kg',
    ),
    InfoSection(
      'Cost',
      'Multiply the total number of blocks by the price per block, then add '
          'the cement, sand, bars and tie wire at their price book prices.',
      formula: 'cost = blocks × price per block + Σ(other materials × price)',
    ),
  ],
  references: const [
    'https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/',
    'https://aedoconstruction.com/blog/chb-size-dimensions-philippines/',
    'https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/',
  ],
);

String _plywoodKey(String? thickness, String? grade) => grade == 'marine'
    ? marinePlywoodKey(thickness ?? '12')
    : plywoodKey(thickness ?? '12');

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
    const ChoiceField(
      id: 'thickness',
      label: 'Thickness',
      initial: '12',
      helper: '6 mm for ceilings, 12–18 mm for floors and cabinets',
      options: [
        ChoiceOption('6', '6 mm (¼")'),
        ChoiceOption('9', '9 mm (⅜")'),
        ChoiceOption('12', '12 mm (½")'),
        ChoiceOption('18', '18 mm (¾")'),
      ],
    ),
    const ChoiceField(
      id: 'grade',
      label: 'Grade',
      initial: 'ordinary',
      helper: 'Marine plywood resists moisture',
      options: [
        ChoiceOption('ordinary', 'Ordinary'),
        ChoiceOption('marine', 'Marine'),
      ],
    ),
    wasteField(
      initial: '10',
      helper: '10% for normal layouts, 15% for many openings',
    ),
  ],
  priceRef: (s) => PriceRef(_plywoodKey(s['thickness'], s['grade'])),
  compute: (input) {
    final area = input['length'] * input['width'];
    final waste = input.choice('waste').value;
    final count = withWaste(ceilCount(area / sheetArea), waste);
    final thickness = input.choice('thickness');
    final marine = input.chose('grade', 'marine');
    return CalcResult(
      label:
          "${marine ? 'Marine plywood' : 'Plywood'} ${thickness.label} 4' × 8'",
      itemKey: _plywoodKey(thickness.id, input.choice('grade').id),
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
      'Thickness and grade',
      '6 mm (¼") for ceilings, 9–12 mm for walls and partitions, 18 mm (¾") '
          'for floors, shelves and cabinets. Marine plywood uses waterproof '
          'glue for wet areas and concrete forms. Thickness and grade set the '
          'price, not the number of sheets.',
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
  priceRef: (s) => PriceRef('foam_roll_${s['roll'] ?? '50'}'),
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
      itemKey: 'foam_roll_${input.choice('roll').id}',
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
          buy('foil_tape', tape / 50, label: 'Foil tape for the laps'),
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
      'Every lap between strips is taped along its full length. Tape comes '
          'in 50 m rolls.',
      formula:
          'tape = (strips − 1) × strip length × sides\n'
          'rolls = round up(tape ÷ 50)',
    ),
  ],
  references: const [
    'https://www.lazada.com.ph/products/pe-foam-insulation-10mm-double-sided-1meter-x-50meter-i276479065.html',
    'https://roofonline.com/roof-pitch-factor/',
  ],
);

/// Ceiling framing per m²: metal furring every 0.40 m (2.5 m), carrying
/// channels every 1.20 m (0.833 m), hangers on a 1.20 m grid (0.69).
const furringPerM2 = 2.5;
const channelPerM2 = 1 / 1.2;
const hangersPerM2 = 1 / (1.2 * 1.2);

/// 2"×2" wood framing on a 0.40 × 0.60 m grid: 4.17 m of lumber per m²,
/// 1.094 board feet per metre.
const woodFramePerM2 = 4.56;

/// Board screws per m² of ceiling, fixed about every 20 cm along each
/// furring.
const screwsPerM2 = 14;

/// #10 GI hanger wire weighs about 0.071 kg per metre; each hanger takes
/// about a metre of wire with its twists.
const hangerWireKg = 0.071;

final ceiling = MaterialSpec(
  id: 'ceiling',
  name: 'Ceiling',
  category: MaterialCategory.structural,
  icon: Icons.grid_on,
  blurb: 'Boards with metal or wood framing, hangers and screws',
  keywords: const [
    'ceiling',
    'kisame',
    'hardiflex',
    'fiber cement',
    'gypsum',
    'furring',
    'carrying channel',
  ],
  numbers: const [
    NumberField(id: 'length', label: 'Room length', unit: 'm', max: 1000),
    NumberField(id: 'width', label: 'Room width', unit: 'm', max: 1000),
    NumberField(
      id: 'price',
      label: 'Price per board',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'board',
      label: 'Board',
      initial: 'fiber_cement_board',
      options: [
        ChoiceOption('fiber_cement_board', 'Fiber cement 4.5 mm'),
        ChoiceOption('gypsum_board', 'Gypsum 9 mm'),
      ],
    ),
    const ChoiceField(
      id: 'frame',
      label: 'Framing',
      initial: 'metal',
      options: [
        ChoiceOption('metal', 'Metal furring and channels'),
        ChoiceOption('wood', 'Wood 2" × 2"'),
      ],
    ),
    wasteField(initial: '10', helper: 'Offcuts at the edges of the room'),
  ],
  priceRef: (s) => PriceRef(s['board'] ?? 'fiber_cement_board'),
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    final perimeter = 2 * (length + width);
    final waste = input.choice('waste').value;
    final board = input.choice('board');
    final boards = withWaste(ceilCount(area / sheetArea), waste);
    final metal = input.chose('frame', 'metal');
    final hangers = ceilCount(area * hangersPerM2);
    return CalcResult(
      label: '${board.label} ceiling, ${metal ? 'metal' : 'wood'} frame',
      area: area,
      quantity: boards.total.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      itemKey: board.id,
      details: [
        ResultDetail('Ceiling area', formatArea(area)),
        const ResultDetail('Area per board (1.22 × 2.44 m)', '2.98 m²'),
        ResultDetail(
          'Boards for ${formatArea(area)}',
          formatQuantity(boards.base.toDouble(), QuantityUnit.sheets),
        ),
        ...wasteDetail(boards, waste, QuantityUnit.sheets),
        ResultDetail('Room perimeter', formatLength(roundUp(perimeter))),
        ResultDetail('Hangers on a 1.2 m grid', '$hangers'),
      ],
      companions: [
        if (metal) ...[
          buy('metal_furring', area * furringPerM2 * 1.05 / 5),
          buy('carrying_channel', area * channelPerM2 * 1.05 / 5),
          buy('wall_angle', perimeter / 3),
          buy('hanger_wire', hangers * hangerWireKg),
        ] else ...[
          buy(
            'good_lumber',
            (area * woodFramePerM2 + hangers * 1.094) * 1.05,
            label: 'Lumber 2" × 2", S4S',
          ),
          buy('nails', area * 0.08),
        ],
        buy('board_screws', area * screwsPerM2 * 1.05 / 100),
      ],
      note: 'Check spacing against the board maker\'s fixing guide.',
    );
  },
  definitions: const [
    InfoSection(
      'Ceiling boards',
      'Fiber cement (HardieFlex) and gypsum boards are 4\' × 8\' '
          '(1.22 × 2.44 m). Fiber cement suits eaves and humid rooms; gypsum '
          'gives a smoother finish indoors.',
    ),
    InfoSection(
      'Metal framing',
      'Carrying channels hang from the roof or slab every 1.2 m on wire '
          'hangers. Metal furring is clipped under them every 40 cm and the '
          'boards are screwed to the furring. Wall angles finish the edges. '
          'Furring and channels are 5 m long, wall angles 3 m.',
    ),
    InfoSection(
      'Wood framing',
      'A grid of 2" × 2" lumber at 40 × 60 cm, hung from the roof framing '
          'with 2" × 2" hangers about every 1.2 m.',
    ),
  ],
  solution: const [
    InfoSection(
      'Boards',
      'Divide the area by one board, round up and add the waste allowance.',
      formula: 'boards = round up(area ÷ 2.977) + waste',
    ),
    InfoSection(
      'Metal framing',
      'Furring every 0.40 m needs 2.5 m per m²; carrying channels every '
          '1.2 m need 0.83 m per m², both with 5% for laps, in 5 m pieces. '
          'Wall angle runs round the room in 3 m pieces. Each hanger takes '
          'about 1 m of #10 wire (0.071 kg).',
      formula:
          'furring = round up(area × 2.5 × 1.05 ÷ 5)\n'
          'channels = round up(area × 0.83 × 1.05 ÷ 5)\n'
          'wall angle = round up(perimeter ÷ 3)\n'
          'hangers = round up(area ÷ 1.44);  wire = hangers × 0.071 kg',
    ),
    InfoSection(
      'Wood framing',
      'A 40 × 60 cm grid of 2" × 2" needs 4.17 m of lumber per m², or 4.56 '
          'board feet, plus about 1.1 board feet per hanger and 5% waste, '
          'and about 0.08 kg of nails per m².',
      formula:
          'lumber = (area × 4.56 + hangers × 1.094) × 1.05 bd ft\n'
          'nails = area × 0.08 kg',
    ),
    InfoSection(
      'Screws',
      'About 14 screws per m², fixed every 20 cm along each furring, sold '
          'in boxes of 100.',
      formula: 'boxes = round up(area × 14 × 1.05 ÷ 100)',
    ),
  ],
  references: const [
    'James Hardie Philippines, HardieFlex ceiling installation guide',
    'https://aedoconstruction.com/blog/ceiling-installation-repair-cost-philippines/',
  ],
);
