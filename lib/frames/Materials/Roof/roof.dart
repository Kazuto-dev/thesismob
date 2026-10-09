// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thesismob/frames/Mains/calculationHIstory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:thesismob/frames/Mains/sheetExport.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:provider/provider.dart';


class roof extends StatefulWidget {
  const roof({Key? key}) : super(key: key);

  @override
  State<roof> createState() => RoofState();
}

class RoofState extends State<roof> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  TextEditingController costController = TextEditingController();
  String selectedRoofWidth = 'Default';
  String selectedRoofLength = 'Default';
  String selectedCorrugation = 'Default';
  String roofType = 'Default';
  late double area = 0.0;
  late double sheetsNeeded = 0;
  late int sheetsNeededRounded = 0;
  late double totalcost = 0.0;
  String material = "Roof";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 255, 189, 32),
                Color.fromARGB(255, 221, 115, 2),
              ],
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "Roof Estimator",
            style: TextStyle(
              color: const Color.fromARGB(255, 241, 240, 240),
              fontSize: 22,
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/archPages');
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(30.0), // Set your preferred height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Add more widgets if needed
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 228, 228, 228),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Center(
                              child: Text(
                                'Calculation Output',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 70.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Container(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            'Area:',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 48, 48, 48),
                                              fontSize: 18,
                                              fontFamily: GoogleFonts.poppins()
                                                  .fontFamily,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            'Quantity:',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 48, 48, 48),
                                              fontSize: 18,
                                              fontFamily: GoogleFonts.poppins()
                                                  .fontFamily,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            'Cost:',
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 48, 48, 48),
                                              fontSize: 18,
                                              fontFamily: GoogleFonts.poppins()
                                                  .fontFamily,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      padding: EdgeInsets.only(right: 70.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(top: 15.0),
                                            child: Text(
                                              this.area.toString() + 'sqm',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 48, 48, 48),
                                                fontSize: 18,
                                                fontFamily:
                                                    GoogleFonts.poppins()
                                                        .fontFamily,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 15.0),
                                            child: Text(
                                              this.sheetsNeededRounded == 1
                                                  ? '1pc'
                                                  : this
                                                          .sheetsNeededRounded
                                                          .toString() +
                                                      'pcs',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 48, 48, 48),
                                                fontSize: 18,
                                                fontFamily:
                                                    GoogleFonts.poppins()
                                                        .fontFamily,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 15.0),
                                            child: Text(
                                              'PHP' + this.totalcost.toString(),
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 48, 48, 48),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0, top: 5.0),
                      child: GestureDetector(
                        onTap: () async {
                          if (sheetsNeededRounded == 0 || totalcost == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please insert data into the calculator!'),
                                duration: Duration(seconds: 5),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });
                          await exportRowToSheet(context, sheetInfo, [material, area, sheetsNeededRounded, totalcost]);

                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: Image.asset(
                          'lib/assets/logos/Sheet.png',
                          width: 70.0,
                          height: 70.0,
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
                        value: roofType, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            roofType = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          'Ribbed Roof',
                          'Corrugated Roof',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Roof Type",
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
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Area Length (m)',
                          hintText: "Enter Area Length (m)",
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
                          labelText: "Area Width (m)",
                          hintText: "Enter Area Width (m)",
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
                          "1.524m",
                          "1.829m",
                          "2.134m",
                          "2.438m",
                          "2.743m",
                          "3.048m",
                          "3.658m",
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
              Visibility(
                visible: roofType == 'Corrugated Roof',
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCorrugation, // Use windowSize here
                          onChanged: (String? newValue) {
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
                margin: EdgeInsets.only(top: 5.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      // Check if any input is missing
                      if (_lengthController.text.isEmpty ||
                          _widthController.text.isEmpty ||
                          costController.text.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Missing Input"),
                              content: Text(
                                  "Please fill in all the required fields."),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return 0.0;
                      }
                      double roofSizeW = 0.0;
                      double roofSizeL = 0.0;
                      double corrugation = 0.0;
                      double cost = double.parse(costController.text);
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);

                      if (roofType == 'Default') {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Select Roof Type"),
                              content: Text("Please select type of roof."),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }

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
                      } else if (selectedRoofLength == '1.524m') {
                        roofSizeL = 1.524;
                      } else if (selectedRoofLength == '1.829m') {
                        roofSizeL = 1.829;
                      } else if (selectedRoofLength == '2.134m') {
                        roofSizeL = 2.134;
                      } else if (selectedRoofLength == '2.438m') {
                        roofSizeL = 2.438;
                      } else if (selectedRoofLength == '2.743m') {
                        roofSizeL = 2.743;
                      } else if (selectedRoofLength == '3.048m') {
                        roofSizeL = 3.048;
                      } else if (selectedRoofLength == '3.657m') {
                        roofSizeL = 3.657;
                      }

                      if (selectedCorrugation == 'Default') {
                        corrugation = 0.0;
                      } else if (selectedCorrugation == '1.5 Corrugation') {
                        corrugation = 1.524;
                      } else if (selectedCorrugation == '2.5 Corrugation') {
                        corrugation = 1.829;
                      }

                      if (roofType == 'Ribbed Roof') {
                        setState(() {
                          area = length * width;
                          sheetsNeeded = area / (roofSizeW * roofSizeL);
                          sheetsNeededRounded = sheetsNeeded.ceil();
                          totalcost = sheetsNeededRounded * cost;
                          print("Area: $area");
                          print("Sheets Needed: $sheetsNeeded");
                          print("Total Cost: $totalcost");
                        });
                      } else if (roofType == 'Corrugated Roof') {
                        setState(() {
                          area = length * width;
                          print("Area: $area");

                          double effectW = roofSizeW / corrugation;
                          double sheetArea = effectW * roofSizeL;
                          sheetsNeeded = area / sheetArea;

                          print("EffectW: $effectW");
                          print("Sheet Area: $sheetArea");
                          print("Sheets Needed: $sheetsNeeded");

                          if (sheetsNeeded.isFinite) {
                            sheetsNeededRounded = sheetsNeeded.ceil();
                          } else {
                            sheetsNeededRounded = 0;
                          }

                          totalcost = sheetsNeededRounded * cost;

                          print("Total Cost: $totalcost");
                        });
                      }

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Roof Estimator",
                        material: "Roof",
                        area: area.toString() + "m²",
                        quantity: sheetsNeededRounded.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Roof",
                        quantity: sheetsNeededRounded.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      return area;
                    }

                    // Call the calculate function
                    calculate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(249, 155, 7, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 100.0,
                      vertical: 15.0,
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(
                            // Customize the appearance of the loading indicator if needed
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            'Calculate',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontSize: 20,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ),
              // Rest of your original code for the calculator
            ],
          ),
        ),
      ),
    );
  }
}
