import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_install.dart';

/// Whether to offer installing BuildQuantify on the phone's home screen,
/// and installing it.
class InstallController extends ChangeNotifier {
  InstallController(this._prefs, this._installer, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _installer.onChanged = notifyListeners;
  }

  static const dismissedKey = 'install_offer_dismissed_v1';

  /// How long "Not now" holds the offer back.
  static const snooze = Duration(days: 7);

  final SharedPreferences _prefs;
  final AppInstaller _installer;
  final DateTime Function() _now;

  InstallPlatform get platform => _installer.platform;
  bool get inAppBrowser => _installer.inAppBrowser;
  bool get canInstall => _installer.canInstall;

  /// On a phone or tablet, and not already opened as the installed app.
  bool get isAvailable =>
      platform != InstallPlatform.other && !_installer.isInstalled;

  /// Whether to bring the offer up by itself: available, and not put off
  /// within the last [snooze].
  bool get shouldOffer {
    if (!isAvailable) return false;
    final dismissed = DateTime.tryParse(_prefs.getString(dismissedKey) ?? '');
    return dismissed == null || _now().difference(dismissed) >= snooze;
  }

  /// The user put the offer off; it comes back after [snooze].
  void dismiss() {
    _prefs.setString(dismissedKey, _now().toIso8601String());
    notifyListeners();
  }

  /// Shows the browser's install dialog. True when the app was installed.
  Future<bool> install() async {
    final accepted = await _installer.install();
    if (!accepted) dismiss();
    return accepted;
  }

  @override
  void dispose() {
    _installer.onChanged = null;
    super.dispose();
  }
}
