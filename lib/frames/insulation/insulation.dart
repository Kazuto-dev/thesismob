// ignore_for_file: prefer_const_constructors, camel_case_types, use_super_parameters, library_private_types_in_public_api, prefer_final_fields, avoid_print, sized_box_for_whitespace, unused_import, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class insulation extends StatefulWidget {
  @override
  State<insulation> createState() => insulationState();
}

class insulationState extends State<insulation> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _heightController = TextEditingController();

  String thickness = 'Default';
  String type = 'Default';
  String size = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Insulation Estimator"),
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
                      child: DropdownButtonFormField<String>(
                        value: thickness, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            thickness = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '2mm',
                          '3mm',
                          '5mm',
                          '10mm',
                          '12mm',
                          '15mm',
                          '20mm',
                          '25mm',
                          '35mm',
                          '40mm',
                          '50mm',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Thickness (mm)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: size, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            size = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '1(m) X 50(m)',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Size",
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
                        value: type, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            type = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          'Bare',
                          '1 side Aluminum Foil',
                          '2 sided Aluminum Foil',
                          '1 sided Aluminu & Adhesive',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Insulation Type",
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

                      double thickness1 = 0.0;
                      double size1 = 0.0;
                      String type1 = "";

                      if (thickness == 'Default') {
                        thickness1 = 0.0;
                      } else if (thickness == '2mm') {
                        thickness1 = 0.002;
                      } else if (thickness == '3mm') {
                        thickness1 = 0.003;
                      } else if (thickness == '5mm') {
                        thickness1 = 0.005;
                      } else if (thickness == '10mm') {
                        thickness1 = 0.01;
                      } else if (thickness == '12mm') {
                        thickness1 = 0.012;
                      } else if (thickness == '15mm') {
                        thickness1 = 0.015;
                      } else if (thickness == '20mm') {
                        thickness1 = 0.02;
                      } else if (thickness == '25mm') {
                        thickness1 = 0.025;
                      } else if (thickness == '35mm') {
                        thickness1 = 0.035;
                      } else if (thickness == '40mm') {
                        thickness1 = 0.04;
                      } else if (thickness == '50mm') {
                        thickness1 = 0.05;
                      }

                      if (size == 'Default') {
                        size1 = 1.0;
                      } else if (size == '1(m) X 50(m)') {
                        size1 = 50.0;
                      }

                      if (type == 'Default') {
                        type1 = "none";
                      } else if (type == 'Bare') {
                        type1 = "Bare";
                      } else if (type == '1 side Aluminum Foil') {
                        type1 = "1 side Aluminum Foil";
                      } else if (type == '2 sided Aluminum Foil') {
                        type1 = "2 sided Aluminum Foil";
                      } else if (type == '1 sided Aluminu & Adhesive') {
                        type1 = "1 sided Aluminum & Adhesive";
                      }

                      double area = length * height;
                      int insulationNeed = (area / size1).ceil();

                      print('area: $area(m2)');
                      print("thickness: $thickness1(m)");
                      print('size: $size1(m)');
                      print('type: $type1');
                      print('insulationNeed: $insulationNeed');

                      Navigator.pushNamed(context, '/insulationOutput',
                          arguments: {
                            'area': area,
                            'thickness': thickness1,
                            'size': size1,
                            'type': type1,
                            'insulationNeed': insulationNeed,
                          });

                      return area;
                    }

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
