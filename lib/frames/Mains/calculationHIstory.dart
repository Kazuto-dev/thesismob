class CalculationHistoryEntry {
  final String calculatorType;
  final String material;
  final double area;
  final int quantity;
  final DateTime date;

  CalculationHistoryEntry({
    required this.calculatorType,
    required this.material,
    required this.area,
    required this.quantity,
    required this.date,
  });
}