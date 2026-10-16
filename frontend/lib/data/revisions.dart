import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'estimate.dart';
import 'project.dart';
import 'unit_prices.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// How many revisions a project keeps; saving another drops the oldest.
const maxRevisions = 20;

/// A saved copy of a project's estimate, its items and cost settings, as
/// it was on [date]: "Rev 2 – client removed the second bathroom".
@immutable
class EstimateRevision {
  const EstimateRevision({
    required this.number,
    required this.date,
    this.note = '',
    this.items = const [],
    this.costs = CostSettings.owner,
  });

  /// Counts up from 1 and is never reused, even after older revisions are
  /// dropped or deleted.
  final int number;
  final DateTime date;

  /// What changed in this revision, in the user's words.
  final String note;
  final List<Estimate> items;
  final CostSettings costs;

  /// "Rev 2"
  String get label => 'Rev $number';

  /// [project] with this revision's estimate in place of its own, to work
  /// out totals and documents the same way as for the project itself.
  Project applyTo(Project project) => project.copyWith(
    items: items,
    costs: costs,
    updatedAt: project.updatedAt,
  );
}

String _itemsJson(List<Estimate> items) =>
    jsonEncode([for (final e in items) e.toJson()]);

/// The number the next revision of [project] gets.
int nextRevisionNumber(Project project) => project.revisions.fold(
  1,
  (next, r) => r.number >= next ? r.number + 1 : next,
);

/// [project]'s revisions with its current estimate saved as the next one,
/// keeping the newest [maxRevisions].
List<EstimateRevision> addRevision(
  Project project,
  String note, {
  DateTime? now,
}) {
  final all = [
    ...project.revisions,
    EstimateRevision(
      number: nextRevisionNumber(project),
      date: now ?? DateTime.now(),
      note: note.trim(),
      items: project.items,
      costs: project.costs,
    ),
  ];
  return List.unmodifiable(
    all.length > maxRevisions ? all.sublist(all.length - maxRevisions) : all,
  );
}

/// The newest revision with the same items and cost settings as
/// [project]'s current estimate, or null when it has changed since.
EstimateRevision? matchingRevision(Project project) =>
    (_matching[project] ??= () {
      if (project.revisions.isEmpty) return (revision: null);
      final current = _itemsJson(project.items);
      for (final r in project.revisions.reversed) {
        if (r.costs == project.costs && _itemsJson(r.items) == current) {
          return (revision: r);
        }
      }
      return (revision: null);
    }()).revision;

// A project never changes, so its matching revision is found once.
final _matching = Expando<({EstimateRevision? revision})>();

/// The revision [project]'s estimate is at, for exported documents: "Rev 2"
/// when it is the same as revision 2, "Draft after Rev 2" when it has
/// changed since the latest one, or null when it has no revisions.
String? revisionLabel(Project project) => project.revisions.isEmpty
    ? null
    : matchingRevision(project)?.label ??
          'Draft after ${project.revisions.last.label}';

// Revisions never change either; the list is written out once per change.
final _written = Expando<List<Object>>();

/// [revisions] for saving, oldest first. An item that is the same as in the
/// revision before it is written as just its id, so twenty revisions of a
/// large estimate stay small.
List<Object> revisionsToJson(List<EstimateRevision> revisions) =>
    _written[revisions] ??= () {
      var previous = <String, String>{};
      return <Object>[
        for (final r in revisions)
          () {
            final written = <String, String>{
              for (final e in r.items) e.id: jsonEncode(e.toJson()),
            };
            final items = [
              for (final e in r.items)
                previous[e.id] == written[e.id] ? e.id : e.toJson(),
            ];
            previous = written;
            return {
              'number': r.number,
              'date': r.date.toIso8601String(),
              if (r.note.isNotEmpty) 'note': r.note,
              'items': items,
              'costs': r.costs.toJson(),
            };
          }(),
      ];
    }();

/// Reads revisions saved by [revisionsToJson], skipping damaged ones and
/// items whose earlier copy is missing.
List<EstimateRevision> revisionsFromJson(Object? json) {
  if (json is! List) return const [];
  final out = <EstimateRevision>[];
  for (final raw in json) {
    if (raw is! Map<String, dynamic>) continue;
    final number = raw['number'];
    final date = raw['date'] is String
        ? DateTime.tryParse(raw['date'] as String)
        : null;
    if (number is! num || number < 1 || date == null) continue;
    final previous = {
      for (final e in out.isEmpty ? const <Estimate>[] : out.last.items)
        e.id: e,
    };
    final items = <Estimate>[];
    for (final item in raw['items'] as List? ?? const []) {
      if (item is String) {
        if (previous[item] case final e?) items.add(e);
      } else if (item is Map<String, dynamic>) {
        try {
          items.add(Estimate.fromJson(item));
        } on FormatException {
          // Skip a damaged item rather than losing the revision.
        }
      }
    }
    out.add(
      EstimateRevision(
        number: number.toInt(),
        date: date,
        note: raw['note'] is String ? raw['note'] as String : '',
        items: List.unmodifiable(items),
        costs: raw['costs'] is Map<String, dynamic>
            ? CostSettings.fromJson(raw['costs'] as Map<String, dynamic>)
            : CostSettings.owner,
      ),
    );
  }
  return List.unmodifiable(out);
}

/// An item in one estimate and not the other, or in both but different,
/// with its direct cost on each side (0 where it is missing).
typedef ItemChange = ({
  Estimate? before,
  Estimate? after,
  double beforeAmount,
  double afterAmount,
});

