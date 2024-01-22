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
                "Calculator Type: ${entry.calculatorType}\nArea: ${entry.area}\nQuantity needed: ${entry.quantity}\nDate: ${entry.date}"),
            trailing: IconButton(
              icon: Icon(Icons
                  .delete), // You can replace 'Icons.info' with your desired icon
              onPressed: () {
                setState(() {
                  CalculationHistory.history.removeAt(index);
                });
              },
            ),
          );
        },
      ),
    );
  }
}
