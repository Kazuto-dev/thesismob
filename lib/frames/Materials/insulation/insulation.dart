// ignore_for_file: prefer_const_constructors, camel_case_types, use_super_parameters, library_private_types_in_public_api, prefer_final_fields, avoid_print, sized_box_for_whitespace, unused_import, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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

class insulation extends StatefulWidget {
  @override
  State<insulation> createState() => insulationState();
}

class insulationState extends State<insulation> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _costController = TextEditingController();

  String thickness = 'Default';
  String type = 'Default';
  String size = 'Default';
  late double area = 0.0;
  late double thickness1 = 0.0;
  late double totalcost = 0.0;
  late double size1 = 0.0;
  late String type1 = "";
  late int insulation1 = 0;
  late double insulationNeed = 0.0;
  late int insulationNeedRounded = 0;
  String material = "Insulation";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;
    return Scaffold(
      appBar: AppBar(
        title: Text("Insulation Estimator"),
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
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Price per Piece",
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
                          _heightController.text.isEmpty ||
                          _costController.text.isEmpty) {
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

                      double length = double.parse(_lengthController.text);
                      double height = double.parse(_heightController.text);
                      double cost = double.parse(_costController.text);

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
                      setState(() {
                        area = length * height;
                        insulationNeed = (area / size1);
                        totalcost = cost * insulationNeed;

                        if (insulationNeed.isFinite) {
                          insulationNeedRounded = insulationNeed.ceil();
                        } else {
                          // Handle the case where sheetsNeeded is Infinity or NaN
                          insulationNeedRounded =
                              0; // You can set a default value or handle it according to your application logic
                        }

                        print('area: $area(m2)');
                        print("thickness: $thickness1(m)");
                        print('size: $size1(m)');
                        print('type: $type1');
                        print('insulationNeed: $insulationNeedRounded');
                      });

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "PE FOAM Insulation Estimator",
                        material: "Insulation $type1\n" +
                            "Thickness: $thickness1(m)\n" +
                            "Size: $size1(m)",
                        area: area.toString() + "m²",
                        quantity: insulationNeedRounded.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Insulation $type1\n" +
                            "Thickness: $thickness1(m)\n" +
                            "Size: $size1(m)",
                        quantity: insulationNeedRounded.toString() + "pcs",
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

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
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              'Quantity:',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              'Cost:',
                              style: TextStyle(
                                fontSize: 16.0,
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
                              this.area.toString() + 'm²',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              this.insulationNeedRounded.toString() + 'pcs',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 15.0),
                            child: Text(
                              '₱' + this.totalcost.toString(),
                              style: TextStyle(
                                fontSize: 16.0,
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
                width: double.infinity,
                padding: EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (area == 0 || insulationNeedRounded == 0) {
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
                            content: Text('Sheet "$sheetName" does not exist!'),
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
                        await sheet?.values.insertRow(
                            1, ['Materials', 'Area(m²)', 'Quantity']);
                        print('Header row added!');
                      } else {
                        print(
                            'Sheet is not empty. Row count: ${allValues.length}');
                      }

                      // Append the data row
                      final index = await sheet?.values
                          .appendRow([material, area, insulationNeed]);
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
                  child: isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          'Insert to Sheet',
                          style: TextStyle(
                            fontSize: 18.0,
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
