part of 'concrete.dart';

// Wall footings, lintels with stiffener columns and sills, and concrete
// pavements. They use the concrete, bar and form helpers of concrete.dart.
// Tie beams are an option of the Beams calculator.

/// Keys of the work items these calculators, and tie beams, add to the
/// bill of quantities.
abstract final class StructureWork {
  static const concreteTieBeam = 'concrete_tie_beam';
  static const concreteLintel = 'concrete_lintel';
  static const pavement = 'pcc_pavement';
}

/// Price book items these calculators buy.
final List<Item> structureExtrasItems = [
  const Item(
    'wire_mesh',
    'Welded wire mesh 6" × 6", 4 mm, 1.5 × 6 m sheet',
    'sheet',
    ItemGroup.steel,
    plural: 'sheets',
    price: 750,
    estimate: true,
  ),
  const Item(
    'joint_sealant',
    'Polyurethane joint sealant, 600 mL sausage',
    'pc',
    ItemGroup.other,
    plural: 'pcs',
    price: 650,
    estimate: true,
  ),
  const Item(
    'curing_compound',
    'Concrete curing compound, 4 L',
    'gallon',
    ItemGroup.other,
    plural: 'gallons',
    price: 700,
    estimate: true,
  ),
];

/// Work items these calculators measure.
const structureExtrasWorkItems = <WorkItem>[
  WorkItem(
    StructureWork.concreteTieBeam,
    'Structural concrete, tie beams',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(
      foreman: 0.5,
      skilled: 1,
      helpers: 4,
      equipment: {DailyRates.mixer: 1, DailyRates.vibrator: 1},
    ),
    output: 4,
    reference: '900',
  ),
  WorkItem(
    StructureWork.concreteLintel,
    'Structural concrete, lintels, stiffener columns and sills',
    'm³',
    trade: MaterialCategory.structural,
    crew: Crew(foreman: 0.1, skilled: 1, helpers: 2),
    output: 1,
    reference: '900',
  ),
  WorkItem(
    StructureWork.pavement,
    'Concrete pavement, 100 mm, placed, jointed and cured',
    'm²',
    trade: MaterialCategory.structural,
    crew: Crew(
      foreman: 0.5,
      skilled: 1,
      helpers: 4,
      equipment: {DailyRates.mixer: 1, DailyRates.vibrator: 1},
    ),
    output: 40,
    reference: '311',
  ),
];

/// The calculators.
final List<MaterialSpec> structureExtrasMaterials = [
  wallFooting,
  lintel,
  pavement,
];

// ---------------------------------------------------------------------------
// Wall footings

/// Widths of the hollow block walls a wall footing carries, in metres.
const _wallOptions = [
  ChoiceOption('4', '4" CHB', 0.10),
  ChoiceOption('6', '6" CHB', 0.15),
  ChoiceOption('8', '8" CHB', 0.20),
];

/// Bars of one size or two, as companions: one line when they match.
List<Companion> _bars(int mmA, int countA, int mmB, int countB) => [
  if (mmA == mmB)
    buy(rebarKey(mmA), (countA + countB).toDouble())
  else ...[
    if (countA > 0) buy(rebarKey(mmA), countA.toDouble()),
    if (countB > 0) buy(rebarKey(mmB), countB.toDouble()),
  ],
];

