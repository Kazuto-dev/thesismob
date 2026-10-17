import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/app.dart';
import 'package:thesismob/data/api_client.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/google_auth.dart';
import 'package:thesismob/data/google_sheets_client.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/state/estimates_controller.dart';
import 'package:thesismob/state/price_book_controller.dart';
import 'package:thesismob/state/projects_controller.dart';

const phone = Size(400, 900);
const tablet = Size(820, 1180);
const desktop = Size(1440, 900);

/// Pumps the whole app at [location] in a window of [size].
Future<void> pumpApp(
  WidgetTester tester, {
  String location = '/',
  Size size = phone,
  Map<String, Object> prefs = const {},
  GoogleAuth? googleAuth,
  GoogleSheetsClient? sheetsClient,
  ApiClient? apiClient,
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
      googleAuth: googleAuth ?? FakeGoogleAuth(configured: false),
      sheetsClient: sheetsClient ?? GoogleSheetsClient(client: _offline),
      apiClient: apiClient ?? ApiClient(baseUrl: ''),
    ),
  );
  await tester.pumpAndSettle();
}

/// Google sign-in that never opens a window: it hands out [token], or
/// fails with [failure].
class FakeGoogleAuth implements GoogleAuth {
  FakeGoogleAuth({this.configured = true, this.failure});

  final bool configured;
  GoogleAuthFailure? failure;
  int authorizations = 0;
  final forgotten = <String>[];
  bool signedOut = false;

  @override
  bool get isConfigured => configured;

  @override
  void warmUp() {}

  @override
  Future<String> authorize() async {
    if (!configured) {
      throw const GoogleAuthException(GoogleAuthFailure.notConfigured);
    }
    if (failure case final f?) throw GoogleAuthException(f);
    authorizations++;
    return 'token-$authorizations';
  }

  @override
  Future<void> forget(String token) async => forgotten.add(token);

  @override
  Future<void> signOut() async => signedOut = true;
}

final _offline = MockClient((_) async => throw Exception('offline in tests'));

EstimatesController estimatesOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last).read<EstimatesController>();

ProjectsController projectsOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last).read<ProjectsController>();

PriceBookController pricesOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last).read<PriceBookController>();

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Preferences holding one active project with [estimates].
Map<String, Object> projectPrefs(
  List<Estimate> estimates, {
  String name = 'Santos residence',
  Map<String, Object?> costs = const {},
}) => {
  'projects_v1': jsonEncode([
    {
      'id': 'p1',
      'name': name,
      'client': 'Maria Santos',
      'location': 'Antipolo, Rizal',
      'createdAt': '2026-10-01T09:00:00.000',
      'updatedAt': '2026-10-09T09:00:00.000',
      'items': [for (final e in estimates) e.toJson()],
      if (costs.isNotEmpty) 'costs': costs,
    },
  ]),
  'active_project_v1': 'p1',
};

/// Preferences from before projects, holding a summary of [estimates].
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
