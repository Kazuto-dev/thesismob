import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which one-time tips, such as the "Get started" card, the user has
/// dismissed.
class TipsController extends ChangeNotifier {
  TipsController(this._prefs) : _dismissed = {...?_prefs.getStringList(key)};

  static const key = 'tips_dismissed_v1';

  /// The first-run card on the home screen.
  static const getStarted = 'get_started';

  final SharedPreferences _prefs;
  final Set<String> _dismissed;

  bool isDismissed(String tip) => _dismissed.contains(tip);

  void dismiss(String tip) {
    if (!_dismissed.add(tip)) return;
    unawaited(_prefs.setStringList(key, _dismissed.toList()));
    notifyListeners();
  }
}
