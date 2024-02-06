class CalculationHistoryEntry {
  final String calculatorType;
  final String material;
  final String area;
  final String quantity;
  late final DateTime date;
  final String totalamount;

  CalculationHistoryEntry({
    required this.calculatorType,
    required this.material,
    required this.area,
    required this.quantity,
    required this.date,
    required this.totalamount,
  });

  get value => null;

  get key => null;

  Map<String, dynamic> toJson() {
    return {
      'calculatorType': calculatorType,
      'material': material,
      'area': area,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'totalamount': totalamount,
    };
  }

  factory CalculationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CalculationHistoryEntry(
      calculatorType: json['calculatorType'],
      material: json['material'],
      area: json['area'],
      quantity: json['quantity'],
      date: DateTime.parse(json['date']),
      totalamount: json['totalamount'],
    );
  }
}
