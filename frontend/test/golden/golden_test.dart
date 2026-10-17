// Screenshot tests of key screens at phone and desktop widths.
//
// Font rendering differs between operating systems, so goldens are only
// compared on Linux (CI). Regenerate after intended UI changes with:
//   flutter test --update-goldens test/golden
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:thesismob/state/appearance_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/materials/material_spec.dart';

import 'package:thesismob/data/api_client.dart';

import '../fake_server.dart';
import '../helpers.dart';

final _skip = Platform.isLinux ? null : 'Goldens are compared on Linux only';

Future<void> _loadFonts() async {
  final jakarta = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(
      rootBundle.load('assets/fonts/jakarta/PlusJakartaSans-$weight.ttf'),
    );
  }
  await jakarta.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

/// Decodes every image on screen; widget tests otherwise draw them blank.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  await _settleImages(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);

  Estimate item(
    String id,
    String material,
    String label,
    double quantity,
    QuantityUnit unit,
    double price,
  ) => Estimate(
    id: id,
    materialId: material,
    label: label,
    quantity: quantity,
    unit: unit,
    unitPrice: price,
    total: quantity * price,
    createdAt: DateTime(2026, 10, 9, 9),
  );

  final items = [
    item('a', 'chb', 'CHB 4"', 394, QuantityUnit.blocks, 25),
    item('b', 'tiles', 'Tiles 60 × 60 cm', 70, QuantityUnit.pieces, 185),
    item('c', 'paint', 'Paint, latex, 2 coats', 3, QuantityUnit.gallons, 980),
    item(
      'd',
      'roof',
      'Corrugated GI, 8 ft (2.44 m)',
      60,
      QuantityUnit.sheets,
      520,
    ),
    item('e', 'bulb', 'LED bulb 9 W', 7, QuantityUnit.bulbs, 120),
    item('f', 'pvc', 'PVC pipe ½" (20 mm)', 9, QuantityUnit.pipes, 165),
  ];

  Future<void> fillWall(WidgetTester tester) async {
    await tester.enterText(field('Wall length'), '10');
    await tester.enterText(field('Wall height'), '3');
    await tester.enterText(field('Price per block'), '25');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  for (final (label, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('home on $label', skip: _skip != null, (tester) async {
      await pumpApp(tester, size: size, prefs: projectPrefs(items));
      await _snapshot(tester, 'home_$label');
    });

    testWidgets('calculator result on $label', skip: _skip != null, (
      tester,
    ) async {
      await pumpApp(tester, size: size, location: '/category/structural/chb');
      await fillWall(tester);
      if (label == 'phone') {
        await tester.ensureVisible(find.text('How it\'s worked out'));
        await tester.pumpAndSettle();
      }
      await _snapshot(tester, 'calculator_$label');
    });

    testWidgets('login on $label', skip: _skip != null, (tester) async {
      await pumpApp(tester, size: size, googleAuth: FakeGoogleAuth());
      await _snapshot(tester, 'login_$label');
    });

    testWidgets('project on $label', skip: _skip != null, (tester) async {
      await pumpApp(
        tester,
        size: size,
        location: '/project',
        prefs: projectPrefs(items),
      );
      await _snapshot(tester, 'project_$label');
    });
  }

  testWidgets('home for someone new to construction', skip: _skip != null, (
    tester,
  ) async {
    await pumpApp(
      tester,
      prefs: {AppearanceController.experienceKey: 'beginner'},
    );
    await _snapshot(tester, 'home_phone_beginner');
  });

  testWidgets(
    'calculator for someone new to construction',
    skip: _skip != null,
    (tester) async {
      await pumpApp(
        tester,
        location: '/category/structural/chb',
        prefs: {AppearanceController.experienceKey: 'beginner'},
      );
      await _snapshot(tester, 'calculator_phone_beginner');
    },
  );

  testWidgets('calculator in dark mode', skip: _skip != null, (tester) async {
    await pumpApp(
      tester,
      location: '/category/structural/chb',
      prefs: {AppearanceController.key: 'dark'},
    );
    await fillWall(tester);
    await tester.ensureVisible(find.text('How it\'s worked out'));
    await tester.pumpAndSettle();
    await _snapshot(tester, 'calculator_phone_dark');
  });

  testWidgets('slab calculator in Filipino', skip: _skip != null, (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/category/structural/slab',
      prefs: {AppearanceController.languageKey: 'filipino'},
    );
    await _snapshot(tester, 'calculator_phone_filipino');
  });

  for (final (label, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('prices on $label', skip: _skip != null, (tester) async {
      await pumpApp(tester, size: size, location: '/prices');
      await tester.tap(find.text('Cement and aggregates'));
      await tester.pumpAndSettle();
      await _snapshot(tester, 'prices_$label');
    });
  }

  for (final (label, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('plans on $label', skip: _skip != null, (tester) async {
      await pumpApp(
        tester,
        location: '/settings',
        size: size,
        apiClient: ApiClient(
          baseUrl: 'https://api.test',
          client: FakeServer().client,
        ),
        prefs: {AppearanceController.key: 'dark'},
      );
      await tester.ensureVisible(find.text('Compare plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compare plans'));
      await tester.pumpAndSettle();
      await _snapshot(tester, 'plans_$label');
    });
  }
}
