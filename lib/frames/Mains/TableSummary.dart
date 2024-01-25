import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

class Summary extends StatefulWidget {
  @override
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  double totalCost = 0.0; // Variable to store the running total

  @override
  void initState() {
    super.initState();

    // Calculate the initial totalCost when the widget is built
    totalCost = CalculationSummary.summaries.map((summaryReport) {
      // Extract the numeric part of the totalamount and remove non-numeric characters
      String amount =
          summaryReport.totalamount.replaceAll(RegExp(r'[^\d.]'), '');

      // Attempt to parse the cleaned numeric string as a double; use 0.0 if parsing fails
      return double.tryParse(amount) ?? 0.0;
    }).fold(0.0, (previous, current) => previous + current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Calculation Summary"),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: DataTable(
          columns: <DataColumn>[
            DataColumn(
              label: Text(
                'Material',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true, // Make the "Quantity" column narrower
            ),
            DataColumn(
              label: Text(
                'Costs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true, // Make the "Costs" column narrower
            ),
            DataColumn(
              label: Text('Delete',
                  style:
                      TextStyle(fontSize: 12)), // Empty column for delete icon
            ),
          ],
          rows: CalculationSummary.summaries.map((summaryReport) {
            return DataRow(
              cells: <DataCell>[
                DataCell(
                  Text(
                    summaryReport.materialName,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    summaryReport.quantity,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    summaryReport.totalamount,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete, size: 18),
                    onPressed: () {
                      setState(() {
                        CalculationSummary.summaries.remove(summaryReport);

                        // Subtract the deleted item's cost from the total
                        totalCost -= double.parse(
                            summaryReport.totalamount.replaceAll('₱', ''));

                        // Ensure totalCost is not negative
                        totalCost = totalCost.clamp(0.0, double.infinity);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.blueGrey,
        child: Text(
          'Total Cost: ₱${totalCost.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
