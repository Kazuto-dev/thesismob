// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore, unused_local_variable, prefer_final_fields

import 'package:flutter/material.dart';

// ignore: camel_case_types
class tiles extends StatefulWidget {
  const tiles({super.key});

  @override
  State<tiles> createState() => _tilesState();
}

class _tilesState extends State<tiles> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
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
            Navigator.of(context).pop();
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
                              value: selectedtileWastage,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedtileWastage = newValue!;
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'Default',
                                  child: Text('Default'),
                                ),
                                ...['5% Wastage', '10% Wastage', '15% Wastage']
                                    .map<DropdownMenuItem<String>>(
                                      (String value) =>
                                          DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
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
                          'Tile Size: ',
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
                              value: selectedtileSize,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedtileSize = newValue!;
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'Default',
                                  child: Text('Default'),
                                ),
                                ...[
                                  '5.08cm x 5.08cm',
                                  '10.16cm x 10.16cm',
                                  '15.24cm x 15.24cm',
                                  '20.32cm x 20.32cm',
                                  '30.48cm x 30.48cm',
                                  '40.64cm x 40.64cm',
                                  '45.72cm x 45.72cm',
                                  '60.96cm x 60.96cm'
                                ]
                                    .map<DropdownMenuItem<String>>(
                                      (String value) =>
                                          DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
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
                      double tileSize = 0.0;
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);

                      if (selectedtileWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedtileWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedtileWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedtileWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedtileSize == '5.08cm x 5.08cm') {
                        tileSize = 0.0508;
                      } else if (selectedtileSize == '10.16cm x 10.16cm') {
                        tileSize = 0.1016;
                      } else if (selectedtileSize == '15.24cm x 15.24cm') {
                        tileSize = 0.1524;
                      } else if (selectedtileSize == '20.32cm x 20.32cm') {
                        tileSize = 0.2032;
                      } else if (selectedtileSize == '30.48cm x 30.48cm') {
                        tileSize = 0.3048;
                      } else if (selectedtileSize == '40.64cm x 40.64cm') {
                        tileSize = 0.4064;
                      } else if (selectedtileSize == '45.72cm x 45.72cm') {
                        tileSize = 0.4572;
                      } else if (selectedtileSize == '60.96cm x 60.96cm') {
                        tileSize = 0.6096;
                      }

                      double area = length * width;
                      print("Area: $area");
                      int tileneeded = (area / tileSize).ceil();
                      int wastage =
                          (tileneeded * wastagePercentage).ceil().toInt();
                      int total = tileneeded + wastage;
                      print("Total tiles: $total");

                      Navigator.pushNamed(
                        context,
                        '/outputTiles',
                        arguments: {
                          'area': area,
                          'total': total,
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

      // ignore: prefer_const_constructors
      bottomNavigationBar: BottomNavigationBar(
        items: [
          //home
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: "Calculator",
            backgroundColor: Colors.blue,
          ),
          //profile
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          //settings
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          // Handle the tap for each item
          if (index == 1) {
            Navigator.pushNamed(context, '/solutiontiles');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/definitiontiles');
          }
        },
      ),
    );
  }
} // Add closing parenthesis here