import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  final items = [
    sampleEstimate('a', 'CHB 4"', 1000),
    sampleEstimate('b', 'Tiles', 150000),
    sampleEstimate('c', 'Paint', 1250.5),
  ];
  const size = Size(800, 1400);

  Future<void> openFromMenu(WidgetTester tester, String entry) async {
    await tester.tap(find.byTooltip('Project actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  testWidgets('revisions are saved, compared and restored', (tester) async {
    await pumpApp(
      tester,
      location: '/project',
      size: size,
      prefs: projectPrefs(items),
    );
    await openFromMenu(tester, 'Estimate revisions');
    expect(find.text('Not saved as a revision yet.'), findsOneWidget);
    expect(find.text('No revisions yet.'), findsOneWidget);

    await tester.tap(find.text('Save as a revision'));
    await tester.pumpAndSettle();
    expect(find.text('Save Rev 1'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'What changed'),
      'For the client',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Rev 1 – For the client'), findsOneWidget);
    expect(find.text('The same as Rev 1.'), findsOneWidget);
    expect(find.text('No differences.'), findsOneWidget);

    // The client drops the paint.
    projectsOf(tester).removeItem('c');
    await tester.pumpAndSettle();
    expect(find.text('Changed since Rev 1.'), findsOneWidget);
    expect(find.text('Items removed'), findsOneWidget);
    expect(find.text('Paint'), findsOneWidget);

    await tester.tap(find.byTooltip('Actions for Rev 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Restore Rev 1?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();
    final project = projectsOf(tester).active;
    expect(project.items, hasLength(3));
    expect(project.revisions.map((r) => r.note), [
      'For the client',
      'Before restoring Rev 1',
    ]);
    expect(find.text('Rev 2 – Before restoring Rev 1'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(projectsOf(tester).active.items, hasLength(2));
  });

  testWidgets('quotes are compared with the estimate and awarded', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/project',
      size: size,
      prefs: projectPrefs(items),
    );
    final total = projectsOf(tester).active.breakdown.total;
    await openFromMenu(tester, 'Compare quotes');
    expect(find.text('No quotes yet'), findsOneWidget);

    Future<void> add(String bidder, double amount) async {
      await tester.tap(find.text('Add a quote'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Bidder or subcontractor'),
        bidder,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Quoted price'),
        amount.toStringAsFixed(2),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    await add('Reyes Builders', (total * 0.6).roundToDouble());
    await add('Cruz Construction', (total * 1.05).roundToDouble());
    expect(find.text('Reyes Builders'), findsOneWidget);
    expect(find.text('Lowest'), findsOneWidget);
    expect(find.textContaining('(−40%)'), findsOneWidget);
    expect(
      find.textContaining('More than 20% below the estimate'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Actions for Cruz Construction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as awarded'));
    await tester.pumpAndSettle();
    expect(find.text('Awarded'), findsOneWidget);
    final quotes = projectsOf(tester).active.quotes;
    expect(
      [for (final q in quotes) (q.bidder, q.awarded)],
      [('Reyes Builders', false), ('Cruz Construction', true)],
    );
  });

  testWidgets('a bill for bidders is downloaded for one trade', (tester) async {
    await pumpApp(
      tester,
      location: '/project',
      size: size,
      prefs: projectPrefs(items),
    );
    await openFromMenu(tester, 'Bill of quantities for bidders');
    expect(find.text('Whole job'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'A. Structural works'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    // Tests have no browser to download to.
    expect(find.text("Downloads aren't supported here."), findsOneWidget);
  });
}
