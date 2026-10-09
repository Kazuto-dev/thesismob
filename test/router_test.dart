import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/app.dart';

Future<void> pumpAt(WidgetTester tester, String location) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    BuildQuantifyApp(prefs: prefs, initialLocation: location),
  );
  await tester.pumpAndSettle();
}

String? appBarTitle(WidgetTester tester) {
  final bar = tester.widget<AppBar>(find.byType(AppBar).last);
  final title = bar.title;
  return title is Text ? title.data : null;
}

void main() {
  testWidgets('old bookmarks redirect to the new screens', (tester) async {
    await pumpAt(tester, '/CHBpages');
    expect(appBarTitle(tester), 'Concrete Hollow Blocks');
  });

  testWidgets('short material links resolve to their category', (tester) async {
    await pumpAt(tester, '/material/roof');
    expect(appBarTitle(tester), 'Roofing Sheets');
  });

  testWidgets('a material under the wrong category is not found', (
    tester,
  ) async {
    await pumpAt(tester, '/category/plumbing/chb');
    expect(find.text('Page not found'), findsWidgets);
  });

  testWidgets('unknown paths show the not-found page', (tester) async {
    await pumpAt(tester, '/nope');
    expect(find.text('Page not found'), findsWidgets);
    expect(find.text('Go to home'), findsOneWidget);
  });
}