final wallFooting = MaterialSpec(
  id: 'wall_footing',
  name: 'Wall Footings',
  category: MaterialCategory.structural,
  icon: Icons.view_stream_outlined,
  blurb: 'Strip footings under walls, with bars, trench and backfill',
  keywords: const [
    'wall footing',
    'strip footing',
    'continuous footing',
    'pundasyon',
    'pundasyon ng pader',
    'foundation',
    'trench',
    'hukay',
    'concrete',
  ],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Wall footing length',
      unit: 'm',
      hint: 'All runs of the same size, added up',
      typical: (min: 0.5, max: 300),
      max: 10000,
    ),
    NumberField(
      id: 'width',
      label: 'Footing width',
      unit: 'm',
      hint: 'Usually 0.45–0.80 m under a house wall',
      typical: (min: 0.3, max: 3),
      max: 10,
    ),
    NumberField(
      id: 'thickness',
      label: 'Thickness',
      unit: 'm',
      hint: 'Usually 0.20–0.25 m',
      typical: (min: 0.1, max: 1),
      initial: '0.20',
      max: 5,
    ),
    NumberField(
      id: 'depth',
      label: 'Excavation depth',
      unit: 'm',
      hint: 'From the ground to the bottom, gravel bed included',
      typical: (min: 0.3, max: 3),
      max: 20,
    ),
    _cementPrice,
  ],
  choices: [
    _classChoice,
    _barSize('bar', 'Cross bar size', const [10, 12, 16], '12'),
    _spacing(
      'spacing',
      'Cross bar spacing',
      const [0.15, 0.20, 0.25, 0.30],
      '0.2',
      helper: 'The main bars, across the width of the footing',
    ),
    const ChoiceField(
      id: 'runs',
      label: 'Lengthwise bars',
      initial: '4',
      helper: 'Follow the plans; 3 or 4 is usual under a house wall',
      options: [
        ChoiceOption('3', '3 bars', 3),
        ChoiceOption('4', '4 bars', 4),
        ChoiceOption('5', '5 bars', 5),
        ChoiceOption('6', '6 bars', 6),
      ],
    ),
    _barSize('longBar', 'Lengthwise bar size', const [10, 12, 16], '10'),
    _lapChoice,
    const ChoiceField(
      id: 'wall',
      label: 'Wall on the footing',
      initial: '6',
      helper: 'Its part below the ground takes the place of backfill',
      options: _wallOptions,
    ),
    const ChoiceField(
      id: 'bedding',
      label: 'Gravel bed',
      initial: '0.1',
      helper: 'Compacted gravel under the footing',
      options: _bedOptions,
    ),
    const ChoiceField(
      id: 'space',
      label: 'Working space',
      initial: '0.3',
      helper: 'Room beside the footing to set bars and lay the blocks',
      options: _spaceOptions,
    ),
    const ChoiceField(
      id: 'sides',
      label: 'Side forms',
      initial: 'none',
      helper: 'Footings are often cast against the excavated soil',
      options: [
        ChoiceOption('none', 'None, cast against soil'),
        ChoiceOption('plywood', 'Plywood forms'),
      ],
    ),
    _formPlywood.copyWithVisibility((s) => s['sides'] == 'plywood'),
    _reuse(
      '3',
      'Plywood forms are stripped and reused for the next pour',
    ).copyWithVisibility((s) => s['sides'] == 'plywood'),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final thickness = input['thickness'];
    final depth = input['depth'];
    final bed = input.choice('bedding').value;
    if (bed >= depth) {
      throw ArgumentError('The excavation must be deeper than its gravel bed');
    }
    if (length <= 2 * coverEarth || width <= 2 * coverEarth) {
      throw ArgumentError('The footing must be wider than its 75 mm cover');
    }
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final volume = length * width * thickness;
    final concrete = _mix(volume, mix, waste);

    // Cross bars across the width, lengthwise bars along the run, all
    // inside 75 mm of cover.
    final crossMm = int.parse(input.choice('bar').id);
    final spacing = input.choice('spacing').value;
    final crossCount = ((length - 2 * coverEarth) / spacing + 1e-9).floor() + 1;
    final crossLength = width - 2 * coverEarth;
    final crossBars = stockBars(crossCount, crossLength, 0);
    final runs = input.choice('runs').value.round();
    final longMm = int.parse(input.choice('longBar').id);
    final lap = input.choice('lap').value * longMm / 1000;
    final longLength = length - 2 * coverEarth;
    final longBars = stockBars(runs, longLength, lap);
    final rebarKg =
        _barMetres(crossCount, crossLength, 0) * rebarKgPerMetre(crossMm) +
        _barMetres(runs, longLength, lap) * rebarKgPerMetre(longMm);

    final formed = input.chose('sides', 'plywood');
    final formArea = formed ? 2 * length * thickness : 0.0;
    final uses = formed ? input.choice('reuse').value : 1.0;

    // The trench, the gravel bed, and what goes back in: everything the
    // footing, the bed and the wall below the ground do not fill.
    final space = input.choice('space').value;
    final trenchWidth = width + 2 * space;
    final excavation = length * trenchWidth * depth;
    final bedding = length * width * bed;
    final buried = length * width * math.min(thickness, depth - bed);
    final wall = input.choice('wall');
    final wallBelow = math.max(0.0, depth - bed - thickness);
    final stem = length * wall.value * wallBelow;
    final backfill = math.max(0.0, excavation - bedding - buried - stem);

    return CalcResult(
      label:
          'Wall footing ${formatLength(length)}, '
          '${formatNumber(width)} × ${formatNumber(thickness)} m, '
          '${mix.label}',
      area: length * width,
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ..._mixDetails(volume, mix, waste, concrete.cement),
        ResultDetail(
          'Cross bars, $crossCount × $crossMm mm, '
          '${formatLength(_rounded(crossLength, 3))} each',
          formatCount(crossBars, 'bar'),
        ),
        ResultDetail(
          'Lengthwise bars, $runs × $longMm mm, '
          '${formatLength(_rounded(longLength, 3))} each',
          formatCount(longBars, 'bar'),
        ),
        if (formed) ..._formDetails(formArea, uses),
        ResultDetail(
          'Trench, ${formatNumber(_rounded(trenchWidth, 2))} × '
          '${formatNumber(depth)} m',
          formatVolume(roundUp(excavation, 3)),
        ),
        if (bedding > 0)
          ResultDetail('Gravel bed', formatVolume(roundUp(bedding, 3))),
        if (stem > 0)
          ResultDetail(
            '${wall.label} wall below the ground',
            formatVolume(roundUp(stem, 3)),
          ),
        ResultDetail('Backfill', formatVolume(_rounded(backfill, 3))),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        if (bedding > 0) buy('gravel_bedding', bedding),
        ..._bars(crossMm, crossBars, longMm, longBars),
        _tieWire(crossCount * runs, math.max(crossMm, longMm)),
        if (formed)
          ..._forms(
            formArea,
            plywood: input.choice('plywood').id,
            uses: uses,
            lumberPerSheet: columnFrameLumber[input.choice('plywood').id]!,
          ),
      ],
      note:
          'Excavation and backfill are counted here; leave them out of '
          'Earthworks. The wall itself is counted in Concrete Hollow Blocks. '
          'Footing size and bars must follow the structural plans.',
      works: [
        ..._concreteWorks(
          Work.concreteFooting,
          volume,
          rebarKg: rebarKg,
          formArea: formArea,
          bedding: bedding,
        ),
        WorkQuantity(Work.excavation, _rounded(excavation, 3)),
        if (_rounded(backfill, 3) > 0)
          WorkQuantity(Work.backfill, _rounded(backfill, 3)),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Wall footing',
      'A continuous strip of reinforced concrete under a load-bearing or '
          'exterior wall that spreads its weight on the soil. Add up the '
          'runs of the same width and thickness and enter them together.',
    ),
    InfoSection(
      'Cross and lengthwise bars',
      'The main bars run across the width near the bottom, 75 mm above the '
          'soil. A few lengthwise bars hold them in place and tie the strip '
          'together. Typical house plans use 12 mm cross bars at 20 cm with '
          '3 or 4 lengthwise 10 mm bars. Always follow the plans.',
    ),
    InfoSection(
      'Trench and backfill',
      'The trench is dug wider than the footing so workers can set the '
          'bars and lay the first blocks. After the footing and the wall '
          'below the ground are built, the rest of the trench is backfilled '
          'with the excavated soil.',
    ),
    InfoSection(
      'Side forms',
      'Wall footings are usually poured against the sides of the trench. '
          'Where the soil is loose, plywood forms hold the concrete.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Volume of the strip with the waste allowance, times the mix factors '
          'per m³.',
      formula:
          'volume = length × width × thickness × (1 + waste)\n'
          'cement = round up(volume × bags per m³)',
    ),
    InfoSection(
      'Bars',
      'With 75 mm cover all round: cross bars at the chosen spacing along '
          'the run, each the width less the cover; lengthwise bars the run '
          'less the cover, spliced with the chosen lap where longer than '
          '6 m. Tie wire at each crossing.',
      formula:
          'cross bars = round down((length − 0.15) ÷ spacing) + 1, each '
          'width − 0.15\n'
          'lengthwise bars = count × (length − 0.15)\n'
          'tie wire = cross bars × lengthwise bars × 0.30 ÷ 53 kg',
    ),
    InfoSection(
      'Excavation, gravel bed and backfill',
      'The trench is the footing width plus the working space on each side, '
          'as deep as entered. The gravel bed lies under the footing. The '
          'backfill is what the footing, the bed and the wall below the '
          'ground leave of the trench.',
      formula:
          'excavation = length × (width + 2 × space) × depth\n'
          'gravel bed = length × width × bed\n'
          'wall below ground = length × wall width × (depth − bed − '
          'thickness)\n'
          'backfill = excavation − footing − bed − wall below ground',
    ),
    InfoSection(
      'Side forms',
      'When chosen, plywood lines both sides of the strip, with the column '
          'table\'s frame lumber per sheet and 0.20 kg of nails per m².',
      formula:
          'form area = 2 × length × thickness\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2',
    'NSCP 2015, Table 420.6.1.3.1 (concrete cover)',
    'DPWH Standard Specifications, Item 103 (Structure Excavation) and '
        'Item 104 (Embankment)',
  ],
);

