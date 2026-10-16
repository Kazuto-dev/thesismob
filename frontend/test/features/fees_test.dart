import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/core/format.dart';

import '../helpers.dart';

void main() {
  final items = [sampleEstimate('a', 'CHB 4"', 9850)];

  Future<void> openGeneral(WidgetTester tester) async {
    await pumpApp(
      tester,
      location: '/project',
      size: const Size(400, 1400),
      prefs: projectPrefs(items),
    );
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('General requirements'));
    await tester.tap(find.text('General requirements'));
    await tester.pumpAndSettle();
  }

  testWidgets('permit fees go into the permits general requirement', (
    tester,
  ) async {
    await openGeneral(tester);
    await tester.ensureVisible(find.text('Work out permit fees'));
    await tester.tap(find.text('Work out permit fees'));
    await tester.pumpAndSettle();
    expect(find.text('Permit fees'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Total floor area'),
      '140',
    );
    await tester.pumpAndSettle();
    expect(find.text(formatMoney(840)), findsOneWidget);

    final put = find.textContaining('in permits');
    await tester.scrollUntilVisible(
      put,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(put);
    await tester.pumpAndSettle();
    final permits = projectsOf(tester).active.costs.general['permits'];
    expect(permits, greaterThan(840));
    expect(find.textContaining('Permits and fees set to'), findsOneWidget);
  });

  testWidgets('professional fees go into the professional fees line', (
    tester,
  ) async {
    await openGeneral(tester);
    await tester.ensureVisible(find.text('Work out professional fees'));
    await tester.tap(find.text('Work out professional fees'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Project cost'),
      '3700000',
    );
    await tester.pumpAndSettle();
    expect(find.text(formatMoney(222000)), findsOneWidget);

    final put = find.textContaining('in professional fees');
    await tester.scrollUntilVisible(
      put,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(put);
    await tester.pumpAndSettle();
    expect(projectsOf(tester).active.costs.general['professional'], 370000);
  });

  testWidgets('a region fills in the labour rates', (tester) async {
    await pumpApp(
      tester,
      location: '/project',
      size: const Size(400, 1400),
      prefs: projectPrefs(items),
    );
    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daily rates'));
    await tester.tap(find.text('Daily rates'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rates for region'));
    await tester.tap(find.text('Rates for region'));
    await tester.pumpAndSettle();

    // The price book is set to Metro Manila, so NCR is chosen.
    final ncr = find.ancestor(
      of: find.text('Metro Manila (NCR)'),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(ncr).selected, isTrue);

    final visayas = find.text('Central Visayas (VII)');
    await tester.scrollUntilVisible(
      visayas,
      200,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(visayas);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use these rates'));
    await tester.pumpAndSettle();
    final rates = projectsOf(tester).active.costs.dailyRates;
    expect(rates['skilled'], 850);
    expect(rates['helper'], 700);
    expect(rates['mixer'], 1800, reason: 'equipment is kept');
  });
}
