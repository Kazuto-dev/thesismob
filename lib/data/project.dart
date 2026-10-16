import 'package:flutter/foundation.dart';

import '../materials/catalog.dart';
import '../materials/items.dart';
import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'contract.dart';
import 'contract_math.dart';
import 'estimate.dart';
import 'quotes.dart';
import 'revisions.dart';
import 'unit_prices.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// How labour is priced: from each work item's crew and daily output, or
/// as a share of the materials.
enum LabourMethod { crews, percent }

/// The general requirements of a job: costs of running the site rather
/// than of any one work item, each a lump sum (DPWH Part A and B).
const generalRequirements = <String, String>{
  'mobilization': 'Mobilization and demobilization',
  'temporary': 'Temporary facilities: bodega, toilet, power and water',
  'permits': 'Permits, clearances and fees',
  'professional': 'Professional fees: plans, design and signing',
  'insurance': 'Contractor\'s all-risk insurance and bonds',
  'safety': 'Occupational safety and health',
  'signboard': 'Project signboard',
  'cleanup': 'Clean-up and disposal of debris',
};

/// General requirements that cost so much a month for as long as the job
/// runs, so a longer schedule costs more.
const timeRelatedRequirements = <String, String>{
  'supervision': 'Site engineer and supervision',
  'security': 'Watchman or security guard',
  'utilities': 'Power and water bills',
  'transport': 'Transport, phone and site office supplies',
};

double _toNearest500(double v) => (v / 500).ceilToDouble() * 500;

/// Typical one-time general requirements for a small building with
/// [direct] cost of work, rounded to ₱500: about 4% in all plus a
/// signboard. Professional fees are the owner's and left out.
Map<String, double> suggestGeneralRequirements(double direct) {
  double share(double pct) => _toNearest500(direct * pct / 100);
  return {
    'mobilization': share(0.75),
    'temporary': share(1),
    'permits': share(1),
    'insurance': share(0.3),
    'safety': share(0.5),
    'signboard': direct > 0 ? 5000 : 0,
    'cleanup': share(0.5),
  }..removeWhere((_, v) => v <= 0);
}

/// Typical monthly site costs for a job with [direct] cost of work: a
/// share of an engineer's time on small jobs and a full-time one on large
/// ones, a watchman, utilities and transport.
Map<String, double> suggestMonthlyRequirements(double direct) {
  if (direct <= 0) return const {};
  final scale = switch (direct) {
    < 3000000 => 1.0,
    < 10000000 => 2.0,
    _ => 3.5,
  };
  return {
    'supervision': _toNearest500(8000 * scale),
    'security': direct < 1000000 ? 0 : _toNearest500(8000 * scale.clamp(1, 2)),
    'utilities': _toNearest500(2000 * scale),
    'transport': _toNearest500(2000 * scale),
  }..removeWhere((_, v) => v <= 0);
}

/// How a project's material cost is built up into a budget or a bid.
/// Percentages are whole numbers (35 means 35%).
@immutable
class CostSettings {
  const CostSettings({
    this.labourPct = 40,
    this.labourByTrade = const {},
    this.toolsPct = 0,
    this.hauling = 0,
    this.contingencyPct = 10,
    this.overheadPct = 0,
    this.profitPct = 0,
    this.vatPct = 0,
    this.labourMethod = LabourMethod.crews,
    this.rates = const {},
    this.productivityPct = 100,
    this.general = const {},
    this.monthly = const {},
    this.escalationPct = 0,
  });

  /// For an owner hiring workers directly: materials, labour, a margin for
  /// surprises, and no contractor markups.
  static const owner = CostSettings();

  /// For a contractor's quotation on private work: minor tools on labour,
  /// overhead, profit and 12% VAT.
  static const contractor = CostSettings(
    labourPct: 40,
    toolsPct: 10,
    contingencyPct: 5,
    overheadPct: 10,
    profitPct: 10,
    vatPct: 12,
  );

