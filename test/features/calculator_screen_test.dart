import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  const chb = '/category/structural/chb';

  Future<void> fillWall(WidgetTester tester) async {
    await tester.enterText(field('Wall length'), '10');
    await tester.enterText(field('Wall height'), '3');
    await tester.enterText(field('Price per block'), '25');
    await tester.pump();
  }

  /// Lets the debounced history recording run.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('says what is missing, and flags invalid input', (tester) async {
    await pumpApp(tester, location: chb);
    expect(
      find.textContaining('Enter wall length, wall height and the price'),
      findsOneWidget,
    );
    expect(find.text('Total cost'), findsNothing);

    // Letters and minus signs never reach the field.
    await tester.enterText(field('Wall length'), 'abc-5');
    expect(find.text('5'), findsOneWidget);

    await tester.enterText(field('Wall length'), '0');
    await tester.enterText(field('Wall height'), '500');
    await tester.enterText(field('Price per block'), '25');
    await tester.pump();
    expect(find.text('Must be more than 0'), findsOneWidget);
    expect(find.text('Must be 100 or less'), findsOneWidget);
    expect(find.text('Total cost'), findsNothing);
    await settle(tester);
    expect(estimatesOf(tester).history, isEmpty);
  });

  testWidgets('the estimate updates as you type', (tester) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);

    // 375 blocks plus the default 5% waste.
    expect(find.text('₱9,850.00'), findsWidgets);
    expect(find.text('394 blocks'), findsWidgets);
    expect(find.text('28 bags'), findsOneWidget);

    await tester.ensureVisible(find.text('None').first);
    await tester.tap(find.text('None').first);
    await tester.pump();
    expect(find.text('₱9,375.00'), findsWidgets);
    expect(find.text('375 blocks'), findsWidgets);
  });

  testWidgets('openings larger than the wall are explained', (tester) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);
    await tester.enterText(field('Doors and windows'), '40');
    await tester.pump();
    expect(find.text('Check your measurements'), findsOneWidget);
    expect(find.text('Total cost'), findsNothing);
  });

  testWidgets('history keeps the latest result of a visit', (tester) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);
    await settle(tester);
    final estimates = estimatesOf(tester);
    expect(estimates.history, hasLength(1));
    expect(estimates.history.single.total, 9850);

    // Editing replaces the entry instead of adding one per keystroke.
    await tester.enterText(field('Price per block'), '30');
    await settle(tester);
    expect(estimates.history, hasLength(1));
    expect(estimates.history.single.total, 394 * 30);
    expect(estimates.summary, isEmpty);
  });

  testWidgets('"Add to summary" adds once; new inputs start a new entry', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);

    final add = find.widgetWithText(FilledButton, 'Add to summary');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Added to summary'), findsOneWidget);
    final estimates = estimatesOf(tester);
    expect(estimates.summary, hasLength(1));
    expect(estimates.history, hasLength(1));

    await tester.enterText(field('Wall height'), '4');
    await settle(tester);
    expect(find.text('Added to summary'), findsNothing);
    expect(find.text('Add to summary'), findsOneWidget);
    expect(estimates.history, hasLength(2));
    expect(estimates.summary.single.total, 9850);
  });

  testWidgets('the bar on phones shows the live total and adds it', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    expect(find.widgetWithText(FilledButton, 'Add'), findsNothing);
    await fillWall(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(estimatesOf(tester).summary, hasLength(1));
    expect(find.widgetWithText(FilledButton, 'Added'), findsOneWidget);
  });

  testWidgets('roofing switches inputs for long-span sheets', (tester) async {
    await pumpApp(tester, location: '/category/architectural/roof');
    expect(find.text('Side lap'), findsOneWidget);
    expect(field('Price per sheet'), findsOneWidget);

    await tester.tap(find.text('Long-span rib type'));
    await tester.pumpAndSettle();
    expect(find.text('Side lap'), findsNothing);
    expect(find.text('Effective width'), findsOneWidget);
    expect(field('Price per metre'), findsOneWidget);
    expect(field('Price per sheet'), findsNothing);
  });

  testWidgets('a history entry reopens with its inputs', (tester) async {
    await pumpApp(
      tester,
      location: '$chb?estimate=e1',
      prefs: {
        'estimates_history_v2': summaryPrefs([
          sampleEstimate('e1', 'CHB 4"', 9850),
        ]).values.first,
      },
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('₱9,850.00'), findsWidgets);
    await settle(tester);
    // Reopening does not duplicate the entry.
    expect(estimatesOf(tester).history, hasLength(1));
  });

  testWidgets('definitions and formulas open in a sheet', (tester) async {
    await pumpApp(tester, location: chb);
    await tester.tap(find.text('Definitions'));
    await tester.pumpAndSettle();
    expect(find.text('Concrete hollow block (CHB)'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Concrete hollow block (CHB)'), findsNothing);

    await tester.tap(find.text("How it's calculated"));
    await tester.pumpAndSettle();
    expect(find.text('Area to build'), findsOneWidget);
    expect(find.text('area = length × height − openings'), findsOneWidget);
  });
}
