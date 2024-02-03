// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, no_logic_in_create_state, camel_case_types, avoid_print, unused_local_variable, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:gsheets/gsheets.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';
import 'package:provider/provider.dart';

const creds = r'''{
    "type": "service_account",
    "project_id": "qualified-tea-408701",
    "private_key_id": "ea91bcf89f6ba6cc3c78a57b1e80fee699a1c75a",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCphay8hAMn5lIe\nupiY1WcUF+BJkzmTRR6f/w/ZlbynuNBO32T3AR7hIZyWm72QmRz/UM4e+uA26TXC\nSVLtxHAWnyEK3FFv9WClBm6BvuQ2IuJAobHh5OR0M+LYrsnJsD2mhq/nPaDdqvNb\nR5w4IBZMbeQfTCWYa4CW343uQsvCNTi9TZ9LywPDoaRHKJQGJjjxEdBpC6R/shuB\noz6ASRs/qx0BNa5RQm5DWtpUnU5JQ6vnUQMJoy74/ZqURQNpqDMKOPOkah1Zxbbu\nA7xuH1RB2Z/XXXwFqekS3TQafBe1gBtPNupBPedlFigoCQztZcQe7nbKb2Q0SuYh\nInxlApb9AgMBAAECggEAN6iVkeGwHZIQBVnTj16FtQGv2MhXX4SSrQp0HEb/BXx3\nHGZZgoXiKx27iXGB+G9lJ2jS/DX3lt/UEEG90iYsfSjrEuNKc713aUdm0f+ocyPZ\n8EmGm3npDkQY53bf9vIAE+Rl7cD8x7sAosgswPq8B4UPIL2CHHyzYBXvRjq1JsKE\njal4Ig3ogP74C+3DFbFp9S92YK62YX69q/ZLF8FoJD+I3USWcYyrYQURPrx7S5J4\n2hG/TZPRp16zdLApRn1QYlGxtJDZc4+XaG7mHomCODK5YHrpdYwH9BCL6PvHWue6\ndxaUjYyi7oAM4Zh6mqNlzDo41A8pN/Pj0c0BOdAUuwKBgQDe7zIOmzxV2zEgTGia\nPk7onageTyCzcvgptIf1qEqknxopxb1UOechLNuKNs3aT/nK8/ZDPxzcBiaV17wt\nBJ2JsYH1l8bhH0osgzRNbsm+xxXtzMAdD6rbxWA73RVnl542w7DNzmu6w+IKzSR7\nrH9FhoKR9VYaVqAxcmrlBnxzZwKBgQDCqmvl7XQBQW58jopUpZCi2CJStoVO560+\nAD3W7rlJrWnG5j6TfnmfSju7sbDmgJ+BIqCQY3BsnuZ5o/0v/1MeFk8j/6at6Hxl\nzZJvf3LjzAYLuIgopngNqhc69ByOzt2TWSHhdc+XxObQPCz6V0Xw+XeqY7rHckfS\n+41NUpln+wKBgQCwBogs1k/+rrMMgKh7WcVukMWlIO9+IcJnE7/irX46m9HJt/O1\nZH7mSAgVCw7hWRKwOI9zK4s7A7RFznErzqAhj8JAzBXhvZYQrYyHs3mipInhGTF8\nANn069T/j6KOCD6JmVyqNFoFvxNlWfN7n4liuUGxw9i3tTyJroFO0x9C8wKBgEFC\nBF3WFnd9Sd6zoifyQOR2dDsqONJU1Dzes9xjtvW+DqHA+eVUFs2RgyjOzrDXGaGe\nzBjbXQrs0fKhSPVYMLL7Y5h70ZKnR1yRZ6+9F/TJppUzTWHjPIfIJ3V59EDjlGAb\nF0KPzgHg3kechK9/plC8MKOMP0cxRmayMZJkSE0VAoGAK8HeMxRClTn0TCfp/jJ/\nKOosMxyzwli3y957kmvj9KYY4+gFdDaWpLDdfn75atya9VwQ/vm5CVEpC8GRj1r/\nSaJDQ/xjJxOoSM14dkYRIEOUd7J9PopKrDZsKUZ/jTaMp/kuOXIJB1OhnRy2DC+l\nku78n4YGUeOxTfkqx2+Qo3s=\n-----END PRIVATE KEY-----\n",
    "client_email": "flutter-test@qualified-tea-408701.iam.gserviceaccount.com",
    "client_id": "113220498252729969715",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/flutter-test%40qualified-tea-408701.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''';

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
      backgroundColor: Color.fromARGB(255, 251, 248, 235),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 251, 248, 235),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "CHB Estimator",
            style: TextStyle(
              color: Colors.black,
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
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/struc');
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                            labelText: "Area Width (m)",
                            labelStyle: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color:
                                  Colors.black, // Modify label text color here
                            ),
                            hintText: "Enter Width (m)",
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
                            labelText: "Area Width (m)",
                            labelStyle: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color:
                                  Colors.black, // Modify label text color here
                            ),
                            hintText: "Enter Width (m)",
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
                            fillColor: Color.fromARGB(255, 221, 221,
                                221), // Modify dropdown background color here
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
                            fillColor: Color.fromARGB(255, 221, 221,
                                221), // Modify dropdown background color here
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
                              color:
                                  Colors.black, // Modify label text color here
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
                                    },
                                  ),
                                  TextButton(
                                    child: Text("Confirm"),
                                    onPressed: () {
                                      // Call the calculate function
                                      calculate();
                                      Navigator.of(context)
                                          .pop(); // Close the confirmation dialog
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
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          return 0.0;
                        }

                        // ... (your existing calculation code)
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

                        CalculationSummaryEntry summary =
                            CalculationSummaryEntry(
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
                      primary: Color.fromRGBO(204, 145, 38, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 110.0,
                        vertical: 10.0,
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
                Container(
                  margin: EdgeInsets.only(top: 50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Calculation Output',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 100.0),
                  margin: EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                'Area:',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                'Quantity:',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                'Cost:',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(right: 100.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                this.area.toString() + 'sqm',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                this.totalCHB == 1
                                    ? '1pc'
                                    : this.totalCHB.toString() + 'pcs',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(
                                '₱' + this.totalcost.toString(),
                                style: TextStyle(
                                  color: Color.fromARGB(255, 48, 48, 48),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (totalCHB == 0 || totalCHB == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Please insert data into the calculator!'),
                            duration: Duration(seconds: 5),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        final gsheets = GSheets(creds);
                        final ss =
                            await gsheets.spreadsheet('${sheetInfo?.sheetId}');
                        final sheetName = '${sheetInfo?.sheetName}';

                        // Check if the sheet exists
                        bool sheetExists = false;
                        for (var sheet in ss.sheets) {
                          if (sheet.title == sheetName) {
                            sheetExists = true;
                            break;
                          }
                        }
                        // Display an error snackbar if the sheet doesn't exist
                        if (!sheetExists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sheet "$sheetName" does not exist!'),
                              duration: Duration(seconds: 5),
                            ),
                          );

                          // Print a message to the console
                          print('Sheet "$sheetName" does not exist!');

                          return; // Stop execution if the sheet doesn't exist
                        }

                        final sheet = ss.worksheetByTitle(sheetName);

                        // Fetch all values in the sheet
                        final allValues = await sheet?.values.allRows();

                        // Check if the sheet is empty
                        if (allValues == null || allValues.isEmpty) {
                          // Add the header row at row 1
                          print('Adding header row...');
                          await sheet?.values.insertRow(1, [
                            'Materials',
                            'Area(sqm)',
                            'Quantity',
                            'Cost(₱)'
                          ]);
                          print('Header row added!');
                        } else {
                          print(
                              'Sheet is not empty. Row count: ${allValues.length}');
                        }

                        // Append the data row
                        final index = await sheet?.values
                            .appendRow([material, area, totalCHB, totalcost]);
                        print('Updated at $index');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Data added successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('Error updating data: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Data Insertion unsuccessful!'),
                            duration: Duration(seconds: 5),
                          ),
                        );
                        // Handle the error as needed
                      }

                      setState(() {
                        isLoading = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromRGBO(
                          204, 145, 38, 1), // Set background color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Add border radius
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 85.0, // Adjust horizontal padding
                        vertical: 10.0, // Adjust vertical padding if needed
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              // Customize the appearance of the loading indicator if needed
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Insert to Sheet',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
