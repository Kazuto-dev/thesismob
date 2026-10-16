import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'boq.dart';
import 'contract.dart';
import 'project.dart';
import 'unit_prices.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// A line of the contract: a work item, a general requirement or a
/// variation order, with its share of the contract price (markups and VAT
/// included).
typedef ContractLine = ({
  String key,
  String number,
  String description,
  double quantity,
  String unit,
  double amount,
});

/// The project's contract lines, numbered as in the bill of quantities.
/// Markups and VAT are spread over the lines in proportion to their direct
/// cost, so the lines add up to the contract price.
List<ContractLine> contractLines(Project project) {
  final b = project.breakdown;
  final factor = b.direct > 0 ? b.total / b.direct : 1.0;
  final lines = <ContractLine>[];
  for (final section in workSections(project)) {
    for (final (:number, :analysis) in section.entries) {
      final a = analysis;
      lines.add((
        key: '${a.estimate.id}|${a.work.key}',
        number: number,
        description: workDescription(a),
        quantity: a.quantity,
        unit: a.unit,
        amount: _centavos(a.directCost * factor),
      ));
    }
  }
  for (final (i, g) in generalLines(project).indexed) {
    lines.add((
      key: 'general|${g.key}',
      number: 'F.${i + 1}',
      description: g.description,
      quantity: g.quantity,
      unit: g.unit,
      amount: _centavos(g.amount * factor),
    ));
  }
  // Put the rounding difference on the largest line, so the lines add up
  // to the total exactly.
  if (lines.isNotEmpty) {
    final sum = lines.fold<double>(0, (s, l) => s + l.amount);
    final diff = _centavos(b.total - sum);
    if (diff != 0) {
      var largest = 0;
      for (var i = 1; i < lines.length; i++) {
        if (lines[i].amount > lines[largest].amount) largest = i;
      }
      final l = lines[largest];
      lines[largest] = (
        key: l.key,
        number: l.number,
        description: l.description,
        quantity: l.quantity,
        unit: l.unit,
        amount: _centavos(l.amount + diff),
      );
    }
  }
  for (final (i, v) in project.contract.variations.indexed) {
    lines.add((
      key: 'vo|${v.id}',
      number: 'VO-${i + 1}',
      description: v.description,
      quantity: 1,
      unit: 'lot',
      amount: _centavos(v.amount),
    ));
  }
  return lines;
}

/// The original contract price plus the variation orders.
double contractPrice(Project project) =>
    _centavos(project.breakdown.total + project.contract.variationsTotal);

/// One progress billing worked out: what was accomplished, less what was
/// billed before, the downpayment recouped and the retention held.
typedef BillingStatement = ({
  int number,
  DateTime date,
  double percentComplete,
  double toDate,
  double previous,
  double thisPeriod,
  double recoupment,
  double retention,
  double netDue,
});

/// The value of the work done by [billing], over [lines].
double accomplished(List<ContractLine> lines, Billing billing) => _centavos(
  lines.fold(
    0,
    (s, l) => s + l.amount * (billing.progress[l.key] ?? 0).clamp(0, 100) / 100,
  ),
);

/// Every billing of the project, in order.
List<BillingStatement> billingStatements(Project project) {
  final lines = contractLines(project);
  final price = contractPrice(project);
  final terms = project.contract.terms;
  var previous = 0.0;
  final out = <BillingStatement>[];
  for (final (i, b) in project.contract.billings.indexed) {
    final toDate = accomplished(lines, b);
    final period = _centavos(toDate - previous);
    final recoupment = _centavos(period * terms.downpaymentPct / 100);
    final retention = _centavos(period * terms.retentionPct / 100);
    out.add((
      number: i + 1,
      date: b.date,
      percentComplete: price <= 0 ? 0 : toDate / price * 100,
      toDate: toDate,
      previous: previous,
      thisPeriod: period,
      recoupment: recoupment,
      retention: retention,
      netDue: _centavos(period - recoupment - retention),
    ));
    previous = toDate;
  }
  return out;
}

/// The downpayment billed on signing.
double downpayment(Project project) => _centavos(
  project.breakdown.total * project.contract.terms.downpaymentPct / 100,
);

// Schedule

/// Phases of building a house, in order, with the work items in each.
const schedulePhases = <(String, Set<String>)>[
  (
    'Site preparation and earthworks',
    {Work.excavation, Work.backfill, Work.gravelBedding, 'excavation_hard'},
  ),
  ('Foundations', {Work.concreteFooting}),
  ('Columns and ground slab', {Work.concreteColumn, Work.concreteSlabOnFill}),
  (
    'Beams, upper slabs and stairs',
    {Work.concreteBeam, Work.concreteSlabSuspended, 'stairs_concrete'},
  ),
  (
    'Walls and rough-ins',
    {
      Work.chb4,
      Work.chb6,
      Work.chb8,
      Work.roughIn,
      Work.piping,
      Work.wiring,
      Work.boxes,
      Work.septicChb,
      'aux_point',
      'catch_basin',
    },
  ),
  (
    'Roofing',
    {Work.roofing, Work.purlins, Work.gutter, Work.insulation, 'steel_truss'},
  ),
  (
    'Plastering, ceilings and waterproofing',
    {
      Work.plaster,
      Work.ceiling,
      Work.plywood,
      'waterproofing',
      'waterproofing_torch',
      'floor_topping',
    },
  ),
  (
    'Finishes and openings',
    {
      Work.tiling,
      Work.tileSkirting,
      Work.painting,
      Work.doors,
      Work.windows,
      Work.carpet,
      Work.wallpaper,
      'plank_flooring',
      'cabinets',
      'cabinets_built',
      'countertop',
      'steel_railing',
    },
  ),
  (
    'Fixtures, testing and turnover',
    {
      Work.lightFixture,
      Work.wiringDevice,
      Work.panel,
      Work.toilet,
      Work.sink,
      Work.faucet,
      Work.shower,
      Work.tank,
      'pump_install',
      'cctv_camera',
    },
  ),
];

