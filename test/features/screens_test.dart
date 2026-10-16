import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:thesismob/core/format.dart';
import 'package:thesismob/data/google_sheets_client.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/features/common/tiles.dart';
import 'package:thesismob/features/projects/boq_grid.dart';
import 'package:thesismob/state/google_account_controller.dart';

import '../google_fake.dart';
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

  testWidgets('a first visit offers to plan a house with a checklist', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Plan a house'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Project name'),
      'Reyes house',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('0 of 26 done · next: Footings'), findsOneWidget);

    // Not every house needs everything.
    await tester.tap(find.byTooltip('Footings not needed'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 25 done · next: Wall Footings'), findsOneWidget);

    await tester.tap(find.text('Estimate').first);
    await tester.pumpAndSettle();
    expect(find.text('Wall footing length'), findsOneWidget);
    expect(projectsOf(tester).active.name, 'Reyes house');
  });

  testWidgets('"Not now" hides the first-visit card for good', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('a quick budget gives a range from the floor area', (
    tester,
  ) async {
    await pumpApp(tester, location: '/quick-budget');
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();
    expect(find.text('₱3,600,000.00 – ₱5,000,000.00'), findsOneWidget);
    await tester.tap(find.text('Economy'));
    await tester.pump();
    expect(find.text('₱2,800,000.00 – ₱3,600,000.00'), findsOneWidget);
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
      await tester.ensureVisible(find.byTooltip('Actions for Paint'));
      await tester.tap(find.byTooltip('Actions for Paint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
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

    testWidgets('saves to Google Sheets, then updates the same sheet', (
      tester,
    ) async {
      final api = FakeGoogleApi();
      await pumpApp(
        tester,
        location: '/project',
        prefs: {
          ...projectPrefs(items),
          GoogleAccountController.skippedKey: true,
        },
        googleAuth: FakeGoogleAuth(),
        sheetsClient: GoogleSheetsClient(client: api.client),
      );
      await tester.tap(find.text('Google Sheets'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Saved "BuildQuantify – Santos residence" to your Google Drive.',
        ),
        findsOneWidget,
      );
      expect(projectsOf(tester).active.sheetId, 'sheet1');
      expect(find.text('Update Google Sheet'), findsOneWidget);

      await tester.tap(find.text('Update Google Sheet'));
      await tester.pumpAndSettle();
      expect(api.spreadsheets, hasLength(1));
    });

    testWidgets('the contract tab bills progress and records changes', (
      tester,
    ) async {
      await pumpApp(tester, location: '/project', prefs: projectPrefs(items));
      await tester.tap(find.text('Contract'));
      await tester.pumpAndSettle();
      expect(find.text('Quotation'), findsOneWidget);
      expect(find.text('Download quotation'), findsOneWidget);

      // A variation order changes the contract price.
      final before = projectsOf(tester).active.breakdown.total;
      await tester.ensureVisible(find.text('Add a variation order'));
      await tester.tap(find.text('Add a variation order'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'What changed'),
        'Extra window',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Amount, with markups and VAT'),
        '18000',
      );
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();
      final contract = projectsOf(tester).active.contract;
      expect(contract.variations.single.amount, 18000);
      expect(find.text('Revised contract price'), findsOneWidget);
      expect(find.text(formatMoney(before + 18000)), findsWidgets);

      // A progress billing at half of every line.
      await tester.ensureVisible(find.text('New progress billing'));
      await tester.tap(find.text('New progress billing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All 50%'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final billing = projectsOf(tester).active.contract.billings.single;
      expect(billing.progress.values, everyElement(50));
      expect(find.textContaining('Billing 1 ·'), findsOneWidget);
      expect(find.textContaining('50% complete · net due'), findsOneWidget);
    });

    testWidgets('an item shows the unit price analysis of its work', (
      tester,
    ) async {
      final spec = materialById('footing')!;
      const inputs = {
        'count': 4.0,
        'length': 1.2,
        'width': 1.2,
        'thickness': 0.25,
        'price': 240.0,
      };
      final footing = Estimate.fromResult(
        materialId: 'footing',
        result: spec.calculate(inputs, spec.initialChoices),
        inputs: inputs,
        choices: spec.initialChoices,
      );
      await pumpApp(
        tester,
        location: '/project',
        size: const Size(400, 1400),
        prefs: projectPrefs([footing]),
      );
      await tester.tap(find.byType(EstimateTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Unit price analysis'), findsOneWidget);
      await tester.tap(find.text('Structural concrete, footings'));
      await tester.pumpAndSettle();
      expect(find.text('Direct cost per m³'), findsOneWidget);
      expect(
        find.text('Reinforcing steel, cut, bent and tied in place'),
        findsOneWidget,
      );
    });

    testWidgets('desktops show the budget beside the items', (tester) async {
      await pumpApp(
        tester,
        location: '/project',
        size: desktop,
        prefs: projectPrefs(items),
      );
      expect(find.text('Daily rates'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
    });

    testWidgets('desktops edit unit prices in the bill of quantities grid', (
      tester,
    ) async {
      await pumpApp(
        tester,
        location: '/project',
        size: desktop,
        prefs: projectPrefs(items),
      );
      expect(find.text('Unit price'), findsOneWidget);
      final cell = find.bySemanticsLabel(
        RegExp(r'^Unit price of CHB 4", ₱25\.00'),
      );
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(BoqGrid),
          matching: find.byType(TextField),
        ),
        '30',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final chb = projectsOf(tester).active.items
          .firstWhere((e) => e.label == 'CHB 4"');
      expect(chb.unitPrice, 30);
      expect(chb.total, 40 * 30);
      expect(chb.inputs['price'], 30, reason: 'reopens at the new price');
    });

    testWidgets('explains the empty state', (tester) async {
      await pumpApp(tester, location: '/project');
      expect(find.text('No estimates yet'), findsOneWidget);
      await tester.tap(find.text('Add an estimate'));
      await tester.pumpAndSettle();
      // A sheet of calculators to choose from.
      await tester.enterText(find.byType(TextField).last, 'footing');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Footings'));
      await tester.pumpAndSettle();
      expect(find.text('Footing length'), findsOneWidget);
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
    testWidgets('explains when Google sign-in is not set up', (tester) async {
      await pumpApp(tester, location: '/settings');
      expect(
        find.textContaining("Google sign-in isn't set up"),
        findsOneWidget,
      );
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('signs in and out of Google', (tester) async {
      await pumpApp(
        tester,
        location: '/settings',
        googleAuth: FakeGoogleAuth(),
        sheetsClient: GoogleSheetsClient(client: FakeGoogleApi().client),
        prefs: {GoogleAccountController.skippedKey: true},
      );
      expect(find.text('Signed out'), findsOneWidget);
      await tester.ensureVisible(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('maria@example.com'), findsOneWidget);
      expect(find.text('Signed in'), findsOneWidget);

      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      // Signing out shows the login screen again.
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('the app can be shown in Filipino', (tester) async {
      await pumpApp(tester, location: '/settings');
      await tester.ensureVisible(find.text('Filipino'));
      await tester.tap(find.text('Filipino'));
      await tester.pumpAndSettle();
      expect(find.text('Kasaysayan'), findsOneWidget);
      expect(find.text('Hitsura at unit'), findsOneWidget);

      await tester.tap(find.text('Estimate').first);
      await tester.pumpAndSettle();
      expect(find.text('Mga kategorya'), findsOneWidget);
    });

    testWidgets('switches between light and dark themes', (tester) async {
      await pumpApp(tester, location: '/settings');
      expect(
        Theme.of(tester.element(find.text('Appearance and units'))).brightness,
        Brightness.light,
      );
      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Appearance and units'))).brightness,
        Brightness.dark,
      );
    });
  });
}
