import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    final String encoded =
        jsonEncode(history.map((entry) => entry.toJson()).toList());
    prefs.setString(_historyKey, encoded);
  }

  static Future<void> loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);

    if (historyJson != null) {
      List<dynamic> decoded = jsonDecode(historyJson);
      history = decoded
          .map((item) => CalculationHistoryEntry.fromJson(item))
          .toList();
    }
  }
}
