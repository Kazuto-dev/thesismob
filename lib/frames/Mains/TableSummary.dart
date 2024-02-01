import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

class Summary extends StatefulWidget {
  @override
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  double totalCost = 0.0;
  bool _isLoading = true; // Variable to store the running total

  @override
  void initState() {
    super.initState();
    loadSummary();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> loadSummary() async {
    await CalculationSummary.loadSummary();
    _updateTotalCost();
    setState(() {});
    // Refresh the UI after loading history
  }

  void _updateTotalCost() {
    totalCost = CalculationSummary.summaries.map((summaryReport) {
      String amount =
          summaryReport.totalamount.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(amount) ?? 0.0;
    }).fold(0.0, (previous, current) => previous + current);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            backgroundColor: Color.fromARGB(255, 229, 240, 255),
            body: Center(
              child: Image.asset(
                'lib/assets/logos/SLogo.png',
                height: 100,
                width: 100,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Color.fromARGB(255, 229, 240, 255),
            appBar: AppBar(
              backgroundColor: Color.fromARGB(255, 229, 240, 255),
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Calculation Summary"),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Enable vertical scrolling
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Enable horizontal scrolling
                child: Center(
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => const Color.fromARGB(255, 53, 53, 53)),
                    columns: <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Material',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Quantity',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white),
                        ),
                        numeric: true, // Make the "Quantity" column narrower
                      ),
                      DataColumn(
                        label: Text(
                          'Costs',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white),
                        ),
                        numeric: true, // Make the "Costs" column narrower
                      ),
                      DataColumn(
                        label: Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors
                                  .white), // Smaller font size for delete column
                        ),
                      ),
                    ],
                    rows: CalculationSummary.summaries
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final summaryReport = entry.value;
                      final isEven = index % 2 == 0;
                      final rowColor = isEven
                          ? Color.fromARGB(255, 198, 210, 250)
                          : Color.fromARGB(255, 200, 200, 200);
                      final textStyle = TextStyle(
                          fontSize: 10,
                          color: isEven
                              ? Color.fromARGB(255, 29, 29, 29)
                              : Color.fromARGB(255, 29, 29, 29));

                      return DataRow(
                        color: MaterialStateColor.resolveWith(
                            (states) => rowColor),
                        cells: <DataCell>[
                          DataCell(
                            Text(
                              summaryReport.materialName,
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(
                              summaryReport.quantity,
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            Text(
                              summaryReport.totalamount,
                              style: textStyle,
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.delete, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Confirmation'),
                                      content: Text(
                                          'Are you sure you want to delete this item?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Delete'),
                                          onPressed: () {
                                            setState(() {
                                              CalculationSummary.summaries
                                                  .remove(summaryReport);

                                              // Subtract the deleted item's cost from the total
                                              totalCost -= double.parse(
                                                  summaryReport.totalamount
                                                      .replaceAll('₱', ''));

                                              // Ensure totalCost is not negative
                                              totalCost = totalCost.clamp(
                                                  0.0, double.infinity);

                                              CalculationSummary.saveSummary();
                                            });
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.blueGrey,
              child: Text(
                'Total Cost: ₱${totalCost.toStringAsFixed(2).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
  }
}