  /// For a government estimate following DPWH practice (DO 197 s.2016,
  /// kept by DO 30 s.2025): overhead, contingencies and miscellaneous
  /// (OCM) and profit by the size of the direct cost, minor tools at 10% of
  /// labour and 5% VAT. The contingency is inside the OCM.
  factory CostSettings.dpwh(double directCost, {CostSettings? from}) {
    final (ocm, profit) = dpwhMarkups(directCost);
    return CostSettings(
      labourPct: from?.labourPct ?? 40,
      labourByTrade: from?.labourByTrade ?? const {},
      toolsPct: 10,
      hauling: from?.hauling ?? 0,
      contingencyPct: 0,
      overheadPct: ocm,
      profitPct: profit,
      vatPct: 5,
      labourMethod: from?.labourMethod ?? LabourMethod.crews,
      rates: from?.rates ?? const {},
      productivityPct: from?.productivityPct ?? 100,
      general: from?.general ?? const {},
      monthly: from?.monthly ?? const {},
      escalationPct: from?.escalationPct ?? 0,
    );
  }

  /// DPWH OCM and profit percentages for an estimated direct cost.
  static (double, double) dpwhMarkups(double directCost) =>
      switch (directCost) {
        <= 5000000 => (15, 10),
        <= 50000000 => (12, 8),
        <= 150000000 => (10, 8),
        _ => (8, 8),
      };

  /// This preset's markups with the job's own labour, rates, hauling and
  /// general requirements.
  CostSettings keepingJobCosts(CostSettings job) => copyWith(
    labourPct: job.labourPct,
    labourByTrade: job.labourByTrade,
    hauling: job.hauling,
    labourMethod: job.labourMethod,
    rates: job.rates,
    productivityPct: job.productivityPct,
    general: job.general,
    monthly: job.monthly,
    escalationPct: job.escalationPct,
  );

  factory CostSettings.fromJson(Map<String, dynamic> json) {
    double pct(String key, double fallback) {
      final v = json[key];
      return v is num && v.isFinite && v >= 0 ? v.toDouble() : fallback;
    }

    Map<String, double> amounts(String key) => {
      for (final e in (json[key] as Map? ?? const {}).entries)
        if (e.key is String &&
            e.value is num &&
            (e.value as num).isFinite &&
            (e.value as num) >= 0)
          e.key as String: (e.value as num).toDouble(),
    };

    return CostSettings(
      // Projects saved before crews existed keep their percentage.
      labourMethod: LabourMethod.values.firstWhere(
        (m) => m.name == json['labourMethod'],
        orElse: () => LabourMethod.percent,
      ),
      rates: amounts('rates'),
      productivityPct: pct('productivityPct', 100),
      general: amounts('general'),
      monthly: amounts('monthly'),
      escalationPct: pct('escalationPct', 0),
      labourPct: pct('labourPct', 40),
      labourByTrade: {
        for (final e in (json['labourByTrade'] as Map? ?? const {}).entries)
          if (e.key is String && e.value is num && (e.value as num) >= 0)
            e.key as String: (e.value as num).toDouble(),
      },
      toolsPct: pct('toolsPct', 0),
      hauling: pct('hauling', 0),
      contingencyPct: pct('contingencyPct', 10),
      overheadPct: pct('overheadPct', 0),
      profitPct: pct('profitPct', 0),
      vatPct: pct('vatPct', 0),
    );
  }

  /// Labour as a percentage of material cost, for trades without their own.
  final double labourPct;

  /// Labour percentages for particular trades, keyed by category name.
  final Map<String, double> labourByTrade;

  /// Minor tools and equipment, as a percentage of labour.
  final double toolsPct;

  /// Delivery and hauling, in pesos.
  final double hauling;

  /// Allowance for surprises, as a percentage of direct cost.
  final double contingencyPct;

  /// Contractor's overhead, as a percentage of direct cost.
  final double overheadPct;

  /// Contractor's profit, as a percentage of direct cost.
  final double profitPct;

  /// Value-added tax on the price before tax.
  final double vatPct;

  final LabourMethod labourMethod;

  /// Daily rates that differ from [DailyRates.defaults], by key.
  final Map<String, double> rates;

  /// How fast the crews work against the usual outputs, in percent: 80
  /// means slower crews and 25% more crew-days.
  final double productivityPct;

  /// General requirements in pesos, by [generalRequirements] key.
  final Map<String, double> general;

  /// Time-related general requirements in pesos a month, by
  /// [timeRelatedRequirements] key.
  final Map<String, double> monthly;

  /// Expected rise in prices before the work is bought, as a percentage of
  /// the direct cost.
  final double escalationPct;

