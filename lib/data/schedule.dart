import 'dart:math' as math;

import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'boq.dart';
import 'project.dart';
import 'unit_prices.dart';

/// How a phase follows an earlier one. It may start once phase [phase] is
/// [done] of the way through (1 means finished) plus [lag] working days
/// for curing or setting. When it overlaps the earlier phase (done below
/// 1) it also finishes no sooner than [tail] working days after that
/// phase, since its last piece of work follows the earlier phase's last.
typedef PhaseLink = ({int phase, double done, double lag, double tail});

/// A phase of building a house: the work items in it, the phases it
/// waits for and, for a phase with no work items of its own such as
/// mobilization, a fixed number of working days.
typedef SchedulePhase = ({
  String label,
  Set<String> works,
  List<PhaseLink> after,
  double fixedDays,
});

/// The phases of building a house in order, and how each follows the
/// others. Bars and forms go with their element, so a beam's rebar is in
/// the beams' phase. Lags are working days:
///
/// - mobilization and layout (clearing, staking, batter boards, the
///   bodega) take 5 days;
/// - foundations start when the pits are half dug and finish a day after
///   the last pit;
/// - columns, backfill and the ground slab wait 3 days for the footings
///   to cure;
/// - beams and upper slabs go on columns cured for 3 days: the frame is
///   built floor by floor, so its work does not overlap;
/// - walls start 2 days after the ground slab, and the upper walls finish
///   3 days after the upper slab;
/// - roofing waits 7 days for the beams and upper slabs to cure, and for
///   half the walls;
/// - plastering starts when a third of the walls are up and set for 2
///   days, and ends 3 days after the last wall;
/// - ceilings go up once the roof is on;
/// - finishes start two weeks after half the plaster, so it has cured
///   enough to paint, and end two weeks after the last of it and 2 days
///   after the ceilings;
/// - fixtures go in last, once most finishes are done, followed by a week
///   of testing, the punch list and turnover.
///
/// A phase with a suspended slab also takes [curingDays] more.
const schedulePhases = <SchedulePhase>[
  (label: 'Mobilization and layout', works: {}, after: [], fixedDays: 5),
  (
    label: 'Site preparation and earthworks',
    works: {Work.excavation, 'excavation_hard'},
    after: [(phase: 0, done: 1, lag: 0, tail: 0)],
    fixedDays: 0,
  ),
  (
    label: 'Foundations',
    works: {Work.concreteFooting, 'concrete_tie_beam'},
    after: [(phase: 1, done: 0.5, lag: 0, tail: 1)],
    fixedDays: 0,
  ),
  (
    label: 'Columns and ground slab',
    works: {
      Work.concreteColumn,
      Work.backfill,
      Work.gravelBedding,
      Work.concreteSlabOnFill,
    },
    after: [(phase: 2, done: 1, lag: 3, tail: 0)],
    fixedDays: 0,
  ),
  (
    label: 'Beams, upper slabs and stairs',
    works: {Work.concreteBeam, Work.concreteSlabSuspended, 'stairs_concrete'},
    after: [(phase: 3, done: 1, lag: 3, tail: 0)],
    fixedDays: 0,
  ),
  (
    label: 'Walls and rough-ins',
    works: {
      Work.chb4,
      Work.chb6,
      Work.chb8,
      Work.roughIn,
      Work.piping,
      Work.wiring,
      Work.boxes,
      Work.septicChb,
      'concrete_lintel',
      'aux_point',
      'catch_basin',
    },
    after: [
      (phase: 3, done: 1, lag: 2, tail: 0),
      (phase: 4, done: 0, lag: 0, tail: 3),
    ],
    fixedDays: 0,
  ),
  (
    label: 'Roof framing and roofing',
    works: {
      Work.roofing,
      Work.purlins,
      Work.gutter,
      Work.insulation,
      'steel_truss',
      'fascia_board',
      'roof_flashing',
    },
    after: [
      (phase: 4, done: 1, lag: 7, tail: 0),
      (phase: 5, done: 0.5, lag: 0, tail: 0),
    ],
    fixedDays: 0,
  ),
  (
    label: 'Plastering and waterproofing',
    works: {
      Work.plaster,
      'waterproofing',
      'waterproofing_torch',
      'floor_topping',
    },
    after: [(phase: 5, done: 0.3, lag: 2, tail: 3)],
    fixedDays: 0,
  ),
  (
    label: 'Ceilings',
    works: {Work.ceiling, Work.plywood, 'eaves_soffit'},
    after: [
      (phase: 6, done: 1, lag: 0, tail: 0),
      (phase: 7, done: 0.5, lag: 0, tail: 0),
    ],
    fixedDays: 0,
  ),
  (
    label: 'Finishes and openings',
    works: {
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
      'steel_gate',
      'pcc_pavement',
    },
    after: [
      (phase: 7, done: 0.5, lag: 14, tail: 14),
      (phase: 8, done: 0.5, lag: 0, tail: 2),
    ],
    fixedDays: 0,
  ),
  (
    label: 'Fixtures',
    works: {
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
      'service_entrance',
      'water_heater',
      'bath_accessory',
    },
    after: [(phase: 9, done: 0.75, lag: 0, tail: 2)],
    fixedDays: 0,
  ),
  (
    label: 'Testing, punch list and turnover',
    works: {},
    after: [
      (phase: 9, done: 1, lag: 0, tail: 0),
      (phase: 10, done: 1, lag: 0, tail: 0),
    ],
    fixedDays: 6,
  ),
];

