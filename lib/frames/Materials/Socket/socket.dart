// ignore_for_file: prefer_const_constructors

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

// ignore: camel_case_types
class MySocket extends StatefulWidget {
  const MySocket({super.key});

  @override
  State<MySocket> createState() => MySocketState();
}

class MySocketState extends State<MySocket> {
  TextEditingController costController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  String selectedType = "Default";
  late double totalquantity = 0.0;
  late double totalcost = 0.0;
  String material = "Socket";
  bool isLoading = false;

  List<Map<String, dynamic>> calculationHistory = [];
  List<Map<String, dynamic>> calculationSummary = [];

  @override
  Widget build(BuildContext context) {
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;
    return Scaffold(
      appBar: AppBar(
        title: Text("Socket Calculator"),
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
                      child: DropdownButtonFormField<String>(
                        value: selectedType, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedType = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '1 Gang',
                          '2 Gang',
                          '3 Gang',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Switch Type",
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
                      double quantity = double.parse(quantityController.text);

                      double area = 0.0;
                      setState(() {
                        // Round up to the nearest whole number for the CHB needed
                        totalcost = quantity * cost;
                        print("Total Cost: $totalcost");
                        totalquantity = quantity;
                        print("Quantity: $totalquantity");
                      });

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                        date: DateTime.now(),
                        calculatorType: "Socket Cost Calculator",
                        material: "Socket - " + selectedType,
                        quantity: totalquantity.toString(),
                        area: area.toString(),
                        totalamount: "₱" + totalcost.toString(),
                      );

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Socket - " + selectedType,
                        quantity: totalquantity.toString(),
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
                              this.totalquantity == 1
                                  ? '1pc'
                                  : this.totalquantity.toString() + 'pcs',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                          ), // pc pcs
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
                    if (totalquantity == 0 || totalcost == 0) {
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
                            1, ['Materials', 'Area(sqm)', 'Quantity']);
                        print('Header row added!');
                      } else {
                        print(
                            'Sheet is not empty. Row count: ${allValues.length}');
                      }

                      // Append the data row
                      final index = await sheet?.values
                          .appendRow([material, totalquantity]);
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
