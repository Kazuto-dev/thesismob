import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:thesismob/data/custom_items.dart';
import 'package:thesismob/state/projects_controller.dart';

import '../helpers.dart';

void main() {
  testWidgets('a custom item is added from the picker and can be changed', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/project',
      size: const Size(400, 1400),
      prefs: projectPrefs([sampleEstimate('a', 'CHB 4"', 1000)]),
    );
    await tester.tap(find.text('Add an estimate').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom item or lump sum'));
    await tester.pumpAndSettle();

    // Nothing is added until it is described and priced.
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Describe the work'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Description'),
      'Solar panels, 3 kW',
    );
    await tester.tap(find.text('Subcontract'));
    await tester.pumpAndSettle();
    expect(find.text('Labour per lot'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'All-in price per lot'),
      '180000',
    );
    await tester.pumpAndSettle();
    expect(find.text('₱180,000.00'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final project = context.read<ProjectsController>().active;
    final solar = project.items.last;
    expect(solar.isCustom, isTrue);
    expect(solar.customKind, CustomKind.subcontract);
    expect(project.breakdown.subcontracts, 180000);
    expect(find.text('Solar panels, 3 kW'), findsWidgets);

    // Its menu opens the same dialog to change it.
    await tester.ensureVisible(
      find.byTooltip('Actions for Solar panels, 3 kW'),
    );
    await tester.tap(find.byTooltip('Actions for Solar panels, 3 kW'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Change custom item'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'All-in price per lot'),
      '175000',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      context.read<ProjectsController>().active.breakdown.subcontracts,
      175000,
    );
  });
}
