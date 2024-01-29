import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await CalculationHistory.loadHistory();
    setState(() {}); // Refresh the UI after loading history
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Calculation History"),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: CalculationHistory.history.length,
        itemBuilder: (context, index) {
          CalculationHistoryEntry entry = CalculationHistory.history[index];
          return ListTile(
            title: Text(
              "Material: ${entry.material}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
                "Calculator Type: ${entry.calculatorType}\nArea: ${entry.area}\nQuantity needed: ${entry.quantity}\nTotal Cost: ${entry.totalamount}\nDate: ${entry.date}"),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirmation"),
                      content:
                          Text("Are you sure you want to delete this item?"),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Delete"),
                          onPressed: () {
                            setState(() {
                              CalculationHistory.history.removeAt(index);
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Item deleted successfully."),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
