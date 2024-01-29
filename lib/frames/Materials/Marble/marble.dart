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

class marble extends StatefulWidget {
  const marble({super.key});
  @override
  marbleState createState() => marbleState();
}

class marbleState extends State<marble> {
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController costController = TextEditingController();
  String selectedWastage = 'Default';
  String selectedSize = 'Default';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marble Calculator"),
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
                'lib/assets/logos/Logo4.png',
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
                        controller: lengthController,
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
                        controller: widthController,
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
                        value: selectedWastage, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedWastage = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '5% Wastage',
                          '10% Wastage',
                          '15% Wastage',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "CHB Wastage",
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
                          '.40m x .20m',
                          '.30m x .20m',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Marble Size",
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
                      double marbleSize = 0.0;
                      double length = double.parse(lengthController.text);
                      double width = double.parse(widthController.text);
                      double cost = double.parse(costController.text);
                      double wastagePercentage = 0.0;

                      if (selectedWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedSize == '.40m x .20m') {
                        marbleSize = 0.08;
                      } else if (selectedSize == '.30m x .20m') {
                        marbleSize = 0.06;
                      }

                      double area = length * width;
                      print("Area: $area");

                      int marbleNeed = (area / marbleSize).ceil();
                      print("Marble Needed: $marbleNeed");

                      // Round up to the nearest whole number for the CHB needed
                      double totalcost = area * cost;
                      print("Area: $totalcost");

                      int wastage =
                          (wastagePercentage * marbleNeed).ceil().toInt();
                      print("Wastage: $wastage");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                          date: DateTime.now(),
                          calculatorType: "MArble Estimator",
                          material: "Marble",
                          area: area.toString() + "m²",
                          quantity: marbleNeed.toString() + "pcs",
                          totalamount: totalcost.toString() + "₱");

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Marble",
                        quantity: marbleNeed.toString() + "pcs",
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      // Navigate to the output page with the calculated values
                      Navigator.pushNamed(
                        context,
                        '/marbleOutput',
                        arguments: {
                          'area': area,
                          'Marble Needed': marbleNeed,
                          'totalcost': totalcost
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