/// The phase of work [workKey] of [trade]: its own phase, or walls and
/// rough-ins for unknown structural, services and other work and
/// finishes for unknown architectural work.
int phaseOf(String workKey, MaterialCategory? trade) {
  for (final (i, p) in schedulePhases.indexed) {
    if (p.works.contains(workKey)) return i;
  }
  return trade == MaterialCategory.architectural ? 9 : 5;
}

/// The most workers of one trade, by category name, that a small house
/// site run by one foreman holds at once. Crews the app sizes itself
/// stay within them: about eight structural workers (diggers, masons,
/// carpenters, steelmen and their helpers, or one concrete gang with
/// carpenters), four on roofing and finishes, and an electrician and a
/// plumber with a helper each.
const siteWorkerLimits = <String, double>{
  'structural': 8,
  'architectural': 4,
  'electrical': 2,
  'plumbing': 2,
  'other': 3,
};

/// Crews the app sizes itself aim to finish a trade's work in a phase in
/// about this many working days, three weeks.
const autoLaneDays = 18.0;

/// Working days that the work above a pour waits for it to cure, added
/// to its phase: the next floor's columns and walls go on a suspended
/// slab after about a week of curing.
const curingDays = <String, double>{Work.concreteSlabSuspended: 7};

/// Working days in a week: Monday to Saturday.
const workDaysPerWeek = 6;

/// Working days in an average month of six-day weeks, holidays included.
const workDaysPerMonth = 26;

/// Regular holidays that fall on a working day in an average year, for
/// schedules without a start date.
const _holidaysPerYear = 9.0;

/// Monday-to-Saturday days in an average year.
const _workDaysPerYear = 313.0;

/// One bar of the schedule: one trade's work in one phase, or a phase
/// with no work items of its own, such as testing and turnover.
typedef ScheduleTask = ({
  int phase,
  String label,
  MaterialCategory? trade,
  double start,
  double days,
  double cost,

  /// The part of [cost] that is materials, bought when the task starts.
  double materials,

  /// Crews working at once; 0 for a phase with no work items.
  double crews,

  /// The work in crew-days, before it is shared between crews.
  double crewDays,

  /// Whether the task sets the finish date: a day's delay here delays
  /// the job.
  bool critical,
});

/// The key of [trade] in [ContractData.crews] and [siteWorkerLimits].
String tradeKey(MaterialCategory? trade) => trade?.name ?? 'other';

class _Lane {
  _Lane(this.phase, this.trade);

  final int phase;
  final MaterialCategory? trade;
  double crewDays = 0;
  double workerDays = 0;
  double cost = 0;
  double materials = 0;

  /// Working days the lane waits for its concrete to cure, from
  /// [curingDays].
  double cure = 0;

  /// Workers in one crew, on average over the lane's work.
  double get crewSize => crewDays <= 0 ? 2 : workerDays / crewDays;
}

/// The crew-days, workers and cost of [project]'s work by phase and trade.
List<_Lane> _lanesOf(Project project) {
  final rates = project.costs.dailyRates;
  final crewDay =
      (rates[DailyRates.skilled] ?? 0) + (rates[DailyRates.helper] ?? 0);
  final lanes = <(int, MaterialCategory?), _Lane>{};
  for (final section in workSections(project)) {
    for (final (number: _, :analysis) in section.entries) {
      final a = analysis;
      final key = scheduleKey(a);
      final phase = phaseOf(key, section.trade);
      final days = a.crewDays > 0
          ? a.crewDays
          : crewDay <= 0
          ? 0.0
          : a.labourCost / crewDay;
      final crew = a.item?.crew;
      final size = crew == null || a.crewDays <= 0
          ? 2.0
          : crew.foreman + crew.skilled + crew.helpers;
      final lane = lanes.putIfAbsent((
        phase,
        section.trade,
      ), () => _Lane(phase, section.trade));
      lane.crewDays += days;
      lane.workerDays += days * size;
      lane.cost += a.directCost;
      lane.materials += a.materialCost;
      lane.cure = math.max(lane.cure, curingDays[key] ?? 0);
    }
  }
  return lanes.values.toList()..sort((a, b) => a.phase.compareTo(b.phase));
}