int _phaseOf(String workKey, MaterialCategory? trade) {
  for (final (i, (_, keys)) in schedulePhases.indexed) {
    if (keys.contains(workKey)) return i;
  }
  return switch (trade) {
    MaterialCategory.architectural => 7,
    _ => 4,
  };
}

/// Working days in a week: Monday to Saturday.
const workDaysPerWeek = 6;

/// Working days in an average month of six-day weeks.
const workDaysPerMonth = 26;

/// One bar of the schedule: one trade's work in one phase.
typedef ScheduleTask = ({
  int phase,
  String label,
  MaterialCategory? trade,
  double start,
  double days,
  double cost,
});

/// A construction schedule worked out from the crew-days of each work
/// item and the crews working at once in each trade. Phases follow one
/// another; trades within a phase work side by side.
class Schedule {
  Schedule._(this.tasks, this.days, this.costs);

  factory Schedule.of(Project project) {
    final c = project.costs;
    final rates = c.dailyRates;
    final crewDay =
        (rates[DailyRates.skilled] ?? 0) + (rates[DailyRates.helper] ?? 0);
    final lanes = <(int, MaterialCategory?), ({double days, double cost})>{};
    for (final section in workSections(project)) {
      for (final (number: _, :analysis) in section.entries) {
        final a = analysis;
        final measured = worksOf(a.estimate);
        final main = measured.isEmpty ? a.work.key : measured.first.key;
        final key = a.work.key == Work.rebar || a.work.key == Work.formwork
            ? main
            : a.work.key;
        final trade = section.trade;
        final phase = _phaseOf(key, trade);
        final days = a.crewDays > 0
            ? a.crewDays
            : crewDay <= 0
            ? 0.0
            : a.labourCost / crewDay;
        final crews = project.contract.crewsFor(trade?.name ?? 'other');
        final lane = lanes[(phase, trade)];
        lanes[(phase, trade)] = (
          days: (lane?.days ?? 0) + days / crews,
          cost: (lane?.cost ?? 0) + a.directCost,
        );
      }
    }
    final tasks = <ScheduleTask>[];
    var start = 0.0;
    for (var phase = 0; phase < schedulePhases.length; phase++) {
      final here = [
        for (final MapEntry(:key, :value) in lanes.entries)
          if (key.$1 == phase) (key.$2, value),
      ];
      if (here.isEmpty) continue;
      var longest = 0.0;
      for (final (trade, lane) in here) {
        // Half a day at least, rounded up to half days.
        final days = ((lane.days * 2).ceilToDouble() / 2).clamp(0.5, 1e6);
        tasks.add((
          phase: phase,
          label: schedulePhases[phase].$1,
          trade: trade,
          start: start,
          days: days.toDouble(),
          cost: lane.cost,
        ));
        if (days > longest) longest = days.toDouble();
      }
      start += longest;
    }
    // General requirements run for the whole job.
    final general =
        c.generalTotal + c.hauling + c.monthlyTotal * start / workDaysPerMonth;
    return Schedule._(tasks, start, general);
  }

  final List<ScheduleTask> tasks;

  /// Working days from start to finish.
  final double days;

  /// Costs spread evenly over the whole job, such as general
  /// requirements.
  final double costs;

  double get weeks => days / workDaysPerWeek;

  /// How long the job runs in months, for costs paid by the month.
  double get months => days / workDaysPerMonth;

  /// The planned cumulative percent of the work's value done by the end
  /// of each week, for an S-curve.
  List<double> get sCurve {
    final total = tasks.fold<double>(0, (s, t) => s + t.cost) + costs;
    if (days <= 0 || total <= 0) return const [];
    final weekCount = (days / workDaysPerWeek).ceil();
    return [
      for (var w = 1; w <= weekCount; w++)
        () {
          final end = (w * workDaysPerWeek).toDouble();
          var done = costs * (end / days).clamp(0, 1);
          for (final t in tasks) {
            done += t.cost * ((end - t.start) / t.days).clamp(0, 1);
          }
          return (done / total * 100).clamp(0, 100).toDouble();
        }(),
    ];
  }

  /// The date [workingDays] after [start], skipping Sundays.
  static DateTime addWorkingDays(DateTime start, double workingDays) {
    var date = DateTime(start.year, start.month, start.day);
    var left = workingDays.ceil();
    while (left > 0) {
      date = date.add(const Duration(days: 1));
      if (date.weekday != DateTime.sunday) left--;
    }
    return date;
  }
}
