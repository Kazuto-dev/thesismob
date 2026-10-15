import 'package:flutter/foundation.dart';

import '../materials/catalog.dart';
import '../materials/items.dart';
import '../materials/material_spec.dart';
import 'estimate.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

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

  /// This preset's markups with the job's own labour and hauling.
  CostSettings keepingJobCosts(CostSettings job) => copyWith(
    labourPct: job.labourPct,
    labourByTrade: job.labourByTrade,
    hauling: job.hauling,
  );

  factory CostSettings.fromJson(Map<String, dynamic> json) {
    double pct(String key, double fallback) {
      final v = json[key];
      return v is num && v.isFinite && v >= 0 ? v.toDouble() : fallback;
    }

    return CostSettings(
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
  }) => CostSettings(
    labourPct: labourPct ?? this.labourPct,
    labourByTrade: labourByTrade ?? this.labourByTrade,
    toolsPct: toolsPct ?? this.toolsPct,
    hauling: hauling ?? this.hauling,
    contingencyPct: contingencyPct ?? this.contingencyPct,
    overheadPct: overheadPct ?? this.overheadPct,
    profitPct: profitPct ?? this.profitPct,
    vatPct: vatPct ?? this.vatPct,
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
      other.vatPct == vatPct;

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
    required this.contingency,
    required this.overhead,
    required this.profit,
    required this.vat,
  });

  factory CostBreakdown.of(List<Estimate> items, CostSettings s) {
    final byTrade = <MaterialCategory?, double>{};
    for (final e in items) {
      final trade = materialById(e.materialId)?.category;
      byTrade[trade] = (byTrade[trade] ?? 0) + e.grandTotal;
    }
    final materials = _centavos(
      byTrade.values.fold<double>(0, (sum, v) => sum + v),
    );
    final labour = _centavos(
      byTrade.entries.fold<double>(
        0,
        (sum, e) => sum + e.value * s.labourFor(e.key) / 100,
      ),
    );
    final tools = _centavos(labour * s.toolsPct / 100);
    final direct = materials + labour + tools + s.hauling;
    return CostBreakdown(
      materials: materials,
      materialsByTrade: {
        for (final e in byTrade.entries) e.key: _centavos(e.value),
      },
      labour: labour,
      tools: tools,
      hauling: _centavos(s.hauling),
      contingency: _centavos(direct * s.contingencyPct / 100),
      overhead: _centavos(direct * s.overheadPct / 100),
      profit: _centavos(direct * s.profitPct / 100),
      vat: _centavos(
        (direct +
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
  final double contingency;
  final double overhead;
  final double profit;
  final double vat;

  /// Materials, labour, tools and hauling.
  double get direct => _centavos(materials + labour + tools + hauling);

  /// Before tax.
  double get subtotal => _centavos(direct + contingency + overhead + profit);

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
    this.items = const [],
    this.costs = CostSettings.owner,
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
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      items: List.unmodifiable(items),
      costs: json['costs'] is Map<String, dynamic>
          ? CostSettings.fromJson(json['costs'] as Map<String, dynamic>)
          : CostSettings.owner,
    );
  }

  final String id;
  final String name;
  final String client;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The estimates in this project, in the order they were added.
  final List<Estimate> items;
  final CostSettings costs;

  /// Cost of all materials, companions included.
  double get materialsTotal =>
      _centavos(items.fold<double>(0, (sum, e) => sum + e.grandTotal));

  CostBreakdown get breakdown => CostBreakdown.of(items, costs);

  List<MaterialLine> get materials => consolidate(items);

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? location,
    List<Estimate>? items,
    CostSettings? costs,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    client: client ?? this.client,
    location: location ?? this.location,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    items: items ?? this.items,
    costs: costs ?? this.costs,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (client.isNotEmpty) 'client': client,
    if (location.isNotEmpty) 'location': location,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': [for (final e in items) e.toJson()],
    'costs': costs.toJson(),
  };
}
