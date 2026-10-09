// ignore_for_file: prefer_const_constructors, camel_case_types, use_super_parameters, library_private_types_in_public_api, prefer_final_fields, avoid_print, sized_box_for_whitespace, unused_import, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thesismob/frames/Mains/calculationHIstory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:thesismob/frames/Mains/sheetExport.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';
import 'package:provider/provider.dart';


class bulb extends StatefulWidget {
  @override
  State<bulb> createState() => _bulbState();
}

class _bulbState extends State<bulb> {
  TextEditingController costController = TextEditingController();
  TextEditingController bulbQty = TextEditingController();
  late double totalcost = 0.0;
  late int bulbQuantity = 0;
  late double area = 0.0;
  String material = "Bulb";
  bool isLoading = false;

  String bulbType = 'Default';
  String watts = 'Default';
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
            "Bulb Estimator",
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
              Navigator.pushNamed(context, '/elecPages');
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
                                              this.bulbQuantity == 1
                                                  ? '1pc'
                                                  : this
                                                          .bulbQuantity
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
                          if (bulbQuantity == 0 || totalcost == 0) {
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
                          await exportRowToSheet(context, sheetInfo, [material, area, bulbQuantity, totalcost]);

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
                        controller: bulbQty,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Quantity',
                          hintText: "Enter Quantity",
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
                        value: watts, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            watts = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '3W',
                          '5W',
                          '7W',
                          '9W',
                          '11W',
                          '13W',
                          '15W',
                          '18W',
                          '20W',
                          '25W',
                          '30W',
                          '40W',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Watts",
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
                    double caculate() {
                      bulbQuantity = double.parse(bulbQty.text).toInt();
                      double cost = double.parse(costController.text);

                      setState(() {
                        material = "Bulb $bulbType + $watts";
                        area = 0.0;
                        totalcost =
                            bulbQty.text.isEmpty ? 0 : (bulbQuantity * cost);
                      });

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Bulb Estimator",
                        material: "Bulb $bulbType $watts",
                        area: area.toString() + "m²",
                        quantity: bulbQuantity.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Bulb $bulbType $watts",
                        quantity: bulbQuantity.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      return area;
                    }

                    caculate();
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
