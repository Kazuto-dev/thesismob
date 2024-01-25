// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

// ignore: camel_case_types
class wood extends StatefulWidget {
  const wood({super.key});

  @override
  State<wood> createState() => woodState();
}

class woodState extends State<wood> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  TextEditingController costController = TextEditingController();
  String selectedwoodWastage = 'Default';
  String selectedwoodSize = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plywood Estimator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/struc');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/logos/Plywood.png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Length (m)',
                          hintText: "Enter Length (m)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Width (m)",
                          hintText: "Enter Width (m)",
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
                      child: DropdownButtonFormField<String>(
                        value: selectedwoodWastage, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedwoodWastage = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '5% Wastage',
                          '10% Wastage',
                          '15% Wastage',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Wastage",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedwoodSize, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            selectedwoodSize = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '4\' x 8\'',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "PlyWood Size",
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
                      double wastagePercentage = 0.0;
                      double woodSize = 0.0;
                      double cost = double.parse(costController.text);
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);

                      if (selectedwoodWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedwoodWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedwoodWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedwoodWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedwoodSize == 'Default') {
                        woodSize = 0.0;
                      } else if (selectedwoodSize == '4\' x 8\'') {
                        woodSize = 2.97;
                      }

                      double area = length * width;
                      print("Area: $area");
                      int woodneeded = (area / woodSize).ceil();

                      int wastage;

                      if (wastagePercentage.isFinite) {
                        wastage =
                            (woodneeded * wastagePercentage).ceil().toInt();
                      } else {
                        // Handle the case where wastagePercentage is Infinity or NaN
                        wastage =
                            0; // Set a default value or handle it according to your application logic
                      }

                      int total = woodneeded + wastage;
                      print("Total plywood: $total");

                      double totalcost = total * cost;
                      print("Total Cost: $totalcost");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Plywood Estimator",
                        material: "Plywood $selectedwoodSize",
                        area: area.toString() + "m²",
                        quantity: total.toString() + "pcs",
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Plywood",
                        quantity: total.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      Navigator.pushNamed(
                        context,
                        '/outputPly',
                        arguments: {
                          'area': area,
                          'total': total,
                          'totalcost': totalcost
                        },
                      );

                      return area;
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
} // Add closi