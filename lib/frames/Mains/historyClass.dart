import 'package:thesismob/frames/Mains/calculationHistory.dart';

class CalculationHistory {
  static List<CalculationHistoryEntry> history = [];

  static void addEntry(CalculationHistoryEntry entry) {
    history.add(entry);
  }

  static List<CalculationHistoryEntry> getHistoryForCalculatorType(
      String calculatorType) {
    return history
        .where((entry) => entry.calculatorType == calculatorType)
        .toList();
  }
}
