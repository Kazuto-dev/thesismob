// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

class roof extends StatefulWidget {
  const roof({Key? key}) : super(key: key);

  @override
  State<roof> createState() => RoofState();
}

class RoofState extends State<roof> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  String selectedRoofWidth = 'Default';
  String selectedRoofLength = 'Default';
  String selectedCorrugation = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Roof Estimator"),
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
                'lib/assets/images/Roof(noBG).png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
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
                        value: selectedRoofWidth, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedRoofWidth = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '0.8m',
                          '0.9m',
                          '1.0m',
                          '1.2mm',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Sheet Width (m)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedRoofLength, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            selectedRoofLength = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '5FT',
                          '6FT',
                          '7FT',
                          '8FT',
                          '9FT',
                          '10FT',
                          '12FT',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Sheet Length (ft))",
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
                        value: selectedCorrugation, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedCorrugation = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '1.5 Corrugation',
                          '2.5 Corrugation',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Corrugation",
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
                      double roofSizeW = 0.0;
                      double roofSizeL = 0.0;
                      double corrugation = 0.0;
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);

                      if (selectedRoofWidth == "Default") {
                        roofSizeW = 0.0;
                      } else if (selectedRoofWidth == '0.8m') {
                        roofSizeW = 0.8;
                      } else if (selectedRoofWidth == '0.9m') {
                        roofSizeW = 0.9;
                      } else if (selectedRoofWidth == '1.0m') {
                        roofSizeW = 1.0;
                      } else if (selectedRoofWidth == '1.2m') {
                        roofSizeW = 1.2;
                      }

                      if (selectedRoofLength == 'Default') {
                        roofSizeL = 0.0;
                      } else if (selectedRoofLength == '5FT') {
                        roofSizeL = 1.524;
                      } else if (selectedRoofLength == '6FT') {
                        roofSizeL = 1.829;
                      } else if (selectedRoofLength == '7FT') {
                        roofSizeL = 2.134;
                      } else if (selectedRoofLength == '8FT') {
                        roofSizeL = 2.438;
                      } else if (selectedRoofLength == '9FT') {
                        roofSizeL = 2.743;
                      } else if (selectedRoofLength == '10FT') {
                        roofSizeL = 3.048;
                      } else if (selectedRoofLength == '12FT') {
                        roofSizeL = 3.657;
                      }

                      if (selectedCorrugation == 'Default') {
                        corrugation = 0.0;
                      } else if (selectedCorrugation == '1.5 Corrugation') {
                        corrugation = 1.524;
                      } else if (selectedCorrugation == '2.5 Corrugation') {
                        corrugation = 1.829;
                      }
                      double area = length * width;
                      print("Area: $area");

                      double effectW = roofSizeW / corrugation;
                      double sheetArea = effectW * roofSizeL;
                      double sheetsNeeded = area / sheetArea;

                      int sheetsNeededRounded;

                      if (sheetsNeeded.isFinite) {
                        sheetsNeededRounded = sheetsNeeded.ceil();
                      } else {
                        // Handle the case where sheetsNeeded is Infinity or NaN
                        sheetsNeededRounded =
                            0; // You can set a default value or handle it according to your application logic
                      }

                      print("Sheets Needed: $sheetsNeededRounded");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Roof Estimator",
                        material: "Roof",
                        area: area.toString() + "m²",
                        quantity: sheetsNeededRounded.toString() + "pcs",
                      );

                      CalculationHistory.addEntry(entry);

                      Navigator.pushNamed(
                        context,
                        '/roofOutput',
                        arguments: {
                          'area': area,
                          'sheetsNeeded': sheetsNeededRounded,
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
