import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/data/app_install.dart';
import 'package:thesismob/state/install_controller.dart';

import '../helpers.dart';

void main() {
  var now = DateTime(2026, 10, 17, 9);

  Future<InstallController> controller(
    FakeAppInstaller installer, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return InstallController(
      await SharedPreferences.getInstance(),
      installer,
      now: () => now,
    );
  }

  setUp(() => now = DateTime(2026, 10, 17, 9));

  test('offers on phones, not on computers or the installed app', () async {
    expect((await controller(FakeAppInstaller())).shouldOffer, isTrue);
    expect(
      (await controller(FakeAppInstaller(platform: InstallPlatform.android)))
          .shouldOffer,
      isTrue,
    );
    expect(
      (await controller(FakeAppInstaller(platform: InstallPlatform.other)))
          .shouldOffer,
      isFalse,
    );
    final installed = await controller(FakeAppInstaller(isInstalled: true));
    expect(installed.isAvailable, isFalse);
    expect(installed.shouldOffer, isFalse);
  });

  test('"Not now" holds the offer back for a week', () async {
    final install = await controller(FakeAppInstaller());
    install.dismiss();
    expect(install.shouldOffer, isFalse);
    // Still available from Settings meanwhile.
    expect(install.isAvailable, isTrue);
    now = now.add(const Duration(days: 6));
    expect(install.shouldOffer, isFalse);
    now = now.add(const Duration(days: 1));
    expect(install.shouldOffer, isTrue);
  });

  test('installing asks the browser; declining puts the offer off', () async {
    final installer = FakeAppInstaller(
      platform: InstallPlatform.android,
      canInstall: true,
    );
    final install = await controller(installer);
    expect(await install.install(), isTrue);
    expect(installer.prompts, 1);
    expect(install.shouldOffer, isTrue);

    installer
      ..accept = false
      ..canInstall = true;
    expect(await install.install(), isFalse);
    expect(install.shouldOffer, isFalse);
  });

  test('tells its listeners when Chrome offers to install', () async {
    final installer = FakeAppInstaller(platform: InstallPlatform.android);
    final install = await controller(installer);
    var changes = 0;
    install.addListener(() => changes++);
    installer.offer();
    expect(changes, 1);
    expect(install.canInstall, isTrue);
  });
}
