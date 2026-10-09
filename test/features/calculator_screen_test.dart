import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  const chb = '/category/structural/chb';

  Future<void> calculate(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Calculate'));
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty and invalid input show messages and no result', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    await calculate(tester);
    expect(find.text('Enter a wall length'), findsOneWidget);
    expect(find.text('Enter the price per block'), findsOneWidget);
    expect(find.text('Total cost'), findsNothing);

    // Letters and minus signs never reach the field.
    await tester.enterText(field('Wall length'), 'abc-5');
    expect(find.text('5'), findsOneWidget);

    await tester.enterText(field('Wall length'), '0');
    await tester.enterText(field('Wall height'), '500');
    await tester.enterText(field('Price per block'), '25');
    await calculate(tester);
    expect(find.text('Must be more than 0'), findsOneWidget);
    expect(find.text('Must be 100 or less'), findsOneWidget);
    expect(estimatesOf(tester).history, isEmpty);
  });

  testWidgets('a valid calculation shows the estimate but does not touch '
      'the summary', (tester) async {
    await pumpApp(tester, location: chb);
    await tester.enterText(field('Wall length'), '10');
    await tester.enterText(field('Wall height'), '3');
    await tester.enterText(field('Price per block'), '25');
    await calculate(tester);

    expect(find.text('₱9,375.00'), findsOneWidget);
    expect(find.text('375 blocks'), findsWidgets);
    expect(find.text('30 m²'), findsOneWidget);

    final estimates = estimatesOf(tester);
    expect(estimates.history, hasLength(1));
    expect(estimates.summary, isEmpty);

    // Calculating again with the same inputs does not duplicate history.
    await calculate(tester);
    expect(estimates.history, hasLength(1));
  });

  testWidgets('"Add to summary" adds once, then the result goes stale when '
      'inputs change', (tester) async {
    await pumpApp(tester, location: chb);
    await tester.enterText(field('Wall length'), '10');
    await tester.enterText(field('Wall height'), '3');
    await tester.enterText(field('Price per block'), '25');
    await calculate(tester);

    await tester.ensureVisible(find.text('Add to summary'));
    await tester.tap(find.text('Add to summary'));
    await tester.pumpAndSettle();
    expect(find.text('Added to summary'), findsOneWidget);
    expect(estimatesOf(tester).summary, hasLength(1));

    await tester.enterText(field('Wall height'), '4');
    await tester.pump();
    expect(find.textContaining('Your inputs changed'), findsOneWidget);
  });

  testWidgets('roof asks for the side lap only for corrugated sheets', (
    tester,
  ) async {
    await pumpApp(tester, location: '/category/architectural/roof');
    expect(find.text('Side lap'), findsNothing);

    await tester.tap(find.text('Roof type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corrugated').last);
    await tester.pumpAndSettle();
    expect(find.text('Side lap'), findsOneWidget);
  });

  testWidgets('a history entry reopens with its inputs', (tester) async {
    await pumpApp(
      tester,
      location: '$chb?estimate=e1',
      prefs: {
        'estimates_history_v2': summaryPrefs([
          sampleEstimate('e1', 'CHB 4"', 9375),
        ]).values.first,
      },
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('₱9,375.00'), findsOneWidget);
  });

  testWidgets('definitions open in a sheet', (tester) async {
    await pumpApp(tester, location: chb);
    await tester.tap(find.text('Definitions'));
    await tester.pumpAndSettle();
    expect(find.text('Wall Height'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Wall Height'), findsNothing);
  });
}
