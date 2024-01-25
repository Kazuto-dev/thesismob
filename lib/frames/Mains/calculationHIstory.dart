class CalculationHistoryEntry {
  final String calculatorType;
  final String material;
  final String area;
  final String quantity;
  final DateTime date;
  final String totalamount;

  CalculationHistoryEntry({
    required this.calculatorType,
    required this.material,
    required this.area,
    required this.quantity,
    required this.date,
    required this.totalamount,
  });
}
