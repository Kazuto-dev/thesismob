// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

// ignore: camel_case_types
class MySwitch extends StatefulWidget {
  const MySwitch({super.key});

  @override
  State<MySwitch> createState() => MySwitchState();
}

class MySwitchState extends State<MySwitch> {
  TextEditingController costController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Switch Calculator"),
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
                      double quantity = double.parse(quantityController.text);

                      double area = 0.0;

                      // Round up to the nearest whole number for the CHB needed
                      double totalcost = quantity * cost;
                      print("Total Cost: $totalcost");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Switch Cost Calculator",
                        material: "Switch",
                        quantity: quantity.toString(),
                        area: area.toString(),
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Switch",
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
