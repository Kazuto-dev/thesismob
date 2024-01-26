class CalculationSummaryEntry {
  final String materialName;
  final String quantity;
  final String totalamount;

  CalculationSummaryEntry({
    required this.materialName,
    required this.quantity,
    required this.totalamount, 
  });

  Map<String, dynamic> toJson() {
    return {
      'materialName': materialName,
      'quantity': quantity,
      'totalamount': totalamount,
    };
  }

  factory CalculationSummaryEntry.fromJson(Map<String, dynamic> json) {
    return CalculationSummaryEntry(
      materialName: json['materialName'],
      quantity: json['quantity'],
      totalamount: json['totalamount'],
    );
  }
}