/// The work key that places [a] in a phase: bars and forms go with the
/// element they are for.
String scheduleKey(WorkAnalysis a) {
  final measured = worksOf(a.estimate);
  final main = measured.isEmpty ? a.work.key : measured.first.key;
  return a.work.key == Work.rebar || a.work.key == Work.formwork
      ? main
      : a.work.key;
}

/// Crews the app gives [lane] so it takes about [laneDays], within the
/// site's worker limit for the trade and at least one.
double _autoCrews(_Lane lane, double laneDays) {
  final limit = siteWorkerLimits[tradeKey(lane.trade)] ?? 4;
  final most = (limit / lane.crewSize).floorToDouble().clamp(1.0, 1e6);
  final wanted = (lane.crewDays / laneDays - 1e-9).ceilToDouble();
  return wanted.clamp(1.0, most);
}

double _halfDays(double days) => (days * 2).ceilToDouble() / 2;

/// The schedule worked out for a given set of crews, before the
/// allowance for rain.
class _Plan {
  _Plan(List<_Lane> lanes, double Function(_Lane) crewsOf) {
    final n = schedulePhases.length;
    start = List.filled(n, 0);
    days = List.filled(n, 0);
    present = List.filled(n, false);
    final driver = List<int?>.filled(n, null);
    for (final lane in lanes) {
      final c = crewsOf(lane);
      crews[lane] = c;
      final d = math.max(0.5, _halfDays(lane.crewDays / c)) + lane.cure;
      laneDays[lane] = d;
      if (d > days[lane.phase]) days[lane.phase] = d;
      present[lane.phase] = true;
    }
    if (lanes.isNotEmpty) {
      for (final (i, p) in schedulePhases.indexed) {
        if (p.fixedDays > 0) {
          days[i] = p.fixedDays;
          present[i] = true;
        }
      }
    }
    for (var i = 0; i < n; i++) {
      var s = 0.0;
      for (final link in schedulePhases[i].after) {
        final p = link.phase;
        final double earliest;
        if (!present[p]) {
          // Nothing of that phase to wait for, but what it waited for.
          earliest = start[p];
        } else if (!present[i]) {
          earliest = start[p] + link.done * days[p];
        } else {
          var e = start[p] + link.done * days[p] + link.lag;
          if (link.done < 1) {
            e = math.max(e, start[p] + days[p] + link.tail - days[i]);
          }
          earliest = e;
        }
        if (earliest > s + 1e-9) {
          s = earliest;
          driver[i] = p;
        }
      }
      start[i] = s;
    }
    var last = -1;
    for (var i = 0; i < n; i++) {
      if (present[i] && (last < 0 || finish(i) >= finish(last) - 1e-9)) {
        last = i;
      }
    }
    total = last < 0 ? 0 : finish(last);
    for (int? i = last; i != null && i >= 0; i = driver[i]) {
      if (present[i]) critical.add(i);
    }
  }

  late final List<double> start;
  late final List<double> days;
  late final List<bool> present;
  final crews = <_Lane, double>{};
  final laneDays = <_Lane, double>{};
  final critical = <int>{};
  late final double total;

  double finish(int phase) => start[phase] + days[phase];
}

/// A construction schedule worked out from the crew-days of each work
/// item and the crews working at once in each trade. Phases overlap and
/// wait for curing as [schedulePhases] says; trades within a phase work
/// side by side. Working days are Monday to Saturday, stretched by the
/// allowance for rain and unworkable days, and dates skip Sundays and
/// the regular holidays.
class Schedule {
  Schedule._({
    required this.tasks,
    required this.days,
    required this.netDays,
    required this.costs,
    required this.holidays,
    required this.target,
    required this.meetsTarget,
    required this.critical,
  });

