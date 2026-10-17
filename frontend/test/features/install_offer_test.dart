import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:thesismob/data/app_install.dart';
import 'package:thesismob/state/install_controller.dart';

import '../helpers.dart';

void main() {
  const settle = Duration(seconds: 4);

  testWidgets('on iPhone, offers the Share menu steps by itself', (
    tester,
  ) async {
    await pumpApp(tester, appInstaller: FakeAppInstaller());
    expect(find.text('Install BuildQuantify'), findsNothing);
    await tester.pump(settle);
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsOneWidget);
    expect(find.textContaining('Add to Home Screen'), findsOneWidget);
    expect(find.text('Install'), findsNothing);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsNothing);
    final install = tester
        .element(find.byType(NavigationBar))
        .read<InstallController>();
    expect(install.shouldOffer, isFalse);
  });

  testWidgets('once put off, it does not come back the next visit', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appInstaller: FakeAppInstaller(),
      prefs: {
        InstallController.dismissedKey: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      },
    );
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsNothing);
  });

  testWidgets('on Android, installs with one tap once Chrome allows it', (
    tester,
  ) async {
    final installer = FakeAppInstaller(platform: InstallPlatform.android);
    await pumpApp(tester, appInstaller: installer);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Install BuildQuantify'), findsNothing);

    installer.offer();
    await tester.pump(settle);
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Not now')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: sheet, matching: find.text('Install')),
    );
    await tester.pumpAndSettle();
    expect(installer.prompts, 1);
    expect(find.text('Install BuildQuantify'), findsNothing);
    expect(
      find.text('BuildQuantify is installed. Open it from your home screen.'),
      findsOneWidget,
    );
  });

  testWidgets('on Android without Chrome\'s offer, shows the menu steps', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appInstaller: FakeAppInstaller(platform: InstallPlatform.android),
    );
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsOneWidget);
    expect(find.textContaining('Install app, or Add to Home'), findsOneWidget);
  });

  testWidgets('inside Facebook or Messenger, says to open a browser first', (
    tester,
  ) async {
    await pumpApp(
      tester,
      appInstaller: FakeAppInstaller(
        platform: InstallPlatform.android,
        inAppBrowser: true,
      ),
    );
    await tester.pump(settle);
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot install apps'), findsOneWidget);
    expect(find.textContaining('Open in browser'), findsOneWidget);
  });

  for (final (where, installer) in [
    ('on computers', FakeAppInstaller(platform: InstallPlatform.other)),
    ('in the installed app', FakeAppInstaller(isInstalled: true)),
  ]) {
    testWidgets('never $where', (tester) async {
      await pumpApp(tester, appInstaller: installer);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Install BuildQuantify'), findsNothing);
    });
  }

  testWidgets('Settings has it on phones', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      appInstaller: FakeAppInstaller(),
      prefs: {InstallController.dismissedKey: DateTime.now().toIso8601String()},
    );
    expect(find.text('Install the app'), findsOneWidget);
    await tester.tap(find.text('How to install'));
    await tester.pumpAndSettle();
    expect(find.text('Install BuildQuantify'), findsOneWidget);
  });

  testWidgets('Settings does not have it on computers', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      appInstaller: FakeAppInstaller(platform: InstallPlatform.other),
    );
    expect(find.text('Install the app'), findsNothing);
  });
}
