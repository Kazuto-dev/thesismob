import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which tips, such as the "Get started" card, the user has put off with
/// "Not now", and which they asked to see again from Settings.
class TipsController extends ChangeNotifier {
  TipsController(this._prefs)
    : _snoozed = {...?_prefs.getStringList(key)},
      _pinned = {...?_prefs.getStringList(pinnedKey)};

  /// Tips put off until the next sign-in. Earlier versions put them off
  /// for good under the same key; those come back at the next sign-in too.
  static const key = 'tips_dismissed_v1';

  /// Tips reopened from Settings, shown even once their steps are done.
  static const pinnedKey = 'tips_pinned_v1';

  /// The first-run card on the home screen.
  static const getStarted = 'get_started';

  final SharedPreferences _prefs;
  final Set<String> _snoozed;
  final Set<String> _pinned;

  /// Put off with "Not now" since the user last signed in or out.
  bool isDismissed(String tip) => _snoozed.contains(tip);

  /// Reopened from Settings, so shown whatever the user has done since.
  bool isPinned(String tip) => _pinned.contains(tip);

  /// "Not now": hides [tip] until the user next signs in or out.
  void dismiss(String tip) {
    final changed = _snoozed.add(tip) | _pinned.remove(tip);
    if (!changed) return;
    _save();
    notifyListeners();
  }

  /// Brings [tip] back from Settings.
  void show(String tip) {
    final changed = _snoozed.remove(tip) | _pinned.add(tip);
    if (!changed) return;
    _save();
    notifyListeners();
  }

  /// The user signed in or out: tips they put off come back.
  void wake() {
    if (_snoozed.isEmpty) return;
    _snoozed.clear();
    _save();
    notifyListeners();
  }

  void _save() {
    unawaited(_prefs.setStringList(key, _snoozed.toList()));
    unawaited(_prefs.setStringList(pinnedKey, _pinned.toList()));
  }
}
