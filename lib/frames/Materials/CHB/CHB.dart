// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, no_logic_in_create_state, camel_case_types, avoid_print, unused_local_variable, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:thesismob/frames/Mains/calculationHIstory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:thesismob/frames/Mains/sheetExport.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';
import 'package:provider/provider.dart';


class CHB extends StatefulWidget {
  const CHB({Key? key}) : super(key: key);

  @override
  State<CHB> createState() => _CHBState();
}

class _CHBState extends State<CHB> {
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController costController = TextEditingController();
  String selectedWastage = 'Default';
  String selectedSize = 'Default';
  late double totalcost = 0.0;
  late int totalCHB = 0;
  late double area = 0.0;
  String material = "CHB";
  bool isLoading = false;
  int tapCount = 0;

  List<Map<String, dynamic>> calculationHistory = [];
  List<Map<String, dynamic>> calculationSummary = [];

  @override
  Widget build(BuildContext context) {
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;
    // Retrieve arguments passed by Navigator

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
            "CHB Estimator",
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
              Navigator.pushNamed(context, '/strucPages');
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
                                              this.totalCHB == 1
                                                  ? '1pc'
                                                  : this.totalCHB.toString() +
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
                          if (totalCHB == 0 || totalcost == 0) {
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
                          await exportRowToSheet(context, sheetInfo, [material, area, totalCHB, totalcost]);

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
                      child: TextField(
                        controller: lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          labelText: "Area Length (m)",
                          labelStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.black, // Modify label text color here
                          ),
                          hintText: "Enter Length (m)",
                          hintStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.grey, // Modify hint text color here
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          labelText: "Area Height (m)",
                          labelStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.black, // Modify label text color here
                          ),
                          hintText: "Enter Height (m)",
                          hintStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.grey, // Modify hint text color here
                          ),
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
                          '5%Contingency',
                          '10%Contingency',
                          '15%Contingency',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                color: Color.fromARGB(255, 41, 41,
                                    41), // Modify label text color here
                              ),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 255, 255,
                                  255), // Modify dropdown border color here
                            ),
                          ),
                          labelText: "CHB Contingency",
                          labelStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Color.fromARGB(255, 41, 41,
                                41), // Modify label text color here
                          ),
                          fillColor: Color.fromARGB(255, 251, 248,
                              235), // Modify dropdown background color here
                          filled: true,
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
                          '4"',
                          '5"',
                          '6"',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                color: Color.fromARGB(255, 41, 41,
                                    41), // Modify label text color here
                              ),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 255, 255,
                                  255), // Modify dropdown border color here
                            ),
                          ),
                          labelText: "CHB Size",
                          labelStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Color.fromARGB(255, 41, 41,
                                41), // Modify label text color here
                          ),
                          fillColor: Color.fromARGB(255, 251, 248,
                              235), // Modify dropdown background color here
                          filled: true,
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
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(223, 175, 70, 1),
                            ),
                          ),
                          labelText: "Price per piece",
                          labelStyle: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            color: Colors.black, // Modify label text color here
                          ),
                          hintText: "Enter Price (₱)",
                          hintStyle: TextStyle(
                            color: Colors.grey, // Modify hint text color here
                          ),
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
                    Future<double> calculate() async {
                      setState(() {
                        isLoading = true;
                      });

                      // Perform the asynchronous calculation
                      await Future.delayed(Duration(seconds: 1));

                      tapCount++;
                      if (tapCount > 2) {
                        // Reset tapCount to 0 after the second tap
                        tapCount = 0;

                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Confirmation"),
                              content: Text(
                                  "Are you sure you want to add this entry?"),
                              actions: [
                                TextButton(
                                  child: Text("Cancel"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      isLoading = false;
                                    });
                                  },
                                ),
                                TextButton(
                                  child: Text("Confirm"),
                                  onPressed: () {
                                    // Call the calculate function
                                    calculate();
                                    Navigator.of(context).pop();
                                    setState(() {
                                      isLoading = false;
                                    }); // Close the confirmation dialog
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }

                      // Replace this with your actual calculation logic

                      // Check if any input is missing
                      if (lengthController.text.isEmpty ||
                          widthController.text.isEmpty ||
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
                                    setState(() {
                                      isLoading = false;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return 0.0;
                      }

                      double wastagePercentage = 0.0;
                      double chbSize = 0.08;
                      double length = double.parse(lengthController.text);
                      double width = double.parse(widthController.text);
                      double cost = double.parse(costController.text);

                      if (selectedWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedWastage == '5% Contingency') {
                        wastagePercentage = 0.05;
                      } else if (selectedWastage == '10% Contingency') {
                        wastagePercentage = 0.1;
                      } else if (selectedWastage == '15% Contingency') {
                        wastagePercentage = 0.15;
                      }

                      setState(() {
                        area = length * width;
                        print("Area: $area");

                        // Round up to the nearest whole number for the CHB needed
                        int chbNeed = (area / chbSize).ceil();
                        print("CHB Needed: $chbNeed");

                        // Calculate wastage and round up to the nearest whole number
                        int wastage =
                            (wastagePercentage * chbNeed).ceil().toInt();
                        print("Wastage: $wastage");

                        totalCHB = chbNeed + wastage;

                        totalcost = totalCHB * cost;
                        print("Total Cost: $totalcost");
                      });

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "CHB Estimator",
                        material: "Concrete Hollow Blocks",
                        area: area.toString() + "sqm",
                        quantity: totalCHB.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "CHB " + selectedSize,
                        quantity: totalCHB.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      setState(() {
                        isLoading = false;
                      });

                      return area;
                    }

                    // Call the calculate function
                    calculate();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromRGBO(249, 155, 7, 1),
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
