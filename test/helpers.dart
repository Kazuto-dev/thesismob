import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/app.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/sheets_export_service.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/estimates_controller.dart';

const phone = Size(400, 900);
const tablet = Size(820, 1180);
const desktop = Size(1440, 900);

/// Pumps the whole app at [location] in a window of [size].
Future<void> pumpApp(
  WidgetTester tester, {
  String location = '/',
  Size size = phone,
  Map<String, Object> prefs = const {},
  SheetsExportService? exporter,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    BuildQuantifyApp(
      prefs: instance,
      initialLocation: location,
      exporter: exporter ?? SheetsExportService(endpoint: ''),
    ),
  );
  await tester.pumpAndSettle();
}

EstimatesController estimatesOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last).read<EstimatesController>();

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Saved-summary preferences holding [estimates].
Map<String, Object> summaryPrefs(List<Estimate> estimates) => {
  'estimates_summary_v2': jsonEncode([for (final e in estimates) e.toJson()]),
};

Estimate sampleEstimate(String id, String label, double total) => Estimate(
  id: id,
  materialId: 'chb',
  label: label,
  area: 30,
  quantity: total / 25,
  unit: QuantityUnit.blocks,
  unitPrice: 25,
  total: total,
  createdAt: DateTime(2026, 10, 9, 9),
  inputs: const {'length': 10, 'height': 3, 'price': 25},
  choices: const {'size': '4', 'waste': '5', 'plaster': '2'},
);