  /// Every daily rate, the project's own where set.
  Map<String, double> get dailyRates => {...DailyRates.defaults, ...rates};

  /// The one-time general requirements together.
  double get generalTotal => general.values.fold(0, (sum, v) => sum + v);

  /// The time-related general requirements for one month.
  double get monthlyTotal => monthly.values.fold(0, (sum, v) => sum + v);

  double labourFor(MaterialCategory? trade) =>
      (trade == null ? null : labourByTrade[trade.name]) ?? labourPct;

  bool get isContractorBid => overheadPct > 0 || profitPct > 0 || vatPct > 0;

  CostSettings copyWith({
    double? labourPct,
    Map<String, double>? labourByTrade,
    double? toolsPct,
    double? hauling,
    double? contingencyPct,
    double? overheadPct,
    double? profitPct,
    double? vatPct,
    LabourMethod? labourMethod,
    Map<String, double>? rates,
    double? productivityPct,
    Map<String, double>? general,
    Map<String, double>? monthly,
    double? escalationPct,
  }) => CostSettings(
    labourPct: labourPct ?? this.labourPct,
    labourByTrade: labourByTrade ?? this.labourByTrade,
    toolsPct: toolsPct ?? this.toolsPct,
    hauling: hauling ?? this.hauling,
    contingencyPct: contingencyPct ?? this.contingencyPct,
    overheadPct: overheadPct ?? this.overheadPct,
    profitPct: profitPct ?? this.profitPct,
    vatPct: vatPct ?? this.vatPct,
    labourMethod: labourMethod ?? this.labourMethod,
    rates: rates ?? this.rates,
    productivityPct: productivityPct ?? this.productivityPct,
    general: general ?? this.general,
    monthly: monthly ?? this.monthly,
    escalationPct: escalationPct ?? this.escalationPct,
  );

  Map<String, dynamic> toJson() => {
    'labourPct': labourPct,
    if (labourByTrade.isNotEmpty) 'labourByTrade': labourByTrade,
    'toolsPct': toolsPct,
    'hauling': hauling,
    'contingencyPct': contingencyPct,
    'overheadPct': overheadPct,
    'profitPct': profitPct,
    'vatPct': vatPct,
    'labourMethod': labourMethod.name,
    if (rates.isNotEmpty) 'rates': rates,
    if (productivityPct != 100) 'productivityPct': productivityPct,
    if (general.isNotEmpty) 'general': general,
    if (monthly.isNotEmpty) 'monthly': monthly,
    if (escalationPct != 0) 'escalationPct': escalationPct,
  };

  @override
  bool operator ==(Object other) =>
      other is CostSettings &&
      other.labourPct == labourPct &&
      mapEquals(other.labourByTrade, labourByTrade) &&
      other.toolsPct == toolsPct &&
      other.hauling == hauling &&
      other.contingencyPct == contingencyPct &&
      other.overheadPct == overheadPct &&
      other.profitPct == profitPct &&
      other.vatPct == vatPct &&
      other.labourMethod == labourMethod &&
      mapEquals(other.rates, rates) &&
      other.productivityPct == productivityPct &&
      mapEquals(other.general, general) &&
      mapEquals(other.monthly, monthly) &&
      other.escalationPct == escalationPct;

  @override
  int get hashCode => Object.hash(
    labourPct,
    Object.hashAllUnordered(labourByTrade.entries.map((e) => e.toString())),
    toolsPct,
    hauling,
    contingencyPct,
    overheadPct,
    profitPct,
    vatPct,
    labourMethod,
    Object.hashAllUnordered(rates.entries.map((e) => e.toString())),
    productivityPct,
    Object.hashAllUnordered(general.entries.map((e) => e.toString())),
    Object.hashAllUnordered(monthly.entries.map((e) => e.toString())),
    escalationPct,
  );
}

/// A project's cost, step by step from materials to the final price.
@immutable
class CostBreakdown {
  const CostBreakdown({
    required this.materials,
    required this.materialsByTrade,
    required this.labour,
    required this.tools,
    required this.hauling,
    this.equipment = 0,
    this.general = 0,
    this.timeRelated = 0,
    this.months = 0,
    this.crewDays = 0,
    this.escalation = 0,
    required this.contingency,
    required this.overhead,
    required this.profit,
    required this.vat,
  });

