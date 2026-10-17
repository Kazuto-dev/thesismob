import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n.dart';

/// How the user measures lengths. Calculations and results stay metric.
enum LengthUnit { metres, feet }

/// Whether the user knows construction: the Homeowners Edition shows
/// everyday words to beginners and trade names to experienced users.
enum Experience { beginner, experienced }

/// The light, dark or system colour theme the user picked, whether they
/// measure in metres or feet, their language, and whether they know
/// construction.
class AppearanceController extends ChangeNotifier {
  AppearanceController(this._prefs)
    : _mode = ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(key),
        orElse: () => ThemeMode.system,
      ),
      _lengthUnit = LengthUnit.values.firstWhere(
        (u) => u.name == _prefs.getString(lengthUnitKey),
        orElse: () => LengthUnit.metres,
      ),
      _language = AppLanguage.values.firstWhere(
        (l) => l.name == _prefs.getString(languageKey),
        orElse: () => AppLanguage.english,
      ),
      _experience = Experience.values
          .asNameMap()[_prefs.getString(experienceKey)];

  static const key = 'theme_mode';
  static const lengthUnitKey = 'length_unit_v1';
  static const languageKey = 'language_v1';
  static const experienceKey = 'experience_v1';

  final SharedPreferences _prefs;
  ThemeMode _mode;
  LengthUnit _lengthUnit;
  AppLanguage _language;
  Experience? _experience;

  /// Whether the user knows construction, or null until they have said.
  Experience? get experience => _experience;

  void setExperience(Experience experience) {
    if (experience == _experience) return;
    _experience = experience;
    unawaited(_prefs.setString(experienceKey, experience.name));
    notifyListeners();
  }

  /// The language the app is shown in.
  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    unawaited(_prefs.setString(languageKey, language.name));
    notifyListeners();
  }

  ThemeMode get mode => _mode;

  LengthUnit get lengthUnit => _lengthUnit;

  void setLengthUnit(LengthUnit unit) {
    if (unit == _lengthUnit) return;
    _lengthUnit = unit;
    unawaited(_prefs.setString(lengthUnitKey, unit.name));
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    unawaited(_prefs.setString(key, mode.name));
    notifyListeners();
  }
}
