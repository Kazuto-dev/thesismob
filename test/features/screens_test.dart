import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:thesismob/core/format.dart';
import 'package:thesismob/data/project.dart';

import '../helpers.dart';

void main() {
  group('navigation adapts to the window width', () {
    testWidgets('phones get a bottom navigation bar', (tester) async {
      await pumpApp(tester, size: phone);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('tablets get a navigation rail with labels', (tester) async {
      await pumpApp(tester, size: tablet);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.all);
    });

    testWidgets('desktops get an extended rail', (tester) async {
      await pumpApp(tester, size: desktop);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });
  });

  testWidgets('home lists all four categories on a phone', (tester) async {
    await pumpApp(tester);
    for (final c in ['Structural', 'Architectural', 'Electrical', 'Plumbing']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(find.text('Popular calculators'), findsOneWidget);
  });

  testWidgets('home search finds materials by Filipino names', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'yero');
    await tester.pump();
    expect(find.text('1 material'), findsOneWidget);
    expect(find.text('Roofing Sheets'), findsOneWidget);
    expect(find.text('Categories'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('a category card opens its materials', (tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.text('Electrical'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Electrical'));
    await tester.pumpAndSettle();
    expect(find.text('Electrical materials'), findsOneWidget);
    expect(find.text('Light Bulb'), findsOneWidget);

    // Back returns home instead of stacking a new home page.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);
  });

  group('project', () {
    final items = [
      sampleEstimate('a', 'CHB 4"', 1000),
      sampleEstimate('b', 'Tiles', 15000000),
      sampleEstimate('c', 'Paint', 1250.5),
    ];
    // Materials plus 40% labour and a 10% contingency.
    final budget = Project.create('x').copyWith(items: items).breakdown.total;

    testWidgets('a summary from an earlier version opens as a project', (
      tester,
    ) async {
      await pumpApp(tester, location: '/project', prefs: summaryPrefs(items));
      expect(find.text('My project'), findsWidgets);
      expect(find.text('Project budget · 3 items'), findsOneWidget);
      expect(find.text(formatMoney(budget)), findsOneWidget);
      // The materials in the budget and the structural subtotal.
      expect(find.text('₱15,002,250.50'), findsNWidgets(2));
    });

    testWidgets('removing an item updates the total and can be undone', (
      tester,
    ) async {
      await pumpApp(tester, location: '/project', prefs: projectPrefs(items));
      expect(find.text('Santos residence'), findsWidgets);
      expect(find.text('Maria Santos · Antipolo, Rizal'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Remove Paint'));
      await tester.tap(find.byTooltip('Remove Paint'));
      await tester.pumpAndSettle();
      expect(find.text('₱15,001,000.00'), findsNWidgets(2));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('₱15,002,250.50'), findsNWidgets(2));
    });

    testWidgets('the shopping list merges materials and takes prices', (
      tester,
    ) async {
      await pumpApp(tester, location: '/project', prefs: projectPrefs(items));
      await tester.tap(find.text('To buy'));
      await tester.pumpAndSettle();
      expect(find.text('Masonry'), findsOneWidget);
      expect(find.text('Materials total'), findsOneWidget);
    });

    testWidgets('a contractor bid adds markups and VAT', (tester) async {
      await pumpApp(tester, location: '/project', prefs: projectPrefs(items));
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contractor'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Total contract price'), findsWidgets);
      expect(find.text('VAT, 12%'), findsOneWidget);
      expect(projectsOf(tester).active.costs, CostSettings.contractor);
    });

    testWidgets('desktops show the budget beside the items', (tester) async {
      await pumpApp(
        tester,
        location: '/project',
        size: desktop,
        prefs: projectPrefs(items),
      );
      expect(find.text('Labour by trade'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
    });

    testWidgets('explains the empty state', (tester) async {
      await pumpApp(tester, location: '/project');
      expect(find.text('No estimates yet'), findsOneWidget);
      await tester.tap(find.text('Start an estimate'));
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('new projects are created from the projects list', (
      tester,
    ) async {
      await pumpApp(tester, location: '/project/all');
      expect(find.text('My project'), findsOneWidget);
      await tester.tap(find.text('New project'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Project name'),
        'Garage',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(projectsOf(tester).active.name, 'Garage');
      expect(find.text('No estimates yet'), findsOneWidget);
    });
  });

  testWidgets('the price book edits and resets prices', (tester) async {
    await pumpApp(tester, location: '/settings/prices');
    await tester.enterText(find.byType(TextField).first, 'portland');
    await tester.pumpAndSettle();
    expect(find.text('Portland cement, 40 kg'), findsOneWidget);
    expect(find.text('₱240.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Portland cement, 40 kg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portland cement, 40 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '265');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('₱265.00'), findsOneWidget);
    expect(find.text('Your price'), findsOneWidget);
    expect(pricesOf(tester).priceOf('cement_40kg'), 265);

    await tester.ensureVisible(find.byTooltip('Use the suggested price'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Use the suggested price'));
    await tester.pumpAndSettle();
    expect(find.text('₱240.00'), findsOneWidget);
  });

  testWidgets('history explains the empty state', (tester) async {
    await pumpApp(tester, location: '/history');
    expect(find.text('No calculations yet'), findsOneWidget);
  });

  group('settings', () {
    testWidgets('accepts a sheet link and rejects other text', (tester) async {
      await pumpApp(tester, location: '/settings');
      expect(
        find.textContaining("isn't set up for this build"),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Spreadsheet link or ID'),
        'not a sheet',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sheet tab name'),
        'Sheet1',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('That does not look like a spreadsheet link or ID.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Spreadsheet link or ID'),
        'https://docs.google.com/spreadsheets/d/1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789/edit',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Sending to "Sheet1"'), findsOneWidget);
    });

    testWidgets('switches between light and dark themes', (tester) async {
      await pumpApp(tester, location: '/settings');
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light,
      );
      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
    });
  });
}