  /// [months] is how long the job runs, for the time-related general
  /// requirements.
  factory CostBreakdown.of(
    List<Estimate> items,
    CostSettings s, {
    double months = 0,
  }) {
    final byTrade = <MaterialCategory?, double>{};
    for (final e in items) {
      final trade = materialById(e.materialId)?.category;
      byTrade[trade] = (byTrade[trade] ?? 0) + e.grandTotal;
    }
    final materials = _centavos(
      byTrade.values.fold<double>(0, (sum, v) => sum + v),
    );
    var labourSum = 0.0;
    var equipmentSum = 0.0;
    var days = 0.0;
    for (final e in items) {
      final cost = labourOf(e, s);
      labourSum += cost.labour;
      equipmentSum += cost.equipment;
      days += cost.crewDays;
    }
    final labour = _centavos(labourSum);
    final equipment = _centavos(equipmentSum);
    final tools = _centavos(labour * s.toolsPct / 100);
    final timeRelated = _centavos(s.monthlyTotal * months);
    final general = _centavos(s.generalTotal + timeRelated);
    final direct = materials + labour + tools + equipment + s.hauling + general;
    return CostBreakdown(
      materials: materials,
      materialsByTrade: {
        for (final e in byTrade.entries) e.key: _centavos(e.value),
      },
      labour: labour,
      tools: tools,
      equipment: equipment,
      general: general,
      timeRelated: timeRelated,
      months: months,
      crewDays: days,
      hauling: _centavos(s.hauling),
      escalation: _centavos(direct * s.escalationPct / 100),
      contingency: _centavos(direct * s.contingencyPct / 100),
      overhead: _centavos(direct * s.overheadPct / 100),
      profit: _centavos(direct * s.profitPct / 100),
      vat: _centavos(
        (direct +
                direct * s.escalationPct / 100 +
                direct * s.contingencyPct / 100 +
                direct * s.overheadPct / 100 +
                direct * s.profitPct / 100) *
            s.vatPct /
            100,
      ),
    );
  }

  final double materials;

  /// Material cost per trade; null holds items of no known trade.
  final Map<MaterialCategory?, double> materialsByTrade;
  final double labour;
  final double tools;
  final double hauling;

  /// Rented equipment such as concrete mixers, from the crews.
  final double equipment;

  /// General requirements: mobilization, temporary facilities and the
  /// like, the time-related ones included.
  final double general;

  /// The part of [general] that costs so much a month.
  final double timeRelated;

  /// How long the job runs, in months, for [timeRelated].
  final double months;

  /// Crew-days of work, when labour is priced by crews.
  final double crewDays;

  /// Price escalation until the work is bought.
  final double escalation;
  final double contingency;
  final double overhead;
  final double profit;
  final double vat;

  /// Materials, labour, tools, equipment, hauling and general
  /// requirements.
  double get direct =>
      _centavos(materials + labour + tools + equipment + hauling + general);

  /// Before tax.
  double get subtotal =>
      _centavos(direct + escalation + contingency + overhead + profit);

  double get total => _centavos(subtotal + vat);
}

/// One line of the shopping list: everything of one material across a
/// project, e.g. all the cement from walls, plaster and slab.
@immutable
class MaterialLine {
  const MaterialLine({
    required this.key,
    required this.label,
    required this.unit,
    required this.quantity,
    required this.amount,
    required this.group,
  });

  final String key;
  final String label;
  final String unit;
  final double quantity;
  final double amount;
  final ItemGroup group;

  /// Average price per unit, when estimates used different prices.
  double get unitPrice =>
      quantity == 0 ? 0 : (amount / quantity * 100).roundToDouble() / 100;
}

const _groupOfTrade = {
  MaterialCategory.structural: ItemGroup.masonry,
  MaterialCategory.architectural: ItemGroup.paint,
  MaterialCategory.electrical: ItemGroup.electrical,
  MaterialCategory.plumbing: ItemGroup.plumbing,
};

/// The shopping-list key of an estimate's main material.
String mainKeyOf(Estimate e) =>
    e.itemKey ?? 'estimate:${e.label}|${e.unit.name}';

