import '../materials/items.dart';
import '../materials/work_items.dart';

/// A wage region with its minimum daily wage for non-agriculture work in
/// mid-October 2026 (the highest band: cities and larger establishments),
/// from the regional wage boards' orders. See docs/prices-and-costing.md,
/// "Daily rates by region".
enum LabourRegion {
  ncr('Metro Manila (NCR)', 755, 'NCR-28', '26 Sep 2026'),
  car('Cordillera (CAR)', 505, 'CAR-24', '30 Dec 2025'),
  ilocos('Ilocos Region (I)', 505, 'RB I-24', '19 Nov 2025'),
  cagayanValley('Cagayan Valley (II)', 500, 'RTWPB II-24', '5 Nov 2025'),
  centralLuzon('Central Luzon (III)', 600, 'RBIII-26', '16 Apr 2026'),
  calabarzon(
    'CALABARZON (IV-A)',
    600,
    'IVA-22',
    '5 Oct 2025',
    next: (645, '26 Oct 2026'),
  ),
  mimaropa('MIMAROPA (IV-B)', 455, 'RB-MIMAROPA-13', '1 Jan 2026'),
  bicol(
    'Bicol Region (V)',
    455,
    'RBV-23',
    '8 Apr 2026',
    next: (480, '1 Dec 2026'),
  ),
  westernVisayas('Western Visayas (VI)', 550, 'RBVI-29', '19 Nov 2025'),
  negros('Negros Island Region (NIR)', 550, 'RBVI-29', '19 Nov 2025'),
  centralVisayas(
    'Central Visayas (VII)',
    582,
    'RTWPB VII, Sep 2026',
    '14 Oct 2026',
  ),
  easternVisayas('Eastern Visayas (VIII)', 470, 'RB VIII-25', '1 Jun 2026'),
  zamboanga('Zamboanga Peninsula (IX)', 464, 'RIX-24', '1 Jun 2026'),
  northernMindanao('Northern Mindanao (X)', 500, 'RX-24', '1 May 2026'),
  davao('Davao Region (XI)', 540, 'RB XI-24', '1 Sep 2026'),
  soccsksargen('SOCCSKSARGEN (XII)', 460, 'RB XII-25', '15 Dec 2025'),
  caraga('Caraga (XIII)', 475, 'RXIII-20', '1 May 2026'),
  barmm(
    'Bangsamoro (BARMM)',
    436,
    'BARMM-06',
    'Jul 2026',
    next: (461, '1 Dec 2026'),
  );

  const LabourRegion(
    this.label,
    this.minimumWage,
    this.wageOrder,
    this.since, {
    this.next,
  });

  final String label;

  /// The minimum daily wage for non-agriculture work, in pesos.
  final double minimumWage;
  final String wageOrder;

  /// When [minimumWage] took effect.
  final String since;

  /// The next increase already set by an order, and when.
  final (double, String)? next;

  /// What an employer pays on top of the daily wage: 13th-month pay
  /// (8.3%), SSS (10% plus EC), PhilHealth (2.5%) and Pag-IBIG (about
  /// 1%).
  static const labourCostFactor = 1.22;

  /// How far above the minimum wage each worker is paid in the market:
  /// helpers at the minimum, skilled workers 20% above and foremen 50%
  /// above. With [labourCostFactor] these give Metro Manila's
  /// [DailyRates.defaults].
  static const tradePremium = <String, double>{
    DailyRates.foreman: 1.5,
    DailyRates.skilled: 1.2,
    DailyRates.helper: 1.0,
  };

  /// The market daily rate for each worker, rounded to ₱50.
  Map<String, double> get rates => {
    for (final MapEntry(:key, :value) in tradePremium.entries)
      key: (minimumWage * value * labourCostFactor / 50).roundToDouble() * 50,
  };

  /// Whether [dailyRates] pays this region's rate for every worker.
  bool matches(Map<String, double> dailyRates) =>
      rates.entries.every((e) => dailyRates[e.key] == e.value);

  /// [projectRates], a project's own daily rates, with this region's
  /// labour rates in place of its labour ones. Equipment is kept, and a
  /// rate equal to the default is left out, as the budget does.
  Map<String, double> applyTo(Map<String, double> projectRates) {
    final result = {...projectRates};
    for (final MapEntry(:key, :value) in rates.entries) {
      if (value == DailyRates.defaults[key]) {
        result.remove(key);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  /// The wage region a price book region stands for, when it is one.
  static LabourRegion? forPriceRegion(PriceRegion region) =>
      region == PriceRegion.metroManila ? ncr : null;
}
