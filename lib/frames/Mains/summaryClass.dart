import 'package:thesismob/frames/Mains/summaryHistory.dart';

class CalculationSummary {
  static List<CalculationSummaryEntry> summaries = [];

  static void addEntry(CalculationSummaryEntry summary) {
    summaries.add(summary);
  }
}