  factory Schedule.of(Project project) {
    final contract = project.contract;
    final lanes = _lanesOf(project);
    final stretch = 1 + contract.rainPct / 100;

    _Plan plan(double laneDays) => _Plan(
      lanes,
      (lane) =>
          contract.crews[tradeKey(lane.trade)] ?? _autoCrews(lane, laneDays),
    );

    // The crews the app sizes itself get as many as the target needs,
    // within the site's limits; without a target, lanes of about
    // [autoLaneDays].
    final target = targetDays(project);
    var chosen = plan(autoLaneDays);
    bool? meets;
    if (target != null && lanes.isNotEmpty) {
      bool fits(_Plan p) => p.total * stretch <= target + 1e-9;
      var ok = fits(chosen);
      for (var d = autoLaneDays - 0.5; !ok && d >= 1; d -= 0.5) {
        chosen = plan(d);
        ok = fits(chosen);
      }
      meets = ok;
    }

    double scaled(double day) => (day * stretch * 2).roundToDouble() / 2;
    final tasks = <ScheduleTask>[];
    for (final (i, phase) in schedulePhases.indexed) {
      if (!chosen.present[i]) continue;
      final start = scaled(chosen.start[i]);
      final here = [
        for (final lane in lanes)
          if (lane.phase == i) lane,
      ];
      if (here.isEmpty) {
        tasks.add((
          phase: i,
          label: phase.label,
          trade: null,
          start: start,
          days: scaled(chosen.finish(i)) - start,
          cost: 0,
          materials: 0,
          crews: 0,
          crewDays: 0,
          critical: chosen.critical.contains(i),
        ));
        continue;
      }
      for (final lane in here) {
        final d = chosen.laneDays[lane]!;
        tasks.add((
          phase: i,
          label: phase.label,
          trade: lane.trade,
          start: start,
          days: math.max(0.5, scaled(chosen.start[i] + d) - start),
          cost: lane.cost,
          materials: lane.materials,
          crews: chosen.crews[lane]!,
          crewDays: lane.crewDays,
          critical: chosen.critical.contains(i) && d >= chosen.days[i] - 1e-9,
        ));
      }
    }
    final days = scaled(chosen.total);
    final startDate = contract.startDate;
    final holidays = startDate == null
        ? days * _holidaysPerYear / _workDaysPerYear
        : holidaysBetween(
            startDate,
            addWorkingDays(startDate, days),
          ).toDouble();
    final months = (days + holidays) / workDaysPerMonth;
    final c = project.costs;
    return Schedule._(
      tasks: tasks,
      days: days,
      netDays: chosen.total,
      costs: c.generalTotal + c.hauling + c.monthlyTotal * months,
      holidays: holidays,
      target: target,
      meetsTarget: meets,
      critical: [
        for (final i in chosen.critical.toList()..sort())
          schedulePhases[i].label,
      ],
    );
  }

  /// The bars of the schedule in building order.
  final List<ScheduleTask> tasks;

  /// Working days from start to finish, the allowance for rain and
  /// unworkable days included.
  final double days;

  /// Working days of work alone, before the allowance for rain.
  final double netDays;

  /// Costs spread evenly over the whole job, such as general
  /// requirements.
  final double costs;

  /// Regular holidays on working days between the start and the finish,
  /// counted from the start date or estimated without one.
  final double holidays;

  /// The working days the job should take, from [ContractData.targetWeeks]
  /// or [ContractData.finishBy]; null without a target.
  final double? target;

  /// Whether the schedule meets [target]; null without one. When it
  /// cannot, the crews the app sizes itself are at the site's limits.
  final bool? meetsTarget;

  /// The phases that set the finish date, in order.
  final List<String> critical;

  /// Working days added for rain and unworkable days.
  double get allowanceDays => days - netDays;

  double get weeks => days / workDaysPerWeek;

  /// How long the job runs in months, for costs paid by the month: its
  /// working days, the rain allowance and the holidays on the way.
  double get months => (days + holidays) / workDaysPerMonth;

  /// The most crews at once in [trade] (a category name or `other`), or
  /// null when the trade has no work.
  double? crewsFor(String trade) {
    double? most;
    for (final t in tasks) {
      if (t.crewDays > 0 && tradeKey(t.trade) == trade) {
        if (most == null || t.crews > most) most = t.crews;
      }
    }
    return most;
  }

  /// The share of the work's value done by working day [day], from 0 to
  /// 1: each task's cost spread evenly over its days, and [costs] over the
  /// whole job.
  double progressAt(double day) {
    final total = tasks.fold<double>(0, (s, t) => s + t.cost) + costs;
    if (days <= 0 || total <= 0) return 0;
    var done = costs * (day / days).clamp(0, 1);
    for (final t in tasks) {
      if (t.days > 0) done += t.cost * ((day - t.start) / t.days).clamp(0, 1);
    }
    return (done / total).clamp(0, 1).toDouble();
  }