/// Merges the main materials and companions of [items] by material, so a
/// project's cement, sand and bars each appear once.
List<MaterialLine> consolidate(List<Estimate> items) {
  final lines = <String, MaterialLine>{};
  void add(
    String key,
    String label,
    String unit,
    double quantity,
    double amount,
    ItemGroup group,
  ) {
    final existing = lines[key];
    lines[key] = MaterialLine(
      key: key,
      label: existing?.label ?? label,
      unit: unit,
      quantity: (existing?.quantity ?? 0) + quantity,
      amount: _centavos((existing?.amount ?? 0) + amount),
      group: existing?.group ?? group,
    );
  }

  for (final e in items) {
    final item = e.itemKey == null ? null : itemByKey(e.itemKey!);
    final trade = materialById(e.materialId)?.category;
    add(
      mainKeyOf(e),
      item?.name ?? e.label,
      e.unit.labelFor(e.quantity),
      e.quantity,
      e.total,
      item?.group ?? _groupOfTrade[trade] ?? ItemGroup.other,
    );
    for (final l in e.companions) {
      final companionItem = itemByKey(l.itemKey);
      add(
        l.itemKey,
        companionItem?.name ?? l.label,
        l.unit,
        l.quantity,
        l.total,
        companionItem?.group ?? ItemGroup.other,
      );
    }
  }
  final result = lines.values.map((line) {
    final item = itemByKey(line.key);
    final quantity = (line.quantity * 1000).roundToDouble() / 1000;
    return MaterialLine(
      key: line.key,
      label: line.label,
      unit: item?.unitFor(quantity) ?? line.unit,
      quantity: quantity,
      amount: line.amount,
      group: line.group,
    );
  }).toList();
  result.sort((a, b) {
    final g = a.group.index.compareTo(b.group.index);
    return g != 0 ? g : a.label.compareTo(b.label);
  });
  return result;
}

// A project never changes, so its schedule and costs are worked out once.
final _months = Expando<double>();
final _breakdowns = Expando<CostBreakdown>();

/// A line of general requirements in a bill of quantities: a lump sum, a
/// monthly cost over the job's months, or hauling.
typedef GeneralLine = ({
  String key,
  String description,
  double quantity,
  String unit,
  double unitPrice,
  double amount,
});

/// The project's general requirements, line by line, adding up to its
/// [CostBreakdown.general] plus hauling.
List<GeneralLine> generalLines(Project project) {
  final c = project.costs;
  final months = project.breakdown.months;
  return [
    for (final MapEntry(:key, :value) in generalRequirements.entries)
      if ((c.general[key] ?? 0) > 0)
        (
          key: key,
          description: value,
          quantity: 1,
          unit: 'lot',
          unitPrice: c.general[key]!,
          amount: _centavos(c.general[key]!),
        ),
    if (months > 0)
      for (final MapEntry(:key, :value) in timeRelatedRequirements.entries)
        if ((c.monthly[key] ?? 0) > 0)
          (
            key: key,
            description: value,
            quantity: (months * 100).roundToDouble() / 100,
            unit: 'month',
            unitPrice: c.monthly[key]!,
            amount: _centavos(c.monthly[key]! * months),
          ),
    if (c.hauling > 0)
      (
        key: 'hauling',
        description: 'Hauling and delivery of materials',
        quantity: 1,
        unit: 'lot',
        unitPrice: c.hauling,
        amount: _centavos(c.hauling),
      ),
  ];
}

