import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/contract_math.dart';
import 'package:thesismob/data/project.dart';

import '../data/sample_house.dart';
import '../helpers.dart';

Future<void> openContract(WidgetTester tester) async {
  await pumpApp(
    tester,
    location: '/project',
    prefs: projectPrefs(
      sampleHouse().items,
      costs: CostSettings.contractor.toJson(),
    ),
  );
  await tester.tap(find.text('Contract'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the schedule shows crews, critical phases and a target', (
    tester,
  ) async {
    await openContract(tester);
    expect(find.textContaining('Critical phases: '), findsOneWidget);
    expect(find.textContaining('Auto · up to'), findsWidgets);
    expect(find.textContaining('crews ·'), findsWidgets);
    expect(
      find.textContaining('working days for rain and unworkable days'),
      findsOneWidget,
    );

    // Too short a target: the app says so.
    final target = find.widgetWithText(TextField, 'Finish within');
    await tester.ensureVisible(target);
    await tester.enterText(target, '8');
    await tester.pumpAndSettle();
    expect(projectsOf(tester).active.contract.targetWeeks, 8);
    expect(find.textContaining("Can't finish within 8 weeks"), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Clear the target'));
    expect(projectsOf(tester).active.contract.targetWeeks, isNull);

    // Crews typed by hand replace Auto for that trade.
    final structural = find.widgetWithText(TextField, 'Structural');
    await tester.ensureVisible(structural);
    await tester.enterText(structural, '2');
    await tester.pumpAndSettle();
    expect(projectsOf(tester).active.contract.crews, {'structural': 2.0});
    await tester.enterText(structural, '');
    await tester.pumpAndSettle();
    expect(projectsOf(tester).active.contract.crews, isEmpty);
  });

  testWidgets('cash flow and purchase schedule are listed', (tester) async {
    await openContract(tester);
    await tester.ensureVisible(find.text('Cash flow'));
    expect(find.text('Peak cash need (working capital)'), findsOneWidget);
    expect(find.text('Signing'), findsOneWidget);
    expect(find.text('Download cash flow'), findsOneWidget);

    await tester.ensureVisible(find.text('Purchase schedule'));
    expect(find.text('Set a start date to see the dates.'), findsOneWidget);
    expect(find.textContaining('Needed week'), findsNWidgets(8));
    await tapVisible(tester, find.textContaining('Show all'));
    expect(
      find.textContaining('Needed week'),
      findsNWidgets(projectsOf(tester).active.materials.length),
    );
  });

  testWidgets('a government client withholds taxes from billings', (
    tester,
  ) async {
    await openContract(tester);
    await tapVisible(tester, find.text('Individual or household'));
    await tester.tap(find.text('Government').last);
    await tester.pumpAndSettle();
    final p = projectsOf(tester).active;
    expect(p.contract.terms.client, ClientType.government);
    expect(
      find.textContaining('2% creditable income tax and 5% VAT'),
      findsOneWidget,
    );

    final keys = [for (final l in contractLines(p)) l.key];
    projectsOf(tester).updateContract(
      p.id,
      (c) => c.copyWith(
        billings: [
          Billing(
            id: 'b1',
            date: DateTime(2026, 12, 1),
            progress: {for (final k in keys) k: 30},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('you receive'), findsOneWidget);
  });

  testWidgets('actual labour sets the productivity of the estimate', (
    tester,
  ) async {
    await openContract(tester);
    final p = projectsOf(tester).active;
    final keys = [for (final l in contractLines(p)) l.key];
    final billed = p.copyWith(
      contract: ContractData(
        billings: [
          Billing(
            id: 'b1',
            date: DateTime(2026, 12, 1),
            progress: {for (final k in keys) k: 40},
          ),
        ],
      ),
    );
    final earned = reviewActuals(billed)!.earnedLabour;
    projectsOf(tester).updateContract(
      p.id,
      (c) => c.copyWith(
        billings: billed.contract.billings,
        expenses: [
          Expense(
            id: 'x1',
            date: DateTime(2026, 11, 28),
            description: 'Payroll',
            kind: ExpenseKind.labour,
            amount: earned * 1.25,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learn from actuals'), findsOneWidget);
    expect(find.textContaining("Crews' productivity: 80%"), findsOneWidget);
    await tapVisible(
      tester,
      find.text('Use 80% productivity for this estimate'),
    );
    expect(projectsOf(tester).active.costs.productivityPct, 80);
    expect(find.text('Use 80% productivity for this estimate'), findsNothing);
  });
}
