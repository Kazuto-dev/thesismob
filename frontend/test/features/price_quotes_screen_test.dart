import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  testWidgets('a price in the price book records its supplier', (tester) async {
    await pumpApp(tester, location: '/prices');
    await tester.tap(find.text('Cement and aggregates'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Portland cement, 40 kg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portland cement, 40 kg'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Price per bag'),
      '255',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Supplier'),
      'Wilcon Depot',
    );
    expect(find.textContaining('Quoted '), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final book = pricesOf(tester);
    expect(book.priceOf('cement_40kg'), 255);
    expect(book.quoteOf('cement_40kg')?.supplier, 'Wilcon Depot');
    expect(book.quoteOf('cement_40kg')?.date, isNotNull);
    expect(find.textContaining('Wilcon Depot · quoted'), findsOneWidget);
  });
}
