import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/project.dart';

import 'sample_house.dart';

ScheduleTask task(Schedule s, String label) =>
    s.tasks.firstWhere((t) => t.label == label);

double end(ScheduleTask t) => t.start + t.days;

void main() {
  test('a 140 m² two-storey house takes about six months, not thirteen', () {
    final house = sampleHouse();
    final s = Schedule.of(house);
    // With one crew per trade and phases strictly in a row, this house
    // took over 330 working days.
    expect(s.days, inInclusiveRange(130, 200));
    expect(s.months, inInclusiveRange(5.5, 8));
    expect(house.months, closeTo(s.months, 0.01));
    // Excavation alone used to take about 47 days with one helper.
    expect(task(s, 'Site preparation and earthworks').days, lessThan(25));
    expect(task(s, 'Site preparation and earthworks').crews, greaterThan(1));
    expect(s.critical.first, 'Mobilization and layout');
    expect(s.critical, contains('Foundations'));
    expect(s.critical.last, 'Testing, punch list and turnover');
    for (final t in s.tasks) {
      expect(t.crews, greaterThanOrEqualTo(t.crewDays > 0 ? 1 : 0));
    }
    // The work's value is all done by the end.
    expect(s.progressAt(s.days), closeTo(1, 1e-9));
  });

  test('auto crews stay within a small site\'s limits', () {
    final s = Schedule.of(sampleHouse());
    for (final t in s.tasks.where((t) => t.crewDays > 0)) {
      expect(t.crews, greaterThanOrEqualTo(1));
      expect(t.crews, t.crews.roundToDouble());
    }
    // A concrete gang is five or six people, so a small site fits one or
    // two of them, while diggers come one to a crew.
    expect(task(s, 'Foundations').crews, lessThanOrEqualTo(2));
    expect(s.crewsFor('structural'), lessThanOrEqualTo(8));
    expect(s.crewsFor('electrical'), 1);
    expect(s.crewsFor('nothing'), isNull);
  });

  test('phases overlap and wait for curing', () {
    final s = Schedule.of(
      sampleHouse(contract: const ContractData(rainPct: 0)),
    );
    expect(s.allowanceDays, 0);
    final dig = task(s, 'Site preparation and earthworks');
    final footings = task(s, 'Foundations');
    final columns = task(s, 'Columns and ground slab');
    final beams = task(s, 'Beams, upper slabs and stairs');
    final roof = s.tasks.firstWhere(
      (t) => t.label == 'Roof framing and roofing' && t.critical,
    );
    final walls = s.tasks.where((t) => t.label == 'Walls and rough-ins');
    final plaster = task(s, 'Plastering and waterproofing');
    // Footings start while the pits are still being dug.
    expect(footings.start, lessThan(end(dig)));
    expect(footings.start, greaterThanOrEqualTo(dig.start + dig.days / 2));
    // Columns wait three days for the footings to cure.
    expect(columns.start, greaterThanOrEqualTo(end(footings) + 3));
    // The roof waits a week for the beams and upper slab to cure.
    expect(roof.start, greaterThanOrEqualTo(end(beams) + 7));
    // Plastering overlaps the walls, and walls overlap the upper slab.
    final wallsEnd = walls.map(end).reduce((a, b) => a > b ? a : b);
    expect(plaster.start, lessThan(wallsEnd));
    expect(walls.first.start, lessThan(end(beams)));
    // Testing and turnover come last.
    final last = s.tasks.last;
    expect(last.label, 'Testing, punch list and turnover');
    expect(end(last), s.days);
  });

  test('the rain allowance stretches the whole schedule', () {
    final dry = Schedule.of(
      sampleHouse(contract: const ContractData(rainPct: 0)),
    );
    final usual = Schedule.of(sampleHouse());
    final wet = Schedule.of(
      sampleHouse(contract: const ContractData(rainPct: 20)),
    );
    expect(usual.netDays, dry.days);
    expect(usual.days, closeTo(dry.days * 1.1, 0.5));
    expect(wet.days, closeTo(dry.days * 1.2, 0.5));
    expect(usual.allowanceDays, closeTo(dry.days * 0.1, 0.5));
    // Longer jobs pay more months of site engineer and watchman.
    expect(
      sampleHouse(contract: const ContractData(rainPct: 20)).breakdown.general,
      greaterThan(sampleHouse().breakdown.general),
    );
  });

  test('crews set by hand win over the app\'s', () {
    final auto = Schedule.of(sampleHouse());
    final one = Schedule.of(
      sampleHouse(contract: const ContractData(crews: {'structural': 1})),
    );
    expect(one.crewsFor('structural'), 1);
    expect(one.days, greaterThan(auto.days));
    expect(one.crewsFor('architectural'), auto.crewsFor('architectural'));
  });

  test('a target sizes the crews to meet it, or says it cannot', () {
    final usual = Schedule.of(sampleHouse());
    expect(usual.target, isNull);
    expect(usual.meetsTarget, isNull);

    final weeks = usual.weeks.floorToDouble() - 1;
    final sooner = Schedule.of(
      sampleHouse(contract: ContractData(targetWeeks: weeks)),
    );
    expect(sooner.target, weeks * 6);
    expect(sooner.meetsTarget, isTrue);
    expect(sooner.days, lessThanOrEqualTo(weeks * 6));
    expect(
      sooner.crewsFor('structural'),
      greaterThanOrEqualTo(usual.crewsFor('structural')!),
    );

    // A target longer than the usual schedule changes nothing.
    final later = Schedule.of(
      sampleHouse(contract: ContractData(targetWeeks: usual.weeks + 10)),
    );
    expect(later.meetsTarget, isTrue);
    expect(later.days, usual.days);

    // Eight weeks is too fast for a small site: the schedule shows the
    // fastest it can do instead.
    final rushed = Schedule.of(
      sampleHouse(contract: const ContractData(targetWeeks: 8)),
    );
    expect(rushed.meetsTarget, isFalse);
    expect(rushed.days, greaterThan(8 * 6));
    expect(rushed.days, lessThanOrEqualTo(sooner.days));
  });

  test('a finish-by date counts working days from the start', () {
    final start = DateTime(2026, 11, 2);
    final by = DateTime(2027, 4, 30);
    final p = sampleHouse(
      contract: ContractData(startDate: start, finishBy: by, targetWeeks: 99),
    );
    final s = Schedule.of(p);
    expect(s.target, Schedule.workingDaysBetween(start, by));
    expect(Schedule.addWorkingDays(start, s.target!), by);
    // A date without a start date is not a target yet.
    expect(
      targetDays(sampleHouse(contract: ContractData(finishBy: by))),
      isNull,
    );
  });

  test('working days skip Sundays and regular holidays', () {
    // Wednesday 23 December 2026 + 3: Thursday 24th, Saturday 26th
    // (Christmas on Friday), Monday 28th.
    expect(
      Schedule.addWorkingDays(DateTime(2026, 12, 23), 3),
      DateTime(2026, 12, 28),
    );
    expect(
      Schedule.workingDaysBetween(
        DateTime(2026, 12, 23),
        DateTime(2026, 12, 28),
      ),
      3,
    );
    // Proclamation No. 1006 s. 2025 lists these for 2026.
    expect(easter(2026), DateTime(2026, 4, 5));
    final dates = {for (final h in regularHolidays(2026)) h.date};
    expect(
      dates,
      containsAll([
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 2),
        DateTime(2026, 4, 3),
        DateTime(2026, 4, 9),
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 12),
        DateTime(2026, 8, 31),
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 25),
        DateTime(2026, 12, 30),
      ]),
    );
    expect(dates, hasLength(10));
    expect(easter(2027), DateTime(2027, 3, 28));
    expect(isRegularHoliday(DateTime(2027, 3, 26)), isTrue); // Good Friday
    expect(isRegularHoliday(DateTime(2027, 8, 30)), isTrue); // Heroes Day
    expect(isRegularHoliday(DateTime(2027, 8, 31)), isFalse);
  });

  test('holidays on the way lengthen the job in months', () {
    final s = Schedule.of(
      sampleHouse(contract: ContractData(startDate: DateTime(2026, 11, 2))),
    );
    // November to May passes Bonifacio Day, Christmas, Rizal Day, New
    // Year's Day, Holy Week and Araw ng Kagitingan.
    expect(s.holidays, greaterThanOrEqualTo(6));
    expect(s.months, closeTo((s.days + s.holidays) / workDaysPerMonth, 1e-9));
    final finish = Schedule.addWorkingDays(DateTime(2026, 11, 2), s.days);
    final calendar = finish.difference(DateTime(2026, 11, 2)).inDays;
    expect(s.months, closeTo(calendar / 30.44, 0.4));
  });

  test('projects without a frame skip its phases', () {
    final p = Project.create('Repaint').copyWith(
      items: [
        calculated('paint', {'length': 40, 'height': 3, 'price': 750}),
        calculated('toilet', {'quantity': 1, 'price': 6500, 'piecePrice': 0}),
      ],
    );
    final s = Schedule.of(p);
    expect(
      task(s, 'Finishes and openings').start,
      task(s, 'Mobilization and layout').days,
    );
    expect(s.tasks.map((t) => t.label), isNot(contains('Foundations')));
    expect(s.days, lessThan(30));
    expect(Schedule.of(Project.create('Empty')).days, 0);
    expect(Schedule.of(Project.create('Empty')).tasks, isEmpty);
  });
}
