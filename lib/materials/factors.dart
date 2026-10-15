// Estimating factors shared by several calculators. Sources are listed in
// docs/calculations.md.

/// A site-mixed concrete class: 40 kg cement bags, m³ of sand and m³ of
/// gravel per m³ of concrete (Fajardo, Simplified Construction Estimate,
/// Table 1-2). These are not DPWH classes, which are set by strength.
typedef ConcreteMix = ({
  String id,
  String label,
  String ratio,
  double cement,
  double sand,
  double gravel,
});

const concreteMixes = <ConcreteMix>[
  (
    id: 'AA',
    label: 'Class AA',
    ratio: '1 : 1.5 : 3',
    cement: 12.0,
    sand: 0.5,
    gravel: 1.0,
  ),
  (
    id: 'A',
    label: 'Class A',
    ratio: '1 : 2 : 4',
    cement: 9.0,
    sand: 0.5,
    gravel: 1.0,
  ),
  (
    id: 'B',
    label: 'Class B',
    ratio: '1 : 2.5 : 5',
    cement: 7.5,
    sand: 0.5,
    gravel: 1.0,
  ),
  (
    id: 'C',
    label: 'Class C',
    ratio: '1 : 3 : 6',
    cement: 6.0,
    sand: 0.5,
    gravel: 1.0,
  ),
];

ConcreteMix concreteMix(String id) =>
    concreteMixes.firstWhere((m) => m.id == id);

/// Class B mortar (1:3): 40 kg bags of cement and m³ of sand per m³.
const mortarClassB = (cement: 12.0, sand: 1.0);

/// Class B mortar to lay one m² of hollow-block wall, by block thickness
/// in inches (Fajardo Table 2-2).
const chbMortar = {
  '4': (cement: 0.522, sand: 0.0435),
  '6': (cement: 1.018, sand: 0.0844),
  '8': (cement: 1.500, sand: 0.1250),
};

/// Class B plaster 16 mm thick, per m² of each plastered face.
const plasterCement = 0.192;
const plasterSand = 0.016;

/// A hollow block with its joint covers 0.40 × 0.20 m: 12.5 per m².
const chbPerSquareMetre = 12.5;

/// Commercial length of reinforcing bars sold at hardware stores.
const rebarStockLength = 6.0;

/// #16 tie wire: about 53 m per kg, which allows for some waste.
const tieWireMetresPerKg = 53.0;

/// Tie wire cut per bar intersection: 0.30 m for bars up to 12 mm,
/// 0.40 m for larger bars.
double tieWirePerTie(int barMm) => barMm <= 12 ? 0.30 : 0.40;

/// A 4' × 8' sheet (1.22 × 2.44 m) as most estimating tables count it:
/// 1.20 × 2.40 m = 2.88 m² of usable form or ceiling area.
const sheetFormArea = 2.88;

/// The full face of a 4' × 8' sheet: 1.22 × 2.44 m.
const sheetArea = 1.22 * 2.44;
