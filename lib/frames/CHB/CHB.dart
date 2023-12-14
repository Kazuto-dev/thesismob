// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore, no_logic_in_create_state, camel_case_types, avoid_print, unused_local_variable, sized_box_for_whitespace

import 'package:flutter/material.dart';

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
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lengthController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Length in meters',
                          hintText: "Enter length in meters",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Width in meters',
                          hintText: "Enter width in meters",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wastage:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedWastage,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedWastage = newValue!;
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'Default',
                                  child: Text('Default'),
                                ),
                                ...[
                                  '5% Wastage',
                                  '10% Wastage',
                                  '15% Wastage'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHB Size: ',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSize,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedSize = newValue!;
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'Default',
                                  child: Text('Default'),
                                ),
                                ...[
                                  '.40m x .20m',
                                  '.30m x .20m'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
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

                      if (selectedWastage == '5% Wastage') {
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

                      // Calculate wastage and round up to the nearest whole number
                      int wastage =
                          (wastagePercentage * chbNeed).ceil().toInt();
                      print("Wastage: $wastage");

                      int totalCHB = chbNeed + wastage;

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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: "Calculator",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/solution');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/definition');
          }
        },
      ),
    );
  }
}
