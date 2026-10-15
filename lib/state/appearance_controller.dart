import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The light, dark or system colour theme the user picked.
class AppearanceController extends ChangeNotifier {
  AppearanceController(this._prefs)
    : _mode = ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(key),
        orElse: () => ThemeMode.system,
      );

  static const key = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    unawaited(_prefs.setString(key, mode.name));
    notifyListeners();
  }
}
