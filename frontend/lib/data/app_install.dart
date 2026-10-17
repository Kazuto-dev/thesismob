import 'app_install_stub.dart'
    if (dart.library.js_interop) 'app_install_web.dart'
    as platform;

/// The kind of device the web app is open on, for how it installs.
enum InstallPlatform {
  /// Android: Chrome and most browsers can install the app themselves.
  android,

  /// iPhone and iPad: only by the user, from the Share menu.
  ios,

  /// Computers, and anything else.
  other,
}

/// Installing BuildQuantify on the home screen as an app, as far as the
/// browser allows it. Replaced by a fake in tests.
abstract interface class AppInstaller {
  InstallPlatform get platform;

  /// Running as the installed app, opened from the home screen.
  bool get isInstalled;

  /// Open inside another app's browser (Facebook, Messenger, Instagram…),
  /// which cannot install apps.
  bool get inAppBrowser;

  /// The browser has offered to install the app, so [install] can show its
  /// install dialog.
  bool get canInstall;

  /// Called when [canInstall] or [isInstalled] changes.
  set onChanged(void Function()? callback);

  /// Shows the browser's install dialog. True when the user accepts.
  Future<bool> install();
}

/// The installer for the platform the app runs on.
AppInstaller createAppInstaller() => platform.createAppInstaller();