// ---------------------------------------------------------------------------
// Lintels, stiffener columns and sills

/// A lintel is one block course deep; a sill is 0.10 m thick; a stiffener
/// column takes half a block's length of the wall. All are as wide as the
/// block.
const lintelDepth = 0.20;
const sillDepth = 0.10;
const stiffenerLength = 0.20;

/// Cover to the bars of lintels, stiffeners and sills inside a plastered
/// block wall.
const coverLintel = 0.025;

/// Ties of lintels and stiffeners are 10 mm bars, the smallest sold.
const _lintelTieMm = 10;

final lintel = MaterialSpec(
  id: 'lintel',
  name: 'Lintels and Stiffeners',
  category: MaterialCategory.structural,
  icon: Icons.door_sliding_outlined,
  blurb: 'Lintel beams, stiffener columns and sills in a block wall',
  keywords: const [
    'lintel',
    'lintel beam',
    'linter',
    'stiffener',
    'stiffener column',
    'sill',
    'window sill',
    'CHB',
    'hollow blocks',
    'pader',
    'pinto',
    'bintana',
  ],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Wall length',
      unit: 'm',
      hint: 'Walls of the same block size, added up',
      typical: (min: 0.3, max: 300),
      max: 10000,
    ),
    NumberField(
      id: 'height',
      label: 'Wall height',
      unit: 'm',
      hint: 'From the slab or footing to the beam above',
      typical: (min: 0.2, max: 8),
      max: 100,
    ),
    NumberField(
      id: 'doors',
      label: 'Doors',
      unit: 'pcs',
      hint: 'Optional. Openings with a lintel only',
      integer: true,
      optional: true,
      max: 1000,
    ),
    NumberField(
      id: 'doorWidth',
      label: 'Door opening width',
      unit: 'm',
      initial: '0.9',
      typical: (min: 0.5, max: 4),
      max: 20,
    ),
    NumberField(
      id: 'windows',
      label: 'Windows',
      unit: 'pcs',
      hint: 'Optional. Openings with a lintel and a sill',
      integer: true,
      optional: true,
      max: 1000,
    ),
    NumberField(
      id: 'windowWidth',
      label: 'Window opening width',
      unit: 'm',
      initial: '1.2',
      typical: (min: 0.3, max: 6),
      max: 20,
    ),
    _cementPrice,
  ],
  choices: [
    const ChoiceField(
      id: 'size',
      label: 'Block size',
      initial: '4',
      helper: 'Lintels, stiffeners and sills are as wide as the wall',
      options: [
        ChoiceOption('4', '4"', 0.10),
        ChoiceOption('6', '6"', 0.15),
        ChoiceOption('8', '8"', 0.20),
      ],
    ),
    const ChoiceField(
      id: 'stiffeners',
      label: 'Stiffener columns',
      initial: '3',
      helper: 'Usually one for about every 3 m of wall between columns',
      options: [
        ChoiceOption('none', 'None', 0),
        ChoiceOption('2.4', 'Every 2.4 m', 2.4),
        ChoiceOption('3', 'Every 3.0 m', 3.0),
        ChoiceOption('3.6', 'Every 3.6 m', 3.6),
      ],
    ),
    const ChoiceField(
      id: 'bearing',
      label: 'Lintel bearing',
      initial: '0.2',
      helper: 'How far a lintel rests on the wall at each side of an opening',
      options: [
        ChoiceOption('0.15', '15 cm each side', 0.15),
        ChoiceOption('0.2', '20 cm each side', 0.20),
      ],
    ),
    const ChoiceField(
      id: 'sills',
      label: 'Window sills',
      initial: 'concrete',
      options: [
        ChoiceOption('concrete', 'Concrete sill under each window'),
        ChoiceOption('none', 'None'),
      ],
    ),
    _classChoice,
    const ChoiceField(
      id: 'bars',
      label: 'Bars per lintel and stiffener',
      initial: 'auto',
      helper: 'Usually 2 in a 4" wall and 4 in 6" and 8" walls; sills get 2',
      options: [
        ChoiceOption('auto', 'Usual for the block'),
        ChoiceOption('2', '2 bars', 2),
        ChoiceOption('4', '4 bars', 4),
      ],
    ),
    _barSize('bar', 'Bar size', const [10, 12], '10'),
    _spacing('tieSpacing', '10 mm tie spacing', const [
      0.15,
      0.20,
      0.25,
    ], '0.2'),
    _lapChoice,
    _formPlywood,
    _reuse('3'),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final wallLength = input['length'];
    final height = input['height'];
    final doors = input.optional('doors').round();
    final windows = input.optional('windows').round();
    final doorWidth = input['doorWidth'];
    final windowWidth = input['windowWidth'];
    if (doors * doorWidth + windows * windowWidth > wallLength) {
      throw ArgumentError('Doors and windows must fit in the wall');
    }
    final size = input.choice('size');
    final t = size.value;
    final bearing = input.choice('bearing').value;
    final doorLintel = doorWidth + 2 * bearing;
    final windowLintel = windowWidth + 2 * bearing;
    final sills = input.chose('sills', 'none') ? 0 : windows;
    final every = input.choice('stiffeners').value;
    // About one stiffener for every few metres of wall: a wall is broken by
    // columns, which the stiffeners do not replace.
    final stiffeners = every > 0 ? (wallLength / every + 1e-9).floor() : 0;

    final lintelMetres = doors * doorLintel + windows * windowLintel;
    final sillMetres = sills * windowLintel;
    final volume =
        lintelMetres * t * lintelDepth +
        sillMetres * t * sillDepth +
        stiffeners * t * stiffenerLength * height;
    if (volume <= 0) {
      throw ArgumentError('Enter doors or windows, or choose stiffeners');
    }
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final concrete = _mix(volume, mix, waste);

    final barMm = int.parse(input.choice('bar').id);
    final barsOption = input.choice('bars');
    final perMember = barsOption.id == 'auto'
        ? (size.id == '4' ? 2 : 4)
        : barsOption.value.round();
    final lap = input.choice('lap').value * barMm / 1000;
    // Lintel and sill bars run the member's length, anchored by the
    // bearing; stiffener bars run the height and lap into the beam.
    final stiffenerBar = height + lap;
    final mainBars =
        stockBars(doors * perMember, doorLintel, lap) +
        stockBars(windows * perMember, windowLintel, lap) +
        stockBars(sills * 2, windowLintel, lap) +
        stockBars(stiffeners * perMember, stiffenerBar, lap);
    final mainMetres =
        _barMetres(doors * perMember, doorLintel, lap) +
        _barMetres(windows * perMember, windowLintel, lap) +
        _barMetres(sills * 2, windowLintel, lap) +
        _barMetres(stiffeners * perMember, stiffenerBar, lap);

    final spacing = input.choice('tieSpacing').value;
    int along(double metres) => (metres / spacing + 1e-9).floor() + 1;
    final ties =
        doors * along(doorLintel) +
        windows * along(windowLintel) +
        stiffeners * along(height);
    // Lintels and stiffeners share a t × 0.20 m section.
    final tieLength =
        2 * (t - 2 * coverLintel) +
        2 * (lintelDepth - 2 * coverLintel) +
        2 * hookLength(_lintelTieMm);
    final tieBars = stockBars(ties, tieLength, 0);
    final rebarKg =
        mainMetres * rebarKgPerMetre(barMm) +
        _barMetres(ties, tieLength, 0) * rebarKgPerMetre(_lintelTieMm);

    // Both faces of every member; lintels also need a soffit over the
    // opening. The blocks close the other sides.
    final openings = doors * doorWidth + windows * windowWidth;
    final formArea =
        2 * lintelMetres * lintelDepth +
        openings * t +
        2 * sillMetres * sillDepth +
        2 * stiffeners * stiffenerLength * height;
    final uses = input.choice('reuse').value;
    final plywood = input.choice('plywood').id;

    return CalcResult(
      label:
          'Lintels and stiffeners, ${size.label} wall '
          '${formatLength(wallLength)}, ${mix.label}',
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        if (doors > 0)
          ResultDetail(
            'Door lintels, ${formatLength(_rounded(doorLintel, 2))} each',
            '$doors',
          ),
        if (windows > 0)
          ResultDetail(
            'Window lintels, ${formatLength(_rounded(windowLintel, 2))} each',
            '$windows',
          ),
        if (sills > 0) ResultDetail('Window sills', '$sills'),
        if (stiffeners > 0)
          ResultDetail(
            'Stiffener columns, ${formatLength(height)} high',
            '$stiffeners',
          ),
        ..._mixDetails(volume, mix, waste, concrete.cement),
        ResultDetail(
          '$barMm mm bars, $perMember per lintel and stiffener',
          formatCount(mainBars, 'bar'),
        ),
        ResultDetail(
          'Ties, ${formatLength(_rounded(tieLength, 2))} each',
          '$ties',
        ),
        ..._formDetails(formArea, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        ..._bars(barMm, mainBars, _lintelTieMm, tieBars),
        if (ties > 0) _tieWire(ties * perMember, barMm),
        ..._forms(
          formArea,
          plywood: plywood,
          uses: uses,
          lumberPerSheet: columnFrameLumber[plywood]!,
        ),
      ],
      note:
          'The blocks are counted over the whole wall in Concrete Hollow '
          'Blocks; the few these members replace allow for breakage. '
          'Members and bars must follow the plans.',
      works: _concreteWorks(
        StructureWork.concreteLintel,
        volume,
        rebarKg: rebarKg,
        formArea: formArea,
      ),
    );
  },
  definitions: const [
    InfoSection(
      'Lintel',
      'A small reinforced concrete beam over a door or window that carries '
          'the blocks above the opening. It rests on the wall 15–20 cm past '
          'each side of the opening and is one block course (0.20 m) deep.',
    ),
    InfoSection(
      'Stiffener column',
      'A slim column cast in the wall, as wide as the block and 0.20 m '
          'along it, that braces a long block wall between the structural '
          'columns. Usual practice puts one about every 3 m.',
    ),
    InfoSection(
      'Sill',
      'A 0.10 m concrete band under a window opening with two bars, which '
          'keeps the blocks below from cracking at the corners.',
    ),
    InfoSection(
      'Bars and ties',
      'Usually 2 × 10 mm bars in a 4" wall and 4 × 10 mm in 6" and 8" '
          'walls, with 10 mm ties at 20 cm. Follow the plans.',
    ),
  ],
  solution: const [
    InfoSection(
      'Members',
      'Each opening gets a lintel as long as the opening plus the bearing '
          'at both ends; each window a sill as long. Stiffeners are counted '
          'at one for every chosen spacing of wall, as tall as the wall.',
      formula:
          'lintel = opening + 2 × bearing\n'
          'stiffeners = round down(wall length ÷ spacing)',
    ),
    InfoSection(
      'Concrete',
      'Lintels are block-wide and 0.20 m deep; sills 0.10 m deep; '
          'stiffeners block-wide and 0.20 m along the wall. Add the waste '
          'allowance and multiply by the mix factors.',
      formula:
          'volume = lintels × lintel × t × 0.20 + sills × sill × t × 0.10 + '
          'stiffeners × t × 0.20 × height',
    ),
    InfoSection(
      'Bars and ties',
      'Lintel and sill bars run the member\'s length; stiffener bars the '
          'wall height plus one lap into the beam. Ties at the chosen '
          'spacing wrap a t × 0.20 m section inside 25 mm of cover with two '
          '135° hooks. Sills have 2 bars and no ties.',
      formula:
          'ties per member = round down(length ÷ spacing) + 1\n'
          'tie = 2 × (t − 0.05) + 2 × (0.20 − 0.05) + 2 × hook\n'
          'tie wire = ties × bars × 0.30 ÷ 53 kg',
    ),
    InfoSection(
      'Forms',
      'Plywood on both faces of each member and under each lintel across '
          'the opening, with the column table\'s frame lumber per sheet and '
          '0.20 kg of nails per m².',
      formula:
          'form area = 2 × lintel metres × 0.20 + openings × t + '
          '2 × sill metres × 0.10 + 2 × stiffeners × 0.20 × height\n'
          'plywood = round up(form area ÷ 2.88 ÷ uses)',
    ),
  ],
  references: const [
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2',
    'NSCP 2015, Sections 425.3 (hooks) and 420.6.1.3.1 (cover)',
    'https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/',
  ],
);