/// A job being estimated: a house, a renovation, a client's building.
@immutable
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.client = '',
    this.location = '',
    this.floorArea,
    this.items = const [],
    this.costs = CostSettings.owner,
    this.sheetId,
    this.checklist = const [],
    this.notNeeded = const {},
    this.contract = const ContractData(),
    // Estimate revisions and quotes from bidders.
    this.revisions = const [],
    this.quotes = const [],
  });

  factory Project.create(String name, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return Project(
      id: Estimate.newId(at),
      name: name,
      createdAt: at,
      updatedAt: at,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw FormatException('Project is missing an id or name', json);
    }
    DateTime date(String key) =>
        DateTime.tryParse(json[key] is String ? json[key] as String : '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final items = <Estimate>[];
    for (final raw in json['items'] as List? ?? const []) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        items.add(Estimate.fromJson(raw));
      } on FormatException {
        // Skip a damaged entry rather than losing the project.
      }
    }
    return Project(
      id: id,
      name: name,
      client: json['client'] is String ? json['client'] as String : '',
      location: json['location'] is String ? json['location'] as String : '',
      floorArea: json['floorArea'] is num && (json['floorArea'] as num) > 0
          ? (json['floorArea'] as num).toDouble()
          : null,
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      items: List.unmodifiable(items),
      costs: json['costs'] is Map<String, dynamic>
          ? CostSettings.fromJson(json['costs'] as Map<String, dynamic>)
          : CostSettings.owner,
      sheetId: json['sheetId'] is String ? json['sheetId'] as String : null,
      checklist: List.unmodifiable([
        for (final id in json['checklist'] as List? ?? const [])
          if (id is String) id,
      ]),
      notNeeded: Set.unmodifiable({
        for (final id in json['notNeeded'] as List? ?? const [])
          if (id is String) id,
      }),
      contract: json['contract'] is Map<String, dynamic>
          ? ContractData.fromJson(json['contract'] as Map<String, dynamic>)
          : const ContractData(),
      // Estimate revisions and quotes from bidders.
      revisions: revisionsFromJson(json['revisions']),
      quotes: quotesFromJson(json['quotes']),
    );
  }

  final String id;
  final String name;
  final String client;
  final String location;

  /// Total floor area in m², for cost-per-m² checks.
  final double? floorArea;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The estimates in this project, in the order they were added.
  final List<Estimate> items;
  final CostSettings costs;

  /// The Google spreadsheet this project was last saved to, if any.
  final String? sheetId;

  /// Calculators the job needs, by material id, from a checklist such as
  /// the house checklist. Empty when the project has no checklist.
  final List<String> checklist;

  /// Checklist entries the user marked as not needed for this job.
  final Set<String> notNeeded;

  /// Quotation terms, schedule, billings, changes and actual costs.
  final ContractData contract;

  /// Saved copies of the estimate, oldest first; see [addRevision].
  final List<EstimateRevision> revisions;

  /// Prices from bidders and subcontractors, to compare with the estimate.
  final List<BidQuote> quotes;

  /// Whether the checklist entry [materialId] has an estimate.
  bool isEstimated(String materialId) =>
      items.any((e) => e.materialId == materialId);

  /// Checklist entries still to estimate, in order.
  List<String> get checklistToDo => [
    for (final id in checklist)
      if (!isEstimated(id) && !notNeeded.contains(id)) id,
  ];

  /// Cost of all materials, companions included.
  double get materialsTotal =>
      _centavos(items.fold<double>(0, (sum, e) => sum + e.grandTotal));

  /// How long the job runs, in months, from its schedule.
  double get months =>
      _months[this] ??= (Schedule.of(this).months * 100).roundToDouble() / 100;

  CostBreakdown get breakdown =>
      _breakdowns[this] ??= CostBreakdown.of(items, costs, months: months);

  List<MaterialLine> get materials => consolidate(items);

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? location,
    double? floorArea,
    List<Estimate>? items,
    CostSettings? costs,
    String? sheetId,
    List<String>? checklist,
    Set<String>? notNeeded,
    ContractData? contract,
    List<EstimateRevision>? revisions,
    List<BidQuote>? quotes,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    client: client ?? this.client,
    location: location ?? this.location,
    floorArea: floorArea == null
        ? this.floorArea
        : floorArea <= 0
        ? null
        : floorArea,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    items: items ?? this.items,
    costs: costs ?? this.costs,
    sheetId: sheetId ?? this.sheetId,
    checklist: checklist ?? this.checklist,
    notNeeded: notNeeded ?? this.notNeeded,
    contract: contract ?? this.contract,
    revisions: revisions ?? this.revisions,
    quotes: quotes ?? this.quotes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (client.isNotEmpty) 'client': client,
    if (location.isNotEmpty) 'location': location,
    if (floorArea != null) 'floorArea': floorArea,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': [for (final e in items) e.toJson()],
    'costs': costs.toJson(),
    if (sheetId != null) 'sheetId': sheetId,
    if (checklist.isNotEmpty) 'checklist': checklist,
    if (notNeeded.isNotEmpty) 'notNeeded': notNeeded.toList(),
    if (!contract.isEmpty) 'contract': contract.toJson(),
    if (revisions.isNotEmpty) 'revisions': revisionsToJson(revisions),
    if (quotes.isNotEmpty) 'quotes': [for (final q in quotes) q.toJson()],
  };
}
