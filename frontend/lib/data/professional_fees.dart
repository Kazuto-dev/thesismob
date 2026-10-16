double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// The building groups of UAP Doc 202, each with the architect's minimum
/// basic fee as a percentage of the project construction cost.
enum BuildingGroup {
  simple(
    6,
    'Group 1: simple buildings',
    'Warehouses, factories, farm buildings, markets',
  ),
  moderate(
    7,
    'Group 2: moderately complex buildings',
    'Schools, offices, stores, fire stations',
  ),
  complex(8, 'Group 3: complex buildings', 'Hospitals, hotels, stadiums'),
  residence(
    10,
    'Group 4: residences',
    'Houses, duplexes, small apartment houses and townhouses',
  ),
  monumental(12, 'Group 5: monumental buildings', 'Monuments and landmarks');

  const BuildingGroup(this.basicFeePct, this.label, this.examples);

  /// The minimum basic fee for design, in percent of the project
  /// construction cost.
  final double basicFeePct;
  final String label;
  final String examples;
}

/// A professional service the owner pays for. Architectural, structural,
/// electrical and plumbing design together make up UAP Doc 202's minimum
/// basic fee for the building group; how it splits between them, and the
/// mechanical design on top, are our own estimates.
enum DesignService {
  architectural('Architectural design', 'Architect (UAP Doc 202)', 0.60),
  structural('Structural design', 'Civil or structural engineer', 0.20),
  electrical('Electrical design', 'Professional electrical engineer', 0.10),
  plumbing(
    'Sanitary and plumbing design',
    'Sanitary engineer or master plumber',
    0.10,
  ),
  mechanical('Mechanical design', 'Professional mechanical engineer', 0.05),
  supervision(
    'Construction supervision, full time',
    'Architect or engineer on site',
    null,
  );

  const DesignService(this.label, this.by, this.shareOfBasicFee);

  final String label;

  /// Who signs or does the work.
  final String by;

  /// The part of the group's minimum basic fee, or null for a service
  /// priced on its own.
  final double? shareOfBasicFee;

  /// Full-time supervision, in percent of the project construction cost:
  /// the top of UAP's 1–1.5%, as small jobs need.
  static const supervisionPct = 1.5;

  /// The usual fee for [group], in percent of the project construction
  /// cost.
  double percentFor(BuildingGroup group) => switch (shareOfBasicFee) {
    final share? => group.basicFeePct * share,
    null => supervisionPct,
  };

  /// Whether a job of [group] usually needs this service.
  bool usualFor(BuildingGroup group) => switch (this) {
    mechanical => group != BuildingGroup.residence,
    supervision => false,
    _ => true,
  };
}

/// The fee for each ticked service at [percents] (by service) of [cost].
Map<DesignService, double> professionalFees(
  double cost,
  Map<DesignService, double> percents,
) => {
  for (final MapEntry(:key, :value) in percents.entries)
    key: cost <= 0 || value <= 0 ? 0 : _centavos(cost * value / 100),
};

/// The usual percentages for [group], for the services it usually needs.
Map<DesignService, double> usualPercents(BuildingGroup group) => {
  for (final s in DesignService.values)
    if (s.usualFor(group)) s: s.percentFor(group),
};
