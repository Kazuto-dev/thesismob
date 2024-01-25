import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

class cBox extends StatefulWidget {
  const cBox({super.key});
  @override
  cBoxState createState() => cBoxState();
}

class cBoxState extends State<cBox> {
  TextEditingController costController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conjunction Box Calculator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/elec');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/logos/Logo4.png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Quantity',
                          hintText: "Enter Quantity",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Price per Piece',
                          hintText: "Enter Price (₱)",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 50.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      double cost = double.parse(costController.text);
                      double area = 0.0;
                      double quantity = double.parse(quantityController.text);

                      // Round up to the nearest whole number for the CHB needed
                      double totalcost = quantity * cost;
                      print("Area: $totalcost");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Conjunction Box Cost Calculator",
                        material: "Conjunction Box",
                        quantity: quantity.toString(),
                        area: area.toString(),
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Conjunction Box",
                        quantity: quantity.toString(),
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      // Navigate to the output page with the calculated values
                      Navigator.pushNamed(
                        context,
                        '/cbOutput',
                        arguments: {
                          'quantity': quantity,
                          'totalcost': totalcost
                        },
                      );

                      return quantity;
                    }

                    // Call the calculate function
                    calculate();
                  },
                  child: Container(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Calculate',
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
