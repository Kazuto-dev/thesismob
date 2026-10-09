// Screenshot tests of key screens at phone and desktop widths.
//
// Font rendering differs between operating systems, so goldens are only
// compared on Linux (CI). Regenerate after intended UI changes with:
//   flutter test --update-goldens test/golden
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

final _skip = Platform.isLinux ? null : 'Goldens are compared on Linux only';

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(
      rootBundle.load('assets/fonts/poppins/Poppins-$weight.ttf'),
    );
  }
  await poppins.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();

  // The peso sign is not in Poppins; use Roboto as the web build does.
  final root = Platform.environment['FLUTTER_ROOT'];
  final roboto = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  if (root != null && roboto.existsSync()) {
    final bytes = roboto.readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
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

  final items = [
    sampleEstimate('a', 'CHB 4"', 9375),
    sampleEstimate('b', 'Tiles 30 × 30 cm floor', 11070),
    sampleEstimate('c', 'Paint, 2 coats', 1700),
  ];

  for (final (label, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('home on $label', skip: _skip != null, (tester) async {
      await pumpApp(tester, size: size, prefs: summaryPrefs(items));
      await _snapshot(tester, 'home_$label');
    });

    testWidgets('calculator result on $label', skip: _skip != null, (
      tester,
    ) async {
      await pumpApp(tester, size: size, location: '/category/structural/chb');
      await tester.enterText(field('Wall length'), '10');
      await tester.enterText(field('Wall height'), '3');
      await tester.enterText(field('Price per block'), '25');
      await tester.ensureVisible(find.text('Calculate'));
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      await _snapshot(tester, 'calculator_$label');
    });

    testWidgets('summary on $label', skip: _skip != null, (tester) async {
      await pumpApp(
        tester,
        size: size,
        location: '/summary',
        prefs: summaryPrefs(items),
      );
      await _snapshot(tester, 'summary_$label');
    });
  }
}
