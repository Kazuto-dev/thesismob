import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/core/format.dart';

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
      // The price is already filled in from the price book.
      find.textContaining('Enter wall length and wall height'),
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
    expect(find.textContaining('28 bags'), findsOneWidget);

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
    expect(projectsOf(tester).active.items, isEmpty);
  });

  testWidgets('the price comes from the price book until you type one', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    expect(find.text('24'), findsOneWidget);
    expect(find.textContaining('From your price book'), findsOneWidget);

    // A 6" block has its own price.
    await tester.ensureVisible(find.text('6"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6"'));
    await tester.pumpAndSettle();
    expect(find.text('32'), findsOneWidget);

    await tester.enterText(field('Price per block'), '30');
    await tester.pump();
    await tester.ensureVisible(find.text('4"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4"'));
    await tester.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
    expect(find.textContaining('Use price book price'), findsOneWidget);
  });

  testWidgets('companion materials are priced and added to the total', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);
    // Blocks ₱9,850 + 28 bags of cement, 2.5 m³ of sand, 22 bars and 1 kg
    // of tie wire at the suggested prices.
    const others = 28 * 240 + 2.5 * 1500 + 22 * 150 + 85;
    expect(find.text('Materials total'), findsOneWidget);
    expect(find.text(formatMoney(9850 + others)), findsWidgets);
  });

  testWidgets('"Add to project" adds once; new inputs start a new entry', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);

    final add = find.widgetWithText(FilledButton, 'Add to My project');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Added to My project'), findsOneWidget);
    final estimates = estimatesOf(tester);
    final projects = projectsOf(tester);
    expect(projects.active.items, hasLength(1));
    expect(projects.active.items.single.companions, hasLength(4));
    expect(estimates.history, hasLength(1));

    await tester.enterText(field('Wall height'), '4');
    await settle(tester);
    expect(find.text('Added to My project'), findsNothing);
    expect(find.text('Add to My project'), findsOneWidget);
    expect(estimates.history, hasLength(2));
    expect(projects.active.items.single.total, 9850);
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
    expect(projectsOf(tester).active.items, hasLength(1));
    expect(find.widgetWithText(FilledButton, 'Added'), findsOneWidget);
  });

  testWidgets('the same inputs under another name add a second item', (
    tester,
  ) async {
    await pumpApp(tester, location: chb);
    await fillWall(tester);
    final mark = find.byKey(const ValueKey('mark'));
    await tester.ensureVisible(mark);
    await tester.enterText(mark, 'W1');
    await tester.pump();
    final add = find.widgetWithText(FilledButton, 'Add to My project');
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Added to My project'), findsOneWidget);

    await tester.ensureVisible(mark);
    await tester.enterText(mark, 'W2');
    await tester.pump();
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    final items = projectsOf(tester).active.items;
    expect([for (final e in items) e.title], ['W1 – CHB 4"', 'W2 – CHB 4"']);
    expect(items.first.id, isNot(items.last.id));
  });

  testWidgets('editing a project item updates it instead of adding one', (
    tester,
  ) async {
    final item = sampleEstimate('e1', 'CHB 4"', 9850).copyWith(note: 'Kitchen');
    await pumpApp(
      tester,
      location: '$chb?estimate=e1&project=p1',
      prefs: projectPrefs([item]),
    );
    expect(find.text('Editing an item in Santos residence'), findsOneWidget);
    await tester.enterText(field('Wall height'), '4');
    final mark = find.byKey(const ValueKey('mark'));
    await tester.ensureVisible(mark);
    await tester.enterText(mark, 'W1');
    await tester.pump();

    final update = find.widgetWithText(FilledButton, 'Update item');
    await tester.ensureVisible(update);
    await tester.pumpAndSettle();
    await tester.tap(update);
    await tester.pumpAndSettle();

    final items = projectsOf(tester).byId('p1')!.items;
    expect(items, hasLength(1));
    expect(items.single.id, 'e1');
    expect(items.single.inputs['height'], 4);
    expect(items.single.mark, 'W1');
    expect(items.single.note, 'Kitchen', reason: 'the note is kept');
    // Back on the project, which shows the item under its new name.
    expect(find.text('W1 – CHB 4"'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
  });

  testWidgets('an edited item can be added as a new one instead', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '$chb?estimate=e1&project=p1',
      prefs: projectPrefs([sampleEstimate('e1', 'CHB 4"', 9850)]),
    );
    await tester.enterText(field('Wall height'), '4');
    await tester.pump();
    final addNew = find.text('Add as a new item');
    await tester.ensureVisible(addNew);
    await tester.pumpAndSettle();
    await tester.tap(addNew);
    await tester.pumpAndSettle();
    final items = projectsOf(tester).byId('p1')!.items;
    expect(items, hasLength(2));
    expect(items.first.inputs['height'], 3, reason: 'the original is kept');
    expect(items.last.inputs['height'], 4);
  });

  testWidgets('a length typed in centimetres is caught', (tester) async {
    await pumpApp(tester, location: '/category/structural/footing');
    // Units show before anything is typed.
    expect(find.text('m'), findsWidgets);
    await tester.enterText(field('Thickness'), '25');
    await tester.pump();
    expect(find.textContaining('Did you type cm?'), findsOneWidget);
    await tester.tap(find.text('Use 0.25 m'));
    await tester.pump();
    expect(find.textContaining('Did you type cm?'), findsNothing);
    expect(
      tester.widget<TextFormField>(field('Thickness')).controller!.text,
      '0.25',
    );
  });

  testWidgets('lengths can be typed in feet', (tester) async {
    await pumpApp(tester, location: chb);
    await tester.tap(find.text('ft'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Wall length'), '32.808');
    await tester.enterText(field('Wall height'), '9.843');
    await tester.pump();
    // The same wall as 10 × 3 m.
    expect(find.text('394 blocks'), findsWidgets);
    await settle(tester);
    expect(estimatesOf(tester).history.single.inputs['length'], 10);

    await tester.tap(find.text('m').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('Wall length')).controller!.text,
      '10',
    );
  });

  testWidgets('rarely changed options wait under "More options"', (
    tester,
  ) async {
    await pumpApp(tester, location: '/category/structural/slab');
    expect(find.text('Lap splice'), findsNothing);
    expect(find.textContaining('Lap splice: 40 × bar'), findsOneWidget);
    await tester.ensureVisible(find.text('More options'));
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Lap splice'), findsOneWidget);
    // Terms link to what they mean.
    await tester.ensureVisible(find.byTooltip('What is lap splice?'));
    await tester.tap(find.byTooltip('What is lap splice?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('joined by overlapping'), findsOneWidget);
  });

  testWidgets('calculators speak Filipino when asked', (tester) async {
    await pumpApp(tester, location: chb, prefs: {'language_v1': 'filipino'});
    expect(field('Haba ng pader'), findsOneWidget);
    expect(find.textContaining('Ilagay ang haba ng pader'), findsOneWidget);
    await tester.enterText(field('Haba ng pader'), '10');
    await tester.enterText(field('Taas ng pader'), '3');
    await tester.pump();
    expect(find.text('394 blocks'), findsWidgets);
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