// ---------------------------------------------------------------------------
// Concrete pavement

/// A 1.5 × 6 m mesh sheet lapped one 0.15 m square on each edge.
const meshSheetCover = (1.5 - 0.15) * (6 - 0.15);

/// Control joints are sealed with a 6 × 12 mm bead, plus 10% waste: L per
/// metre of joint.
const sealantPerMetre = 0.006 * 0.012 * 1000 * 1.10;

/// Sealant comes in 600 mL sausages.
const sealantPack = 0.6;

/// Curing compound is sprayed at about 0.20 L per m², and sold by the
/// 4 L gallon.
const curingPerM2 = 0.20;
const _curingGallon = 4.0;

/// Usual control joint spacing: 30 times the thickness, at most 4.5 m.
double controlJointSpacing(double thickness) => math.min(30 * thickness, 4.5);

/// The pavement work item's output is for 100 mm; thicker pavements take
/// longer in proportion.
const _pavementBase = 0.10;

final pavement = MaterialSpec(
  id: 'pavement',
  name: 'Concrete Pavement',
  category: MaterialCategory.structural,
  icon: Icons.add_road,
  blurb: 'Driveway, sidewalk or carport slab with base, joints and curing',
  keywords: const [
    'driveway',
    'sidewalk',
    'pavement',
    'carport',
    'garahe',
    'bangketa',
    'daanan',
    'kalsada',
    'PCCP',
    'wire mesh',
    'concrete',
    'semento',
  ],
  numbers: const [
    NumberField(
      id: 'length',
      label: 'Pavement length',
      unit: 'm',
      typical: (min: 0.5, max: 200),
      max: 10000,
    ),
    NumberField(
      id: 'width',
      label: 'Pavement width',
      unit: 'm',
      typical: (min: 0.5, max: 50),
      max: 1000,
    ),
    NumberField(
      id: 'edge',
      label: 'Edge to form',
      unit: 'm',
      hint: 'Optional. Leave empty to form the whole perimeter',
      typical: (min: 0.5, max: 300),
      optional: true,
      max: 10000,
      visibleWhen: _formedEdges,
    ),
    _cementPrice,
  ],
  choices: [
    const ChoiceField(
      id: 'thickness',
      label: 'Thickness',
      initial: '0.1',
      helper: '100 mm for walks and carports, 150 mm where cars drive often',
      options: [
        ChoiceOption('0.1', '100 mm', 0.10),
        ChoiceOption('0.125', '125 mm', 0.125),
        ChoiceOption('0.15', '150 mm', 0.15),
      ],
    ),
    _classChoice,
    const ChoiceField(
      id: 'base',
      label: 'Gravel base',
      initial: '0.1',
      helper: 'Compacted gravel under the pavement',
      options: _bedOptions,
    ),
    const ChoiceField(
      id: 'reinforcement',
      label: 'Reinforcement',
      initial: 'bars',
      options: [
        ChoiceOption('bars', 'Bars both ways'),
        ChoiceOption('mesh', 'Welded wire mesh'),
        ChoiceOption('none', 'None'),
      ],
    ),
    _barSize('bar', 'Bar size', const [
      10,
      12,
    ], '10').copyWithVisibility(_paveBars),
    _spacing(
      'spacing',
      'Bar spacing, both ways',
      const [0.20, 0.25, 0.30, 0.40],
      '0.3',
      helper: 'Follow the plans; 30 cm is usual where cars drive',
    ).copyWithVisibility(_paveBars),
    _lapChoice.copyWithVisibility(_paveBars),
    const ChoiceField(
      id: 'joints',
      label: 'Control joints',
      initial: 'auto',
      helper: 'Cut or tooled grooves across the slab, so it cracks along them',
      options: [
        ChoiceOption('auto', 'Usual for the thickness'),
        ChoiceOption('1.5', 'Every 1.5 m', 1.5),
        ChoiceOption('2', 'Every 2 m', 2),
        ChoiceOption('3', 'Every 3 m', 3),
      ],
    ),
    const ChoiceField(
      id: 'sealant',
      label: 'Joint sealant',
      initial: 'sealed',
      options: [
        ChoiceOption('sealed', 'Polyurethane sealant'),
        ChoiceOption('none', 'None, tooled joints'),
      ],
    ),
    const ChoiceField(
      id: 'curing',
      label: 'Curing',
      initial: 'compound',
      helper: 'New concrete is kept moist for 7 days',
      options: [
        ChoiceOption('compound', 'Curing compound'),
        ChoiceOption('water', 'Kept wet with water'),
      ],
    ),
    ChoiceField(
      id: 'edges',
      label: 'Edge forms',
      initial: 'perimeter',
      helper: 'Edges not poured against a curb or wall need forms',
      options: const [
        ChoiceOption('perimeter', 'Around the slab'),
        ChoiceOption('none', 'None, poured against curbs or walls'),
      ],
    ),
    _formPlywood.copyWithVisibility(_formedEdges),
    _reuse('3').copyWithVisibility(_formedEdges),
    _concreteWaste,
  ],
  priceRef: _cementRef,
  compute: (input) {
    final length = input['length'];
    final width = input['width'];
    final area = length * width;
    final thickness = input.choice('thickness').value;
    final volume = area * thickness;
    final mix = concreteMix(input.choice('class').id);
    final waste = input.choice('waste').value;
    final concrete = _mix(volume, mix, waste);

    // Bars both ways inside 40 mm of cover, as in a slab on fill, or
    // lapped sheets of mesh.
    final barsChosen = input.chose('reinforcement', 'bars');
    final meshChosen = input.chose('reinforcement', 'mesh');
    var bars = 0;
    var crossings = 0;
    var barMetres = 0.0;
    var barMm = 10;
    var spacing = 0.0;
    var runsAlong = 0;
    var runsAcross = 0;
    if (barsChosen) {
      if (length <= 2 * coverFormed || width <= 2 * coverFormed) {
        throw ArgumentError('The pavement must be wider than its bar cover');
      }
      barMm = int.parse(input.choice('bar').id);
      spacing = input.choice('spacing').value;
      final lap = input.choice('lap').value * barMm / 1000;
      runsAlong = ((width - 2 * coverFormed) / spacing + 1e-9).floor() + 1;
      runsAcross = ((length - 2 * coverFormed) / spacing + 1e-9).floor() + 1;
      bars =
          stockBars(runsAlong, length - 2 * coverFormed, lap) +
          stockBars(runsAcross, width - 2 * coverFormed, lap);
      barMetres =
          _barMetres(runsAlong, length - 2 * coverFormed, lap) +
          _barMetres(runsAcross, width - 2 * coverFormed, lap);
      crossings = runsAlong * runsAcross;
    }
    final sheets = meshChosen ? ceilCount(area / meshSheetCover) : 0;

    // Control joints divide the slab into panels no longer than the
    // spacing, both ways.
    final jointOption = input.choice('joints');
    final jointSpacing = jointOption.id == 'auto'
        ? controlJointSpacing(thickness)
        : jointOption.value;
    final across = math.max(0, ceilCount(length / jointSpacing) - 1);
    final along = math.max(0, ceilCount(width / jointSpacing) - 1);
    final joints = across * width + along * length;
    final sealed = input.chose('sealant', 'sealed') && joints > 0;
    final curing = input.chose('curing', 'compound');

    final bedding = area * input.choice('base').value;
    final edgeForms = !input.chose('edges', 'none');
    final entered = input.optional('edge');
    final edge = edgeForms
        ? (entered > 0 ? entered : 2 * (length + width))
        : 0.0;
    final formArea = edge * thickness;
    final uses = edgeForms ? input.choice('reuse').value : 1.0;

    final rebarKg = _rounded(barMetres * rebarKgPerMetre(barMm), 2);
    final forms = _rounded(formArea, 2);
    final gravel = _rounded(bedding, 3);
    return CalcResult(
      label:
          'Concrete pavement ${formatNumber(length)} × '
          '${formatNumber(width)} m, ${formatNumber(thickness * 1000)} mm, '
          '${mix.label}',
      area: area,
      quantity: concrete.cement.toDouble(),
      unit: QuantityUnit.bags,
      unitPrice: input['price'],
      itemKey: 'cement_40kg',
      details: [
        ResultDetail('Pavement area', formatArea(area)),
        ..._mixDetails(volume, mix, waste, concrete.cement),
        if (barsChosen) ...[
          ResultDetail(
            '$barMm mm bars @ ${formatNumber(spacing * 100)} cm',
            '$runsAlong + $runsAcross runs',
          ),
          ResultDetail('6 m bars to buy', formatCount(bars, 'bar')),
        ],
        if (meshChosen)
          ResultDetail(
            'Mesh sheets, ${formatArea(_rounded(meshSheetCover, 2))} each',
            formatCount(sheets, 'sheet'),
          ),
        ResultDetail(
          'Control joints every ${formatLength(_rounded(jointSpacing, 2))}',
          formatLength(_rounded(joints, 2)),
        ),
        if (edge > 0) ResultDetail('Edge to form', formatLength(roundUp(edge))),
        if (formArea > 0) ..._formDetails(formArea, uses),
      ],
      companions: [
        buy('sand', concrete.sand),
        buy('gravel', concrete.gravel),
        if (bedding > 0) buy('gravel_bedding', bedding),
        if (bars > 0) buy(rebarKey(barMm), bars.toDouble()),
        if (crossings > 0) _tieWire(crossings, barMm),
        if (sheets > 0) buy('wire_mesh', sheets.toDouble()),
        if (sealed)
          buy('joint_sealant', joints * sealantPerMetre / sealantPack),
        if (curing) buy('curing_compound', area * curingPerM2 / _curingGallon),
        if (formArea > 0)
          ..._forms(
            formArea,
            plywood: input.choice('plywood').id,
            uses: uses,
            lumberPerSheet: columnFrameLumber[input.choice('plywood').id]!,
          ),
      ],
      note:
          'Expansion joints against the house and curbs, and dowels across '
          'joints, are not counted. Thickness and bars must follow the '
          'plans.',
      // The pavement is paid by the m²; a thicker one takes longer.
      works: [
        WorkQuantity(
          StructureWork.pavement,
          _rounded(area, 2),
          effort: thickness / _pavementBase,
        ),
        if (rebarKg > 0) WorkQuantity(Work.rebar, rebarKg),
        if (forms > 0) WorkQuantity(Work.formwork, forms),
        if (gravel > 0) WorkQuantity(Work.gravelBedding, gravel),
      ],
    );
  },
  definitions: const [
    InfoSection(
      'Concrete pavement',
      'A concrete slab on a compacted gravel base for a driveway, carport, '
          'sidewalk or yard. Enter each rectangle of the same thickness on '
          'its own.',
    ),
    InfoSection(
      'Thickness and reinforcement',
      'Walks and carports are usually 100 mm thick, driveways used every '
          'day 125–150 mm. House pavements are reinforced with 10 mm bars '
          'at about 30 cm both ways, or with welded wire mesh sheets, to '
          'hold cracks closed. Follow the plans.',
    ),
    InfoSection(
      'Control joints',
      'Grooves a quarter of the slab deep, tooled or sawn across the '
          'pavement so it cracks along them as it shrinks. They are usually '
          'spaced at most 30 times the thickness, 3 m for 100 mm, and '
          'sealed against water and grit.',
    ),
    InfoSection(
      'Curing',
      'New concrete is kept moist for at least 7 days, by spraying a curing '
          'compound right after finishing or by keeping it wet under sacks.',
    ),
  ],
  solution: const [
    InfoSection(
      'Concrete',
      'Area times thickness, with the waste allowance, times the mix '
          'factors.',
      formula:
          'volume = length × width × thickness × (1 + waste)\n'
          'cement = round up(volume × bags per m³)',
    ),
    InfoSection(
      'Bars or mesh',
      'Bars both ways inside 40 mm of cover, cut and spliced as in a slab '
          'on fill. Mesh sheets of 1.5 × 6 m lapped 0.15 m each way cover '
          '7.9 m² each.',
      formula:
          'runs = round down((side − 0.08) ÷ spacing) + 1, each way\n'
          'mesh sheets = round up(area ÷ 7.9)',
    ),
    InfoSection(
      'Control joints and sealant',
      'Joints cross the slab at the chosen spacing both ways, or at 30 '
          'times the thickness up to 4.5 m. A 6 × 12 mm bead of sealant '
          'takes 0.079 L per metre with 10% waste.',
      formula:
          'joints = (round up(length ÷ s) − 1) × width + '
          '(round up(width ÷ s) − 1) × length\n'
          'sealant = round up(joints × 0.079 ÷ 0.6) sausages',
    ),
    InfoSection(
      'Base, curing and edge forms',
      'The gravel base covers the area. Curing compound is sprayed at '
          '0.20 L per m². Edge forms run the perimeter, or the edge entered, '
          'as high as the slab, with the column table\'s frame lumber per '
          'sheet.',
      formula:
          'gravel base = area × base\n'
          'curing compound = round up(area × 0.20 ÷ 4) gallons\n'
          'form area = edge × thickness',
    ),
  ],
  references: const [
    'DPWH Standard Specifications, Item 311 (Portland Cement Concrete '
        'Pavement) and Item 200 (Aggregate Subbase Course)',
    'ACI 330R-08, Guide for the Design and Construction of Concrete '
        'Parking Lots (joint spacing)',
    'Max B. Fajardo Jr., Simplified Construction Estimate, Table 1-2',
  ],
);

bool _paveBars(Map<String, String> s) => s['reinforcement'] == 'bars';
