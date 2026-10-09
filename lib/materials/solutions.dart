// "How it's calculated" content for each calculator. Every formula here
// matches the calculation in the material's spec.

import 'material_spec.dart';

const _contingency = InfoSection(
  'Contingency',
  'A contingency adds extra pieces for cutting waste and breakage. The extra '
      'is the chosen percentage of the base count, rounded up.',
  formula: 'extra = round up(base count × contingency)',
);

List<InfoSection> _perPiece(String items) => [
  InfoSection(
    'Cost',
    'Multiply the number of $items by the price per piece. Any type '
        'you choose describes the item in your summary and does not '
        'change the cost.',
    formula: 'cost = quantity × price per piece',
  ),
];

const Map<String, List<InfoSection>> materialSolutions = {
  'chb': [
    InfoSection(
      'Wall area',
      'Multiply the length of the wall by its height.',
      formula: 'area = length × height',
    ),
    InfoSection(
      'Blocks needed',
      'The face of a standard concrete hollow block is 40 cm × 20 cm, or '
          '0.08 m², whatever its thickness. That is 12.5 blocks per square '
          'metre. Divide the wall area by the block face and round up.',
      formula: 'blocks = round up(area ÷ 0.08)',
    ),
    _contingency,
    InfoSection(
      'Cost',
      'Multiply the total number of blocks by the price per block.',
      formula: 'cost = (blocks + extra) × price per block',
    ),
  ],
  'plywood': [
    InfoSection(
      'Area to cover',
      'Multiply the length of the surface by its width.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Sheets needed',
      "A 4' × 8' sheet is 1.22 m × 2.44 m, or 2.97 m². Divide the area by "
          'the sheet area and round up, since plywood is sold by the sheet.',
      formula: 'sheets = round up(area ÷ 2.97)',
    ),
    _contingency,
    InfoSection(
      'Cost',
      'Multiply the total number of sheets by the price per sheet.',
      formula: 'cost = (sheets + extra) × price per sheet',
    ),
  ],
  'insulation': [
    InfoSection(
      'Area to insulate',
      'Multiply the length of the area by its width.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Rolls needed',
      'A 1 m × 50 m roll covers 50 m². Divide the area by the roll coverage '
          'and round up. Thickness and type describe the product and do not '
          'change the number of rolls.',
      formula: 'rolls = round up(area ÷ 50)',
    ),
    InfoSection(
      'Cost',
      'Multiply the number of rolls by the price per roll.',
      formula: 'cost = rolls × price per roll',
    ),
  ],
  'paint': [
    InfoSection(
      'Area to paint',
      'Multiply the length of the surface by its width. To paint a whole '
          'room, add up the area of each wall, or run the calculator once per '
          'wall.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Paint needed',
      'Every coat covers the whole area again. Divide by the coverage printed '
          'on the can (square metres per litre) to get litres, then convert to '
          'gallons.',
      formula: 'litres = area × coats ÷ coverage\ngallons = litres ÷ 3.785',
    ),
    InfoSection(
      'Cans and cost',
      'Paint is sold in whole gallons, so the gallons are rounded up before '
          'multiplying by the price per gallon.',
      formula: 'cost = round up(gallons) × price per gallon',
    ),
  ],
  'tiles': [
    InfoSection(
      'Area to tile',
      'Multiply the length of the room by its width.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Tiles needed',
      'Divide the area by the area of one tile, for example 30 cm × 30 cm = '
          '0.09 m². Round up, since tiles are not sold in fractions.',
      formula: 'tiles = round up(area ÷ tile area)',
    ),
    _contingency,
    InfoSection(
      'Cost',
      'Multiply the total number of tiles by the price per tile.',
      formula: 'cost = (tiles + extra) × price per tile',
    ),
  ],
  'roof': [
    InfoSection(
      'Roof area',
      'Multiply the length of the roof by its width, measured along the '
          'slope.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Ribbed sheets',
      'Each ribbed sheet covers its full width times its length.',
      formula: 'sheets = round up(area ÷ (sheet width × sheet length))',
    ),
    InfoSection(
      'Corrugated sheets',
      'Corrugated sheets overlap their neighbours sideways by 1.5 or 2.5 '
          'corrugations, about 7.6 cm each, so a sheet covers less than its '
          'full width. Lengthwise end laps are not included.',
      formula:
          'covered width = sheet width − 0.0762 m × corrugations\n'
          'sheets = round up(area ÷ (covered width × sheet length))',
    ),
    InfoSection(
      'Cost',
      'Multiply the number of sheets by the price per sheet.',
      formula: 'cost = sheets × price per sheet',
    ),
  ],
  'carpet': [
    InfoSection(
      'Area to cover',
      'Multiply the length of the room by its width.',
      formula: 'area = length × width',
    ),
    InfoSection(
      'Carpets needed',
      'Divide the area by the size of one carpet, for example 1.6 m × 2.3 m '
          '= 3.68 m², and round up.',
      formula: 'carpets = round up(area ÷ carpet size)',
    ),
    _contingency,
    InfoSection(
      'Cost',
      'Multiply the total number of carpets by the price per piece.',
      formula: 'cost = (carpets + extra) × price per piece',
    ),
  ],
  'wallpaper': [
    InfoSection(
      'Wall area',
      'Multiply the width of the wall by its height.',
      formula: 'area = width × height',
    ),
    InfoSection(
      'Rolls needed',
      'Divide the wall area by the area one roll covers and round up.',
      formula: 'rolls = round up(area ÷ roll coverage)',
    ),
    _contingency,
    InfoSection(
      'Cost',
      'Multiply the total number of rolls by the price per roll.',
      formula: 'cost = (rolls + extra) × price per roll',
    ),
  ],
  'wires': [
    InfoSection(
      'Cost',
      'Multiply the length of wire, in metres, by the price per metre. The '
          'wire type describes the item in your summary and does not change '
          'the cost.',
      formula: 'cost = length × price per metre',
    ),
  ],
};

/// Solution for materials bought by the piece; [items] is the plural noun,
/// e.g. `junction boxes`.
List<InfoSection> perPieceSolution(String items) => _perPiece(items);