/// A cost setting that differs, with its value on each side as shown.
typedef SettingChange = ({String label, String before, String after});

/// The direct cost of an estimate's work: materials, labour, minor tools
/// and equipment.
double itemDirectCost(Estimate e, CostSettings costs) => _centavos(
  analyseEstimate(e, costs).fold<double>(0, (sum, a) => sum + a.directCost),
);

/// What changed from one estimate of a project to another: totals, items
/// added, removed and changed, and cost settings.
@immutable
class EstimateComparison {
  const EstimateComparison._({
    required this.before,
    required this.after,
    required this.added,
    required this.removed,
    required this.changed,
    required this.repriced,
    required this.settings,
  });

  /// Compares [before] with [after], two versions of the same project,
  /// such as a revision applied with [EstimateRevision.applyTo] and the
  /// project itself. Items are matched by id.
  factory EstimateComparison.of(Project before, Project after) {
    final old = {for (final e in before.items) e.id: e};
    final now = {for (final e in after.items) e.id: e};
    ItemChange change(Estimate? b, Estimate? a) => (
      before: b,
      after: a,
      beforeAmount: b == null ? 0 : itemDirectCost(b, before.costs),
      afterAmount: a == null ? 0 : itemDirectCost(a, after.costs),
    );
    final changed = <ItemChange>[];
    var repriced = 0.0;
    for (final a in after.items) {
      final b = old[a.id];
      if (b == null) continue;
      final c = change(b, a);
      if (jsonEncode(b.toJson()) != jsonEncode(a.toJson())) {
        changed.add(c);
      } else {
        repriced += c.afterAmount - c.beforeAmount;
      }
    }
    return EstimateComparison._(
      before: before,
      after: after,
      added: [
        for (final a in after.items)
          if (!old.containsKey(a.id)) change(null, a),
      ],
      removed: [
        for (final b in before.items)
          if (!now.containsKey(b.id)) change(b, null),
      ],
      changed: changed,
      repriced: _centavos(repriced),
      settings: settingChanges(before.costs, after.costs),
    );
  }

  final Project before;
  final Project after;
  final List<ItemChange> added;
  final List<ItemChange> removed;

  /// Items in both whose quantities, prices or details differ.
  final List<ItemChange> changed;

  /// The change in the direct cost of the items that are the same in both,
  /// from different cost settings such as daily rates.
  final double repriced;
  final List<SettingChange> settings;

  double get totalChange =>
      _centavos(after.breakdown.total - before.breakdown.total);

  double get directChange =>
      _centavos(after.breakdown.direct - before.breakdown.direct);

  /// The change in general requirements and hauling, which also follows
  /// the length of the job.
  double get generalChange => _centavos(
    after.breakdown.general +
        after.breakdown.hauling -
        before.breakdown.general -
        before.breakdown.hauling,
  );

  bool get isSame =>
      added.isEmpty &&
      removed.isEmpty &&
      changed.isEmpty &&
      settings.isEmpty &&
      totalChange == 0;
}

String _labourMethod(LabourMethod m) =>
    m == LabourMethod.crews ? 'By crew output' : '% of materials';

String _pct(double v) => '${formatNumber(v)}%';

/// The cost settings that differ between [before] and [after], labelled
/// as in the budget.
List<SettingChange> settingChanges(CostSettings before, CostSettings after) {
  final out = <SettingChange>[];
  void add(String label, double b, double a, String Function(double) show) {
    if (b != a) out.add((label: label, before: show(b), after: show(a)));
  }

  if (before.labourMethod != after.labourMethod) {
    out.add((
      label: 'Labour',
      before: _labourMethod(before.labourMethod),
      after: _labourMethod(after.labourMethod),
    ));
  }
  add('Labour, % of materials', before.labourPct, after.labourPct, _pct);
  for (final c in MaterialCategory.values) {
    final b = before.labourByTrade[c.name];
    final a = after.labourByTrade[c.name];
    if (b == null && a == null) continue;
    add(
      'Labour, ${c.label.toLowerCase()} works',
      b ?? before.labourPct,
      a ?? after.labourPct,
      _pct,
    );
  }
  add('Crew productivity', before.productivityPct, after.productivityPct, _pct);
  final rates = {...before.dailyRates.keys, ...after.dailyRates.keys};
  for (final key in rates) {
    add(
      'Daily rate, ${DailyRates.labels[key] ?? key}',
      before.dailyRates[key] ?? 0,
      after.dailyRates[key] ?? 0,
      formatMoney,
    );
  }
  add('Minor tools, % of labour', before.toolsPct, after.toolsPct, _pct);
  add('Hauling and delivery', before.hauling, after.hauling, formatMoney);
  for (final MapEntry(:key, :value) in generalRequirements.entries) {
    add(value, before.general[key] ?? 0, after.general[key] ?? 0, formatMoney);
  }
  for (final MapEntry(:key, :value) in timeRelatedRequirements.entries) {
    add(
      '$value, a month',
      before.monthly[key] ?? 0,
      after.monthly[key] ?? 0,
      formatMoney,
    );
  }
  add('Contingency', before.contingencyPct, after.contingencyPct, _pct);
  add('Overhead (OCM)', before.overheadPct, after.overheadPct, _pct);
  add('Profit', before.profitPct, after.profitPct, _pct);
  add('VAT', before.vatPct, after.vatPct, _pct);
  add('Price escalation', before.escalationPct, after.escalationPct, _pct);
  return out;
}
