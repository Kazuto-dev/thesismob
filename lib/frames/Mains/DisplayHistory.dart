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
    // No need to call setState here, FutureBuilder will handle it
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      CalculationHistory.history.removeAt(index);
    });

    // Save changes to storage
    CalculationHistory.saveHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 229, 240, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 229, 240, 255),
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Calculation History"),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _loadHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
              itemCount: CalculationHistory.history.length,
              itemBuilder: (context, index) {
                CalculationHistoryEntry entry =
                    CalculationHistory.history[index];
                return ListTile(
                  title: Text(
                    "Material: ${entry.material}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Calculator Type: ${entry.calculatorType}\n"
                    "Area: ${entry.area}\n"
                    "Quantity needed: ${entry.quantity}\n"
                    "Total Cost: ${entry.totalamount}\n"
                    "Date: ${entry.date}",
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirmation"),
                            content: Text(
                                "Are you sure you want to delete this item?"),
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
                                  _deleteEntry(index);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("Item deleted successfully."),
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
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
