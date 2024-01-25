// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore, unused_local_variable, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

// ignore: camel_case_types
class tiles extends StatefulWidget {
  const tiles({super.key});

  @override
  State<tiles> createState() => _tilesState();
}

class _tilesState extends State<tiles> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  TextEditingController _costController = TextEditingController();

  String selectedtileWastage = 'Default';
  String selectedtileSize = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tile Estimator"),
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
                'lib/assets/images/Tiles(noBG).png',
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
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedtileWastage, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedtileWastage = newValue!;
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
                          labelText: "Tile Wastage",
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
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedtileSize, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            selectedtileSize = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '20 x 20 (0.04m)',
                          '20 x 30 (0.06m)',
                          '20 x 90 (0.17m)',
                          '30 x 30 (0.09m)',
                          '30 x 60 (0.18m)',
                          '40 x 40 (0.16m)',
                          '60 x 60 (0.36m)',
                          '60 x 120 (0.72m)',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Tile Size",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _costController,
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
                      // ... (your existing calculation code)
                      double wastagePercentage = 0.0;
                      double tileSize = 0.0;
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);
                      double cost = double.parse(_costController.text);

                      if (selectedtileWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedtileWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedtileWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedtileWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedtileSize == 'Default') {
                        tileSize = 0.0;
                      } else if (selectedtileSize == '20 x 20 (0.04m)') {
                        tileSize = 0.04;
                      } else if (selectedtileSize == '20 x 30 (0.06m)') {
                        tileSize = 0.06;
                      } else if (selectedtileSize == '20 x 90 (0.17m)') {
                        tileSize = 0.17;
                      } else if (selectedtileSize == '30 x 30 (0.09m)') {
                        tileSize = 0.09;
                      } else if (selectedtileSize == '30 x 60 (0.18m)') {
                        tileSize = 0.18;
                      } else if (selectedtileSize == '40 x 40 (0.16m)') {
                        tileSize = 0.16;
                      } else if (selectedtileSize == '60 x 60 (0.36m)') {
                        tileSize = 0.36;
                      } else if (selectedtileSize == '60 x 120 (0.72m)') {
                        tileSize = 0.72;
                      }

                      double area = length * width;
                      print("Area: $area");
                      int tileneeded = (area / tileSize).ceil();
                      int wastage =
                          (tileneeded * wastagePercentage).ceil().toInt();
                      int total = tileneeded + wastage;
                      print("Total tiles: $total");
                      double totalcost = total * cost;
                      print("Total Cost: $totalcost");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Tile Estimator",
                        material: "Tiles",
                        area: area.toString() + "m²",
                        quantity: total.toString() + "pcs",
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Tiles",
                        quantity: total.toString() + "pcs",
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      Navigator.pushNamed(
                        context,
                        '/outputTiles',
                        arguments: {
                          'area': area,
                          'total': total,
                          'totalcost': totalcost,
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
}
 // Add closing parenthesis here
