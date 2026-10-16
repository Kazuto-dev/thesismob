import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:thesismob/data/rooms.dart';

import '../helpers.dart';

Finder _input(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('adding a room and making its finish estimates', (tester) async {
    await pumpApp(
      tester,
      location: '/project/p1/rooms',
      prefs: projectPrefs(const []),
    );
    expect(find.text('Update finishes from rooms'), findsOneWidget);

    await tester.tap(find.text('Add a room'));
    await tester.pumpAndSettle();
    await tester.enterText(_input('Room name'), 'Living');
    await tester.enterText(_input('Length'), '4');
    await tester.enterText(_input('Width'), '5');
    await tester.tap(find.text('Add a door'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final project = projectsOf(tester).byId('p1')!;
    expect(project.rooms.single.name, 'Living');
    expect(project.rooms.single.openings.single.isDoor, isTrue);
    expect(project.floorArea, 20, reason: 'filled in from the rooms');
    expect(find.text('Living'), findsOneWidget);
    expect(find.text('The rooms have no finish estimates yet.'), findsOne);

    await tester.tap(find.text('Update finishes from rooms'));
    await tester.pumpAndSettle();

    final items = projectsOf(tester).byId('p1')!.items;
    expect(items, isNotEmpty);
    expect(items.every((e) => e.fromRooms), isTrue);
    expect(
      items.map((e) => e.materialId),
      containsAll(['tiles', 'paint', 'ceiling']),
    );
    expect(items.first.title, 'Ground floor, floors – Tiles 60 × 60 cm');
    expect(
      find.text('The {n} finish estimates match the rooms.'),
      findsNothing,
    );
    expect(
      find.text('The ${items.length} finish estimates match the rooms.'),
      findsOneWidget,
    );

    // Back on the project, the rooms card says the finishes are current.
    await tester.tap(find.text('Back to the project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Finishes up to date'), findsOneWidget);
    expect(find.text('Ground floor, floors – Tiles 60 × 60 cm'), findsWidgets);
  });

  testWidgets('a project without rooms offers to enter them', (tester) async {
    await pumpApp(tester, location: '/project', prefs: projectPrefs(const []));
    await tester.tap(find.text('Enter rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
  });
}
