import 'dart:math' as math;

import '../core/format.dart';
import 'calc_helpers.dart';
import 'material_spec.dart';

/// Paint "gallon" cans in the Philippines hold 4 litres.
const litresPerGallon = 4.0;

/// Waste allowance on paint for rollers, trays and touch-ups.
const paintWaste = 0.10;

/// Coverage of one coat of primer, m² per 4 L.
const primerCoverage = 25.0;

/// Corrugated GI sheets are 0.80 m wide; their end laps are 0.25 m.
const corrugatedEndLap = 0.25;

/// Long-span sheets are cut 5 cm longer than the slope.
const longSpanCutAllowance = 0.05;

/// Extra length cut from a carpet roll for trimming each drop.
const carpetTrim = 0.10;

/// Extra length on each wallpaper strip for trimming top and bottom.
const wallpaperTrim = 0.10;

final paint = MaterialSpec(
  id: 'paint',
  name: 'Paint',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/paint.png',
  blurb: '4-litre gallons by coats, with primer',
  keywords: const ['pintura', 'latex', 'enamel', 'primer', 'wall paint'],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Surface length',
      unit: 'm',
      hint: 'Add up the lengths of all walls to paint',
      max: 10000,
    ),
    NumberField(id: 'height', label: 'Surface height', unit: 'm', max: 1000),
    openingsField,
    NumberField(
      id: 'price',
      label: 'Price per gallon (4 L)',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: const [
    ChoiceField(
      id: 'type',
      label: 'Paint',
      initial: 'latex',
      helper: 'Coverage per coat for a 4 L gallon',
      options: [
        ChoiceOption('latex', 'Latex, 30 m²', 30),
        ChoiceOption('enamel', 'Enamel, 25 m²', 25),
      ],
    ),
    ChoiceField(
      id: 'coats',
      label: 'Finish coats',
      initial: '2',
      options: [
        ChoiceOption('1', '1 coat', 1),
        ChoiceOption('2', '2 coats', 2),
        ChoiceOption('3', '3 coats', 3),
      ],
    ),
    ChoiceField(
      id: 'primer',
      label: 'Primer coat',
      initial: 'yes',
      helper: 'New or bare surfaces need one coat of primer first',
      options: [
        ChoiceOption('yes', 'Include primer', 1),
        ChoiceOption('no', 'No primer', 0),
      ],
    ),
  ],
  compute: (input) {
    final gross = input['length'] * input['height'];
    final openings = input.optional('openings');
    final area = gross - openings;
    if (area <= 0) {
      throw ArgumentError('Doors and windows must be smaller than the surface');
    }
    final type = input.choice('type');
    final coats = input.choice('coats').value;
    final litres =
        area * coats / (type.value / litresPerGallon) * (1 + paintWaste);
    final gallons = ceilCount(litres / litresPerGallon);
    final primerLitres = input.choice('primer').value == 0
        ? 0.0
        : area / (primerCoverage / litresPerGallon) * (1 + paintWaste);
    final coatLabel = coats == 1 ? '1 coat' : '${formatNumber(coats)} coats';
    return CalcResult(
      label: 'Paint, ${type.id}, $coatLabel',
      area: area,
      quantity: gallons.toDouble(),
      unit: QuantityUnit.gallons,
      unitPrice: input['price'],
      details: [
        if (openings > 0) ...[
          ResultDetail('Surface area', formatArea(gross)),
          ResultDetail('Less doors and windows', '−${formatArea(openings)}'),
        ],
        ResultDetail('Area to paint', formatArea(area)),
        ResultDetail('Coverage per coat', '${formatArea(type.value)} per 4 L'),
        ResultDetail(
          'Paint for $coatLabel, +10% waste',
          '${formatNumber(roundUp(litres, 1))} L',
        ),
        ResultDetail(
          'Gallons of 4 L',
          formatQuantity(gallons.toDouble(), QuantityUnit.gallons),
        ),
      ],
      companions: [
        if (primerLitres > 0)
          ResultDetail(
            'Primer, 1 coat',
            '${formatCount(ceilCount(primerLitres / litresPerGallon), 'gallon')}'
                ' (${formatNumber(roundUp(primerLitres, 1))} L)',
          ),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Gallon',
      'Paint in the Philippines is sold in 1 L quarts, 4 L gallons and 16 L '
          'pails. A "gallon" here is 4 litres, not the 3.785 L US gallon.',
    ),
    InfoSection(
      'Surface length and height',
      'For walls, add up the lengths of the walls and use the floor-to-'
          'ceiling height. For a ceiling, use the room length and width.',
    ),
    InfoSection(
      'Coverage',
      'How much surface one coat from a 4 L gallon covers. Water-based '
          'latex covers about 30–35 m² as a top coat; enamel about 25–30 m². '
          'The app uses the low end, since rough walls take more paint.',
    ),
    InfoSection(
      'Coats and primer',
      'New concrete and bare wood get one coat of primer, then two finish '
          'coats. Repainting a sound surface in a similar colour may need '
          'only one finish coat and no primer.',
    ),
  ],
  solution: const [
    InfoSection(
      'Area to paint',
      'Multiply the length by the height and subtract doors and windows.',
      formula: 'area = length × height − openings',
    ),
    InfoSection(
      'Paint',
      'Divide the area by the coverage per litre for each coat, then add 10% '
          'for rollers, trays and touch-ups.',
      formula: 'litres = area × coats ÷ (coverage ÷ 4) × 1.10',
    ),
    InfoSection(
      'Gallons',
      'Divide by 4 litres and round up to whole gallons.',
      formula: 'gallons = round up(litres ÷ 4)',
    ),
    InfoSection(
      'Primer',
      'One coat of primer covers about 25 m² per 4 L, plus the same 10%.',
      formula: 'primer litres = area ÷ (25 ÷ 4) × 1.10',
    ),
    InfoSection(
      'Cost',
      'Multiply the gallons of finish paint by the price per gallon.',
      formula: 'cost = gallons × price per gallon',
    ),
  ],
  references: const [
    'https://www.boysen.com.ph/products/boysen-permacoat-latex',
    'https://www.boysen.com.ph/products/boysen-quick-drying-enamel',
  ],
);

/// Common tile sizes, with the usual number of pieces in a box.
const _tileSizes = [
  (id: '20x20', label: '20 × 20 cm', a: 0.20, b: 0.20, box: 25),
  (id: '20x30', label: '20 × 30 cm', a: 0.20, b: 0.30, box: 17),
  (id: '30x30', label: '30 × 30 cm', a: 0.30, b: 0.30, box: 16),
  (id: '30x60', label: '30 × 60 cm', a: 0.30, b: 0.60, box: 8),
  (id: '40x40', label: '40 × 40 cm', a: 0.40, b: 0.40, box: 6),
  (id: '60x60', label: '60 × 60 cm', a: 0.60, b: 0.60, box: 4),
];

final tiles = MaterialSpec(
  id: 'tiles',
  name: 'Tiles',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/tiles.png',
  blurb: 'Floor or wall tiles with adhesive and grout',
  keywords: const ['tile', 'baldosa', 'floor', 'sahig', 'wall tile', 'ceramic'],
  numbers: const [
    NumberField(id: 'length', label: 'Surface length', unit: 'm', max: 10000),
    NumberField(id: 'width', label: 'Surface width', unit: 'm', max: 10000),
    NumberField(
      id: 'perBox',
      label: 'Tiles per box',
      unit: 'pcs',
      hint: 'Optional. Printed on the box',
      integer: true,
      optional: true,
      max: 1000,
    ),
    NumberField(
      id: 'price',
      label: 'Price per tile',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    ChoiceField(
      id: 'size',
      label: 'Tile size',
      options: [
        for (final s in _tileSizes) ChoiceOption(s.id, s.label, s.a * s.b),
      ],
    ),
    const ChoiceField(
      id: 'layout',
      label: 'Layout',
      initial: 'straight',
      helper: 'Diagonal layouts cut more tiles at the edges',
      options: [
        ChoiceOption('straight', 'Straight, +10%', 0.10),
        ChoiceOption('diagonal', 'Diagonal, +15%', 0.15),
      ],
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    final size = _tileSizes.firstWhere((s) => s.id == input.choice('size').id);
    // Edge tiles count as whole tiles; lay them the way that needs fewer.
    final across = ceilCount(length / size.a) * ceilCount(width / size.b);
    final turned = ceilCount(length / size.b) * ceilCount(width / size.a);
    final base = math.min(across, turned);
    final rows = across <= turned
        ? (ceilCount(length / size.a), ceilCount(width / size.b))
        : (ceilCount(length / size.b), ceilCount(width / size.a));
    final layout = input.choice('layout');
    final count = withWaste(base, layout.value);
    final perBox = input.optional('perBox') > 0
        ? input.optional('perBox').round()
        : size.box;
    final boxes = ceilCount(count.total / perBox);
    // Adhesive: about 3 kg/m² for small tiles, 5 kg/m² from 40 × 40 cm.
    final adhesiveRate = math.max(size.a, size.b) <= 0.30 ? 3.0 : 5.0;
    final adhesiveBags = ceilCount(area * adhesiveRate / 25);
    // Grout for 3 mm joints, as deep as the tile (8–10 mm).
    final depth = math.max(size.a, size.b) <= 0.30 ? 8.0 : 10.0;
    final aMm = size.a * 1000;
    final bMm = size.b * 1000;
    final grout = roundUp(
      area * (aMm + bMm) / (aMm * bMm) * 3 * depth * 1.6,
      1,
    );
    return CalcResult(
      label: 'Tiles ${size.label}',
      area: area,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.pieces,
      unitPrice: input['price'],
      details: [
        ResultDetail('Area to tile', formatArea(area)),
        ResultDetail('Tiles in rows', '${rows.$1} × ${rows.$2} = $base'),
        ...wasteDetail(count, layout.value, QuantityUnit.pieces),
        ResultDetail('Boxes of $perBox', formatCount(boxes, 'box', 'boxes')),
      ],
      companions: [
        ResultDetail('Tile adhesive, 25 kg', formatCount(adhesiveBags, 'bag')),
        ResultDetail('Tile grout', '${formatNumber(grout)} kg'),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Tile size',
      'Common sizes in the Philippines are 20 × 20, 20 × 30 and 30 × 30 cm '
          'for walls and small rooms, and 30 × 60, 40 × 40 and 60 × 60 cm '
          'for floors.',
    ),
    InfoSection(
      'Surface length and width',
      'The floor or wall to tile, in metres.',
    ),
    InfoSection(
      'Layout',
      'Tiles laid straight, parallel to the walls, waste about 10% in cuts. '
          'Diagonal layouts cut every edge tile and waste about 15%.',
    ),
    InfoSection(
      'Tiles per box',
      'Usually 4 for 60 × 60, 6 for 40 × 40, 8 for 30 × 60, 16 for 30 × 30 '
          'and 25 for 20 × 20 cm. Enter the number printed on your box if '
          'it differs.',
    ),
    InfoSection(
      'Adhesive and grout',
      'Tile adhesive (thinset) bonds the tiles; grout fills the 3 mm joints. '
          'Large tiles need a thicker bed of adhesive.',
    ),
  ],
  solution: const [
    InfoSection(
      'Tiles in rows',
      'Count the tiles along each side, rounding up because cut edge tiles '
          'are whole tiles bought. Try the tile both ways round and keep the '
          'smaller count.',
      formula: 'tiles = round up(length ÷ tile) × round up(width ÷ tile)',
    ),
    InfoSection(
      'Waste and boxes',
      'Add 10% (straight) or 15% (diagonal), rounded up, then divide by the '
          'tiles per box.',
      formula:
          'total = tiles + round up(tiles × waste)\n'
          'boxes = round up(total ÷ tiles per box)',
    ),
    InfoSection(
      'Adhesive',
      'About 3 kg/m² with a 6 mm notched trowel for tiles up to 30 × 30 cm, '
          'about 5 kg/m² for larger tiles. Bags hold 25 kg.',
      formula: 'bags = round up(area × kg per m² ÷ 25)',
    ),
    InfoSection(
      'Grout',
      'Joint volume per m² times the density of grout (1.6 kg/L), with tile '
          'sides, joint width (3 mm) and depth in millimetres.',
      formula: 'kg = area × (a + b) ÷ (a × b) × joint × depth × 1.6',
    ),
    InfoSection(
      'Cost',
      'Multiply the total tiles by the price per tile.',
      formula: 'cost = total tiles × price per tile',
    ),
  ],
  references: const [
    'https://shop.wilcon.com.ph/tiles',
    'https://www.bostik.com/files/live/sites/shared_bostik/files/import-philippines/bostik-fixall-excel-tds-fa-rev1.pdf',
  ],
);

final roof = MaterialSpec(
  id: 'roof',
  name: 'Roofing Sheets',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/roof.png',
  blurb: 'Corrugated GI or long-span sheets, laid on the slope',
  keywords: const [
    'yero',
    'GI sheet',
    'long span',
    'bubong',
    'corrugated',
    'rib type',
  ],
  numbers: [
    const NumberField(
      id: 'eave',
      label: 'Roof length',
      unit: 'm',
      hint: 'Along the eaves',
      max: 10000,
    ),
    const NumberField(
      id: 'rafter',
      label: 'Rafter length',
      unit: 'm',
      hint: 'From the eaves to the ridge, overhang included',
      max: 1000,
    ),
    priceField('Price per sheet', visibleWhen: (s) => s['type'] != 'longspan'),
    priceField(
      'Price per metre',
      id: 'priceMetre',
      visibleWhen: (s) => s['type'] == 'longspan',
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Roofing',
      initial: 'corrugated',
      leading: true,
      options: [
        ChoiceOption('corrugated', 'Corrugated GI'),
        ChoiceOption('longspan', 'Long-span rib type'),
      ],
    ),
    slopeField,
    sidesField,
    ChoiceField(
      id: 'sheetLength',
      label: 'Sheet length',
      initial: '8',
      options: [
        for (final ft in [5, 6, 7, 8, 9, 10, 12])
          ChoiceOption('$ft', '$ft ft', ft * 0.3048),
      ],
      visibleWhen: (s) => s['type'] != 'longspan',
    ),
    ChoiceField(
      id: 'sideLap',
      label: 'Side lap',
      initial: '1.5',
      helper: 'Corrugations neighbouring 0.80 m sheets overlap',
      options: const [
        ChoiceOption('1.5', '1½ (0.70 m cover)', 0.70),
        ChoiceOption('2.5', '2½ (0.60 m cover)', 0.60),
      ],
      visibleWhen: (s) => s['type'] != 'longspan',
    ),
    ChoiceField(
      id: 'cover',
      label: 'Effective width',
      initial: '1.00',
      helper: 'Printed in the product sheet; most profiles cover about 1 m',
      options: const [
        ChoiceOption('1.00', '1.00 m', 1.00),
        ChoiceOption('1.07', '1.07 m', 1.07),
        ChoiceOption('0.98', '0.98 m', 0.98),
      ],
      visibleWhen: (s) => s['type'] == 'longspan',
    ),
  ],
  compute: (input) {
    final eave = input['eave'];
    final factor = input.choice('measured').value;
    final slope = input['rafter'] * factor;
    final sides = input.choice('sides').value.toInt();
    final longSpan = input.chose('type', 'longspan');
    final area = eave * slope * sides;
    final slopeDetail = [
      if (factor != 1)
        ResultDetail(
          'Slope length (\u00D7\u00A0${formatNumber(factor)})',
          formatLength(roundUp(slope)),
        ),
    ];
    final ridge = [
      if (sides == 2) ResultDetail('Ridge roll', formatLength(roundUp(eave))),
    ];
    if (longSpan) {
      final cover = input.choice('cover').value;
      final columns = ceilCount(eave / cover);
      final pieces = columns * sides;
      final cut = slope + longSpanCutAllowance;
      final metres = roundUp(pieces * cut);
      return CalcResult(
        label: 'Long-span roofing, ${formatLength(cover)} cover',
        area: area,
        quantity: metres,
        unit: QuantityUnit.metres,
        unitPrice: input['priceMetre'],
        details: [
          ...slopeDetail,
          ResultDetail(
            'Sheets per side (${formatLength(cover)} cover)',
            formatCount(columns, 'sheet'),
          ),
          ResultDetail('Cut length (+5 cm)', formatLength(roundUp(cut))),
          ResultDetail(
            '${formatCount(pieces, 'sheet')} × ${formatLength(roundUp(cut))}',
            formatLength(metres),
          ),
        ],
        companions: ridge,
        note: 'Long-span sheets are cut to length and sold by the metre.',
      );
    }
    final cover = input.choice('sideLap').value;
    final sheetLength = input.choice('sheetLength').value;
    final columns = ceilCount(eave / cover);
    final rows = slope <= sheetLength + 1e-9
        ? 1
        : ceilCount(
            (slope - corrugatedEndLap) / (sheetLength - corrugatedEndLap),
          );
    final sheets = columns * rows * sides;
    return CalcResult(
      label:
          'Corrugated GI, ${input.choice('sheetLength').label} '
          '(${formatLength(roundUp(sheetLength))})',
      area: area,
      quantity: sheets.toDouble(),
      unit: QuantityUnit.sheets,
      unitPrice: input['price'],
      details: [
        ...slopeDetail,
        ResultDetail(
          'Sheets along the eaves (${formatLength(cover)} cover)',
          formatCount(columns, 'sheet'),
        ),
        ResultDetail(
          'Sheets up the slope (0.25 m end lap)',
          formatCount(rows, 'sheet'),
        ),
        if (sides == 2) const ResultDetail('Roof sides', '× 2'),
      ],
      companions: ridge,
    );
  },
  definitions: const [
    InfoSection(
      'Corrugated GI',
      'Galvanised iron sheets with rounded waves, 0.80 m wide and 5 to 12 ft '
          'long. Neighbouring sheets overlap by 1½ or 2½ corrugations, '
          'leaving 0.70 or 0.60 m of cover.',
    ),
    InfoSection(
      'Long-span rib type',
      'Pre-painted sheets roll-formed to any length on order, so one sheet '
          'runs from eaves to ridge. They cover about 1 m each and are priced '
          'per linear metre.',
    ),
    InfoSection(
      'Roof length and rafter length',
      'Roof length runs along the eaves. Rafter length runs from the eaves '
          'up to the ridge, overhang included. Measured from a plan, the '
          'rafter length is horizontal, so choose the pitch to convert it.',
    ),
    InfoSection(
      'End lap',
      'Where two corrugated sheets meet up the slope, the upper one overlaps '
          'the lower by 0.25 m so water cannot get in.',
    ),
    InfoSection(
      'Ridge roll',
      'The bent cap that covers the ridge of a gable roof. It runs the full '
          'roof length.',
    ),
  ],
  solution: const [
    InfoSection(
      'Length along the slope',
      'A plan measurement times the pitch factor √(1 + (rise ÷ run)²): 1.054 '
          'for 4:12, 1.118 for 6:12, 1.414 for 12:12.',
      formula: 'slope = rafter × pitch factor',
    ),
    InfoSection(
      'Corrugated sheets',
      'Count the sheets along the eaves from their cover width, and the '
          'sheets up the slope from their length less the 0.25 m end lap.',
      formula:
          'across = round up(roof length ÷ cover)\n'
          'up = round up((slope − 0.25) ÷ (sheet length − 0.25))\n'
          'sheets = across × up × sides',
    ),
    InfoSection(
      'Long-span sheets',
      'One sheet per cover width along the eaves, each cut 5 cm longer than '
          'the slope.',
      formula:
          'sheets = round up(roof length ÷ cover) × sides\n'
          'metres = sheets × (slope + 0.05)',
    ),
    InfoSection(
      'Cost',
      'Sheets × price per sheet, or metres × price per metre for long-span.',
      formula: 'cost = quantity × price',
    ),
  ],
  references: const [
    'https://www.ugc.ph/product/durarib/',
    'https://www.ugc.ph/product/multi-rib8/',
    'https://roofonline.com/roof-pitch-factor/',
  ],
);

/// Broadloom carpet comes off rolls 4 m or 3.66 m wide.
({int drops, double cut, double bought}) carpetDrops(
  double length,
  double width,
  double roll,
) {
  ({int drops, double cut, double bought}) lay(double along, double across) {
    final drops = ceilCount(across / roll);
    final cut = along + carpetTrim;
    return (drops: drops, cut: cut, bought: drops * cut * roll);
  }

  final a = lay(length, width);
  final b = lay(width, length);
  return a.bought <= b.bought ? a : b;
}

final carpet = MaterialSpec(
  id: 'carpet',
  name: 'Carpet',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/carpet.png',
  blurb: 'Wall-to-wall carpet from a roll, or carpet tiles',
  keywords: const ['alpombra', 'karpet', 'rug', 'broadloom', 'carpet tile'],
  numbers: [
    const NumberField(id: 'length', label: 'Room length', unit: 'm', max: 1000),
    const NumberField(id: 'width', label: 'Room width', unit: 'm', max: 1000),
    priceField('Price per m²', visibleWhen: (s) => s['type'] != 'tiles'),
    priceField(
      'Price per box',
      id: 'boxPrice',
      visibleWhen: (s) => s['type'] == 'tiles',
    ),
  ],
  choices: [
    const ChoiceField(
      id: 'type',
      label: 'Carpet',
      initial: 'roll',
      leading: true,
      options: [
        ChoiceOption('roll', 'Roll (broadloom)'),
        ChoiceOption('tiles', 'Carpet tiles'),
      ],
    ),
    ChoiceField(
      id: 'rollWidth',
      label: 'Roll width',
      initial: '4',
      options: const [
        ChoiceOption('4', '4.00 m', 4),
        ChoiceOption('3.66', '3.66 m (12 ft)', 3.66),
      ],
      visibleWhen: (s) => s['type'] != 'tiles',
    ),
  ],
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    if (input.chose('type', 'tiles')) {
      final tiles = ceilCount(area * 1.05 / 0.25);
      final boxes = ceilCount(tiles / 20);
      return CalcResult(
        label: 'Carpet tiles 50 × 50 cm',
        area: area,
        quantity: boxes.toDouble(),
        unit: QuantityUnit.boxes,
        unitPrice: input['boxPrice'],
        details: [
          ResultDetail('Room area', formatArea(area)),
          ResultDetail('Tiles with 5% waste', formatCount(tiles, 'tile')),
          const ResultDetail('Tiles per box (5 m²)', '20'),
        ],
      );
    }
    final roll = input.choice('rollWidth').value;
    final lay = carpetDrops(length, width, roll);
    final bought = roundUp(lay.bought, 1);
    final perimeter = 2 * (length + width);
    return CalcResult(
      label: 'Carpet, ${formatLength(roll)} roll',
      area: area,
      quantity: bought,
      unit: QuantityUnit.squareMetres,
      unitPrice: input['price'],
      details: [
        ResultDetail('Room area', formatArea(area)),
        ResultDetail(
          'Drops from a ${formatLength(roll)} roll',
          '${lay.drops} × ${formatLength(roundUp(lay.cut))}',
        ),
        ResultDetail('Carpet to buy', formatArea(bought)),
      ],
      companions: [
        ResultDetail('Underlay', formatArea(roundUp(area * 1.05, 1))),
        ResultDetail('Gripper strip', formatLength(roundUp(perimeter, 1))),
        if (lay.drops > 1)
          ResultDetail(
            'Seam tape',
            formatLength(roundUp((lay.drops - 1) * lay.cut, 1)),
          ),
      ],
      note: 'Drops run the way that needs less carpet.',
    );
  },
  definitions: const [
    InfoSection(
      'Broadloom carpet',
      'Wall-to-wall carpet cut from rolls 4 m or 3.66 m (12 ft) wide and '
          'priced per square metre. Each length cut from the roll is a drop.',
    ),
    InfoSection(
      'Carpet tiles',
      '50 × 50 cm squares, usually 20 to a box (5 m²). Easy to replace one '
          'at a time.',
    ),
    InfoSection(
      'Underlay and gripper',
      'Underlay is the cushion under broadloom carpet. Gripper strips are '
          'nailed around the walls to hold the carpet edges.',
    ),
  ],
  solution: const [
    InfoSection(
      'Drops',
      'Enough roll widths to span the room, each cut 10 cm longer than the '
          'room for trimming. Both directions are tried and the one that '
          'needs less carpet is used.',
      formula:
          'drops = round up(room width ÷ roll width)\n'
          'carpet = drops × (room length + 0.10) × roll width',
    ),
    InfoSection(
      'Carpet tiles',
      'Each tile covers 0.25 m². Add 5% for cuts and divide into boxes of '
          '20.',
      formula:
          'tiles = round up(area × 1.05 ÷ 0.25)\n'
          'boxes = round up(tiles ÷ 20)',
    ),
    InfoSection(
      'Cost',
      'Square metres × price per m², or boxes × price per box.',
      formula: 'cost = quantity × price',
    ),
  ],
  references: const [
    'https://jswallmatrix.com/products/carpets/carpet-roll/price-list-philippines',
  ],
);

final wallpaper = MaterialSpec(
  id: 'wallpaper',
  name: 'Wallpaper',
  category: MaterialCategory.architectural,
  image: 'assets/images/materials/wallpaper.png',
  blurb: 'Rolls counted strip by strip, with pattern repeat',
  keywords: const ['wall paper', 'wallcovering', 'wall sticker'],
  numbers: const [
    NumberField(
      id: 'width',
      label: 'Wall width',
      unit: 'm',
      hint: 'Add up the widths of all walls to cover',
      max: 10000,
    ),
    NumberField(id: 'height', label: 'Wall height', unit: 'm', max: 100),
    NumberField(
      id: 'openings',
      label: 'Doors to skip',
      unit: 'm',
      hint: 'Optional. Total width of full-height openings',
      optional: true,
      max: 10000,
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
    const ChoiceField(
      id: 'roll',
      label: 'Roll size',
      initial: 'std',
      options: [
        ChoiceOption('std', '0.53 × 10.05 m', 0.53),
        ChoiceOption('jumbo', '1.06 × 15.6 m', 1.06),
        ChoiceOption('narrow', '0.45 × 10 m', 0.45),
      ],
    ),
    const ChoiceField(
      id: 'repeat',
      label: 'Pattern repeat',
      initial: '0',
      helper: 'Printed on the label; matching patterns wastes paper',
      options: [
        ChoiceOption('0', 'None', 0),
        ChoiceOption('32', '32 cm', 0.32),
        ChoiceOption('53', '53 cm', 0.53),
        ChoiceOption('64', '64 cm', 0.64),
      ],
    ),
    wasteField(initial: 'none', percents: const [0, 10, 15]),
  ],
  compute: (input) {
    final height = input['height'];
    final width = input['width'] - input.optional('openings');
    if (width <= 0) {
      throw ArgumentError('Doors to skip must be narrower than the walls');
    }
    final roll = input.choice('roll');
    final rollWidth = roll.value;
    final rollLength = switch (roll.id) {
      'jumbo' => 15.6,
      'narrow' => 10.0,
      _ => 10.05,
    };
    final repeat = input.choice('repeat').value;
    var drop = height + wallpaperTrim;
    if (repeat > 0) drop = ceilCount(drop / repeat) * repeat;
    final perRoll = (rollLength / drop + 1e-9).floor();
    if (perRoll == 0) {
      throw ArgumentError('The wall is taller than one roll');
    }
    final strips = ceilCount(width / rollWidth);
    final waste = input.choice('waste').value;
    final count = withWaste(ceilCount(strips / perRoll), waste);
    return CalcResult(
      label: 'Wallpaper ${roll.label}',
      area: width * height,
      quantity: count.total.toDouble(),
      unit: QuantityUnit.rolls,
      unitPrice: input['price'],
      details: [
        ResultDetail(
          repeat > 0 ? 'Strip length (with repeat)' : 'Strip length (+10 cm)',
          formatLength(roundUp(drop)),
        ),
        ResultDetail('Strips per roll', '$perRoll'),
        ResultDetail('Strips to cover ${formatLength(width)}', '$strips'),
        ResultDetail(
          'Rolls',
          formatQuantity(count.base.toDouble(), QuantityUnit.rolls),
        ),
        ...wasteDetail(count, waste, QuantityUnit.rolls),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Roll sizes',
      'The standard roll is 0.53 m wide and 10.05 m long (about 5.3 m²). '
          'Jumbo rolls are 1.06 × 15.6 m; some self-adhesive rolls are '
          '0.45 × 10 m.',
    ),
    InfoSection(
      'Strip',
      'One floor-to-ceiling length cut from the roll. Leftovers shorter than '
          'the wall cannot be used for another full strip.',
    ),
    InfoSection(
      'Pattern repeat',
      'The distance before a pattern repeats. Each strip must start at the '
          'same point of the pattern, so strips are cut in whole repeats.',
    ),
  ],
  solution: const [
    InfoSection(
      'Strip length',
      'Wall height plus 10 cm for trimming, rounded up to whole pattern '
          'repeats if there is one.',
      formula: 'strip = height + 0.10',
    ),
    InfoSection(
      'Strips per roll',
      'Only whole strips count.',
      formula: 'per roll = round down(roll length ÷ strip)',
    ),
    InfoSection(
      'Rolls',
      'Strips across the walls, divided among the rolls.',
      formula:
          'strips = round up(wall width ÷ roll width)\n'
          'rolls = round up(strips ÷ per roll)',
    ),
    InfoSection(
      'Cost',
      'Multiply the rolls by the price per roll.',
      formula: 'cost = rolls × price per roll',
    ),
  ],
  references: const [
    'https://www.screwfix.com/guides/painting-decorating/wallpaper/how-much-wallpaper-do-i-need',
  ],
);
