// ignore_for_file: prefer_const_constructors, camel_case_types, use_super_parameters, library_private_types_in_public_api, prefer_final_fields, avoid_print, sized_box_for_whitespace, unused_import, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

class bulb extends StatefulWidget {
  @override
  State<bulb> createState() => _bulbState();
}

class _bulbState extends State<bulb> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController bulbQty = TextEditingController();

  String bulbType = 'Default';
  String roomType = 'Default';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bulb Estimator"),
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
                'lib/assets/images/Bulb(noBG).png',
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
                        controller: bulbQty,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Quantity of Bulbs',
                          hintText: "Enter Quantity of Bulbs",
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
                        value: bulbType, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            bulbType = newValue!;
                            print("BULB Type before calculation: $bulbType");
                          });
                        },
                        items: <String>[
                          'Default',
                          'Incandecent',
                          'Halogen',
                          'CFL',
                          'LED',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Bulb Type",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: roomType, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            roomType = newValue!;
                            print("Room type before calculation: $roomType");
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          'Toilet',
                          'Kitchen',
                          'Dining',
                          'Living',
                          'Garage',
                          'Bedroom',
                          'Storage',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Room Type",
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
                    double caculate() {
                      double length = double.parse(_lengthController.text);
                      double height = double.parse(_heightController.text);
                      int bulbQuantity = double.parse(bulbQty.text).toInt();

                      double roomType1 = 0.0;
                      double bulbType1 = 0.0;

                      if (bulbType == 'Default') {
                        bulbType1 = 0.0;
                      } else if (bulbType == 'Incandecent') {
                        bulbType1 = 15.0;
                      } else if (bulbType == 'Halogen') {
                        bulbType1 = 25.0;
                      } else if (bulbType == 'CFL') {
                        bulbType1 = 60.0;
                      } else if (bulbType == 'LED') {
                        bulbType1 = 75.0;
                      }

                      if (roomType == 'Default') {
                        roomType1 = 0.0;
                      } else if (roomType == 'Toilet') {
                        roomType1 = 400.0;
                      } else if (roomType == 'Kitchen') {
                        roomType1 = 350.0;
                      } else if (roomType == 'Dining') {
                        roomType1 = 300.0;
                      } else if (roomType == 'Living') {
                        roomType1 = 250.0;
                      } else if (roomType == 'Garage') {
                        roomType1 = 200.0;
                      } else if (roomType == 'Bedroom') {
                        roomType1 = 150.0;
                      } else if (roomType == 'Storage') {
                        roomType1 = 100.0;
                      }

                      double area = (length * height);
                      double totalLumens = (area * roomType1);
                      int watts = (totalLumens / bulbType1).ceil();
                      int wperbulb = (watts / bulbQuantity).ceil();

                      String bulb1 =
                          "Bulb Quantity: $bulbQuantity $wperbulb W per bulb";

                      print("Bulb Type: $bulbType");
                      print("Room Type: $roomType");
                      print("Area: $area");
                      print("Total Lumens: $totalLumens");
                      print("Watts: $watts");
                      print("Watts per bulb: $wperbulb");
                      print("Bulb Quantity: $bulbQuantity");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Bulb Estimator",
                        material: "Bulb + $bulbType" + wperbulb.toString(),
                        area: area,
                        quantity: bulbQuantity,
                      );

                      CalculationHistory.addEntry(entry);

                      Navigator.pushNamed(context, '/bulbOutput', arguments: {
                        'area': area,
                        'bulb': bulb1,
                      });

                      return area;
                    }

                    caculate();
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
