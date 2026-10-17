import 'app_install.dart';

/// Outside the browser there is nothing to install.
AppInstaller createAppInstaller() => const _NoInstaller();

class _NoInstaller implements AppInstaller {
  const _NoInstaller();

  @override
  InstallPlatform get platform => InstallPlatform.other;

  @override
  bool get isInstalled => false;

  @override
  bool get inAppBrowser => false;

  @override
  bool get canInstall => false;

  @override
  set onChanged(void Function()? callback) {}

  @override
  Future<bool> install() async => false;
}
