import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:thesismob/frames/Mains/calculationHIstory.dart';

class CalculationHistory {
  static List<CalculationHistoryEntry> history = [];
  static const String _historyKey = 'calculation_history';

  static void addEntry(CalculationHistoryEntry entry) {
    history.add(entry);
    saveHistory();
  }

  static List<CalculationHistoryEntry> getHistoryForCalculatorType(
      String calculatorType) {
    return history
        .where((entry) => entry.calculatorType == calculatorType)
        .toList();
  }

  static void saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = encodeHistory();
    prefs.setString(_historyKey, encoded);
  }

  static String encodeHistory() {
    return jsonEncode(history.map((entry) => entry.toJson()).toList());
  }

  static Future<void> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);

    if (historyJson != null) {
      decodeHistory(historyJson);
    }
  }

  static void decodeHistory(String historyJson) {
    List<dynamic> decoded = jsonDecode(historyJson);
    history =
        decoded.map((item) => CalculationHistoryEntry.fromJson(item)).toList();
  }

  static void deleteOldEntries() {
    DateTime currentDate = DateTime.now();
    history
        .removeWhere((entry) => currentDate.difference(entry.date).inDays > 5);
    saveHistory();
  }
}
