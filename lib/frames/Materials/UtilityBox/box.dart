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


class box extends StatefulWidget {
  const box({Key? key}) : super(key: key);

  @override
  State<box> createState() => _carpetState();
}

class _carpetState extends State<box> {
  TextEditingController costController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  late double quantity = 0.0;
  late double totalcost = 0.0;
  late double totalquantity = 0.0;
  String material = "utility Box";
  bool isLoading = false;
  late double area = 0.0;
  @override
  Widget build(BuildContext context) {
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 251, 248, 235),
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
            "Utility Box Estimator",
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 228, 228, 228),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.all(20.0),
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
                          margin: EdgeInsets.only(top: 0),
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
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
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
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
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
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
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
                                padding: const EdgeInsets.only(
                                    bottom: 10.0, right: 0),
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
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
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
                                          this.totalquantity == 1
                                              ? '1pc'
                                              : this.totalquantity.toString() +
                                                  'pcs',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
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
                                          'PHP' + this.totalcost.toString(),
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 48, 48, 48),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
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
                    padding: const EdgeInsets.only(right: 30.0, top: 50.0),
                    child: GestureDetector(
                      onTap: () async {
                        if (totalquantity == 0 || totalcost == 0) {
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
                        await exportRowToSheet(context, sheetInfo, [material, area, totalquantity, totalcost]);

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
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
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
                margin: EdgeInsets.only(top: 50.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      if (quantityController.text.isEmpty ||
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
                      double cost = double.parse(costController.text);
                      double area = 0.0;
                      double quantity = double.parse(quantityController.text);

                      // Round up to the nearest whole number for the CHB needed
                      setState(() {
                        // Round up to the nearest whole number for the CHB needed
                        totalcost = quantity * cost;
                        print("Total Cost: $totalcost");
                        totalquantity = quantity;
                        print("Quantity: $totalquantity");
                      });

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Utility Box Cost Calculator",
                        material: "utility Box",
                        quantity: quantity.toString(),
                        area: area.toString(),
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "utility Box",
                        quantity: quantity.toString(),
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      // Navigate to the output page with the calculated values

                      return quantity;
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
