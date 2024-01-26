import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalculationSummary {
  static List<CalculationSummaryEntry> summaries = [];
  static const String _summaryKey = 'calculation_summary';

  static void addEntry(CalculationSummaryEntry summary) {
    summaries.add(summary);
    saveSummary();
  }

  static void saveSummary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
        summaries.map((summaryReport) => summaryReport.toJson()).toList());
    prefs.setString(_summaryKey, encoded);
  }

  static Future<void> loadSummary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? summaryJson = prefs.getString(_summaryKey);

    if (summaryJson != null) {
      List<dynamic> decoded = jsonDecode(summaryJson);
      summaries = decoded
          .map((item) => CalculationSummaryEntry.fromJson(item))
          .toList();
    }
  }
}
 