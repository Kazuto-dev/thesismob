// ignore_for_file: prefer_const_constructors, camel_case_types, use_super_parameters, library_private_types_in_public_api, prefer_final_fields, avoid_print, sized_box_for_whitespace

import 'package:flutter/material.dart';

class paint extends StatefulWidget {
  const paint({Key? key}) : super(key: key);

  @override
  _paintState createState() => _paintState();
}

class _paintState extends State<paint> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _doorQty = TextEditingController();
  TextEditingController _windowQty = TextEditingController();
  TextEditingController _coat = TextEditingController();
  TextEditingController _paintCoverage = TextEditingController();

  String windowSize = 'Default';
  String doorSize = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paint"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/arch');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/images/Paint(noBG).png',
                width: 300,
                height: 250,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
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
                        controller: _heightController,
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
                      child: TextField(
                        controller: _doorQty,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Quantity of Doors',
                          hintText: "Enter Quantity of Doors",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _windowQty,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Quantity of Windows",
                          hintText: "Enter Quantity of Windows",
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
                        controller: _coat,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Number of Coats',
                          hintText: "Enter Number of Coats",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _paintCoverage,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Paint Coverage (sqm/L)",
                          hintText: "Enter Paint Coverage (sqm/L)",
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
                        value: windowSize, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            windowSize = newValue!;
                            print(
                                "Window Size before calculation: $windowSize");
// Update windowSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '24 x 24 = 0.38m²',
                          '24 x 48 = 0.74m²',
                          '36 x 36 = 0.83m²',
                          '24 x 60 = 0.93m²',
                          '42 x 42 = 1.14 m²',
                          '14 x 29 = 0.26m²',
                          '36 x 36 = 0.83m²',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Window Size (m)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: doorSize, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            doorSize = newValue!;
                            print("Door Size before calculation: $doorSize");
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '80 x 36 = 1.85m²',
                          '80 x 43 = 2.17m²',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Door Size (m)",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      double length = double.parse(_lengthController.text);
                      double height = double.parse(_heightController.text);
                      double door = double.parse(_doorQty.text);
                      double window = double.parse(_windowQty.text);
                      double coat = double.parse(_coat.text);
                      double paintCoverage = double.parse(_paintCoverage.text);
                      double windowSize1 = 0.0;
                      double doorSize1 = 0.0;

                      if (windowSize == 'Default') {
                        windowSize1 = 0.0;
                      } else if (windowSize == '24 x 24 = 0.38m²') {
                        windowSize1 = 0.38;
                      } else if (windowSize == '24 x 48 = 0.74m²') {
                        windowSize1 = 0.74;
                      } else if (windowSize == '36 x 36 = 0.83m²') {
                        windowSize1 = 0.83;
                      } else if (windowSize == '24 x 60 = 0.93m²') {
                        windowSize1 = 0.93;
                      } else if (windowSize == '42 x 42 = 1.14 m²') {
                        windowSize1 = 1.14;
                      } else if (windowSize == '14 x 29 = 0.26m²') {
                        windowSize1 = 0.26;
                      } else if (windowSize == '36 x 36 = 0.83m²') {
                        windowSize1 = 0.83;
                      }

                      if (doorSize == 'Default') {
                        doorSize1 = 0.0;
                      } else if (doorSize == '80 x 36 = 1.85m²') {
                        doorSize1 = 1.85;
                      } else if (doorSize == '80 x 43 = 2.17m²') {
                        doorSize1 = 2.17;
                      }

                      print("Selected Window Size: $windowSize1");
                      print("Selected Door Size: $doorSize1");

                      double area = length * height;
                      double totalLiters = area / paintCoverage;
                      double totalLitersWithCoat = totalLiters * coat;

                      double doorWin = (window * windowSize1) + (door * doorSize1);

                      double totalArea = area - doorWin;

                      // Display the result or use it as needed
                      print("Area: $area");
                      print("Total Liters: $totalLiters");
                      print("Total Liters with Coat: $totalLitersWithCoat");
                      print("Door + Window Area: $doorWin");
                      print(
                          "Total Area after deducting Door + Window Area: $totalArea");

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
