// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, no_logic_in_create_state, camel_case_types, avoid_print, unused_local_variable, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/history.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CHB extends StatefulWidget {
  const CHB({Key? key}) : super(key: key);

  @override
  State<CHB> createState() => _CHBState();
}

class _CHBState extends State<CHB> {
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  String selectedWastage = 'Default';
  String selectedSize = 'Default';

  List<Map<String, dynamic>> calculationHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CHB Estimator"),
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
                        controller: lengthController,
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
                        controller: widthController,
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
                        value: selectedWastage, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedWastage = newValue!;
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
                          labelText: "CHB Wastage",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSize, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            selectedSize = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '.40m x .20m',
                          '.30m x .20m',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "CHB Size",
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
                      double chbSize = 0.0;
                      double length = double.parse(lengthController.text);
                      double width = double.parse(widthController.text);

                      if (selectedWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedSize == '.40m x .20m') {
                        chbSize = 0.08;
                      } else if (selectedSize == '.30m x .20m') {
                        chbSize = 0.06;
                      }

                      double area = length * width;
                      print("Area: $area");

                      // Round up to the nearest whole number for the CHB needed
                      int chbNeed = (area / chbSize).ceil();
                      print("CHB Needed: $chbNeed");

                      List<String> numbers = ["1", "2", "3", "4", "5"];

                      // Calculate wastage and round up to the nearest whole number
                      int wastage =
                          (wastagePercentage * chbNeed).ceil().toInt();
                      print("Wastage: $wastage");

                      int totalCHB = chbNeed + wastage;

                      Calculation calculation = Calculation(
                        calculatorType: "Concrete Hollow Blocks" + numbers[2],
                        area: area,
                        totalCHB: totalCHB,
                        date: DateTime.now(),
                      );

                      HistoryManager().addCalculation(calculation);

                      // Navigate to the output page with the calculated values
                      Navigator.pushNamed(
                        context,
                        '/CHBoutput',
                        arguments: {'area': area, 'totalCHB': totalCHB},
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

class Calculation {
  String calculatorType;
  double area;
  int totalCHB;
  DateTime date;

  Calculation({
    required this.calculatorType,
    required this.area,
    required this.totalCHB,
    required this.date,
  });
}