  /// The planned cumulative percent of the work's value done by the end
  /// of each week, for an S-curve.
  List<double> get sCurve {
    if (days <= 0 || progressAt(days) <= 0) return const [];
    final weekCount = (days / workDaysPerWeek).ceil();
    return [
      for (var w = 1; w <= weekCount; w++)
        progressAt((w * workDaysPerWeek).toDouble()) * 100,
    ];
  }

  /// The date [workingDays] after [start], skipping Sundays and regular
  /// holidays.
  static DateTime addWorkingDays(DateTime start, double workingDays) {
    var date = DateTime(start.year, start.month, start.day);
    var left = workingDays.ceil();
    while (left > 0) {
      date = DateTime(date.year, date.month, date.day + 1);
      if (isWorkingDay(date)) left--;
    }
    return date;
  }

  /// Working days after [start] up to and including [end]: the inverse
  /// of [addWorkingDays].
  static int workingDaysBetween(DateTime start, DateTime end) {
    var date = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    var count = 0;
    while (date.isBefore(last)) {
      date = DateTime(date.year, date.month, date.day + 1);
      if (isWorkingDay(date)) count++;
    }
    return count;
  }

  /// Whether work goes on on [date]: Monday to Saturday, not a regular
  /// holiday.
  static bool isWorkingDay(DateTime date) =>
      date.weekday != DateTime.sunday && !isRegularHoliday(date);

  /// Regular holidays on Mondays to Saturdays after [start] up to and
  /// including [end].
  static int holidaysBetween(DateTime start, DateTime end) {
    var date = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    var count = 0;
    while (date.isBefore(last)) {
      date = DateTime(date.year, date.month, date.day + 1);
      if (date.weekday != DateTime.sunday && isRegularHoliday(date)) count++;
    }
    return count;
  }
}

/// The working days [project] should take by its finish-by target: the
/// working weeks set, or the working days from the start date to the
/// finish-by date. Null without a target.
double? targetDays(Project project) {
  final c = project.contract;
  final start = c.startDate;
  if (c.finishBy case final by? when start != null) {
    return Schedule.workingDaysBetween(start, by).toDouble();
  }
  if (c.targetWeeks case final weeks? when weeks > 0) {
    return weeks * workDaysPerWeek;
  }
  return null;
}

// Holidays

/// Easter Sunday of [year], by the Gregorian computus.
DateTime easter(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final n = h + l - 7 * m + 114;
  return DateTime(year, n ~/ 31, n % 31 + 1);
}

/// The Philippine regular holidays of [year] that the schedule skips
/// (Labor Code art. 94 as amended by EO 203 and RA 9492): the seven on
/// fixed dates, Maundy Thursday and Good Friday from Easter, and National
/// Heroes Day on the last Monday of August. Eid'l Fitr and Eid'l Adha are
/// left out, since their dates are proclaimed each year, and so are the
/// special non-working days, when sites may work at premium pay.
List<({DateTime date, String name})> regularHolidays(int year) {
  final e = easter(year);
  final august31 = DateTime(year, 8, 31);
  return [
    (date: DateTime(year, 1, 1), name: "New Year's Day"),
    (date: DateTime(e.year, e.month, e.day - 3), name: 'Maundy Thursday'),
    (date: DateTime(e.year, e.month, e.day - 2), name: 'Good Friday'),
    (date: DateTime(year, 4, 9), name: 'Araw ng Kagitingan'),
    (date: DateTime(year, 5, 1), name: 'Labor Day'),
    (date: DateTime(year, 6, 12), name: 'Independence Day'),
    (
      date: DateTime(year, 8, 31 - (august31.weekday - DateTime.monday) % 7),
      name: 'National Heroes Day',
    ),
    (date: DateTime(year, 11, 30), name: 'Bonifacio Day'),
    (date: DateTime(year, 12, 25), name: 'Christmas Day'),
    (date: DateTime(year, 12, 30), name: 'Rizal Day'),
  ];
}

final _holidayCache = <int, Set<int>>{};

/// Whether [date] is one of [regularHolidays].
bool isRegularHoliday(DateTime date) {
  final days = _holidayCache.putIfAbsent(date.year, () {
    return {
      for (final h in regularHolidays(date.year))
        h.date.month * 100 + h.date.day,
    };
  });
  return days.contains(date.month * 100 + date.day);
}
