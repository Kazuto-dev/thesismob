// ignore_for_file: file_names, prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';
import 'package:thesismob/frames/Mains/sheetInfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SheetInfoInput extends StatefulWidget {
  @override
  _SheetInfoInputState createState() => _SheetInfoInputState();
}

class _SheetInfoInputState extends State<SheetInfoInput> {
  final TextEditingController sheetIdController = TextEditingController();
  final TextEditingController sheetNameController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSavedSheetInfo();
  }

  Future<void> loadSavedSheetInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedSheetInfo = prefs.getString('sheetInfo');

    if (savedSheetInfo != null) {
      final decodedSheetInfo = jsonDecode(savedSheetInfo);
      final sheetInfo = SheetInfo.fromJson(decodedSheetInfo);
      sheetIdController.text = sheetInfo.sheetId;
      sheetNameController.text = sheetInfo.sheetName;
    }
  }

  Future<void> saveSheetInfo(String sheetId, String sheetName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sheetInfo = SheetInfo(sheetId, sheetName);
    final encodedSheetInfo = jsonEncode(sheetInfo.toJson());
    prefs.setString('sheetInfo', encodedSheetInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Sheet Form')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
        actions: [
          // Any existing action buttons go here, if applicable
          IconButton(
            icon: Icon(Icons.key_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => displayCreds()),
              );
            },
          ),
        ],
      ),
      // The rest of your Scaffold body goes here

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logos/icons8-google-sheets-300.png',
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: sheetIdController,
                      decoration: InputDecoration(labelText: 'Enter Sheet ID'),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: sheetNameController,
                      decoration:
                          InputDecoration(labelText: 'Enter Sheet Name'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final String sheetId = sheetIdController.text;
                        final String sheetName = sheetNameController.text;

                        if (sheetId.isNotEmpty && sheetName.isNotEmpty) {
                          setState(() {
                            isLoading = true;
                          });

                          // Use the provider to set the sheet info
                          Provider.of<SheetInfoProvider>(context, listen: false)
                              .setSheetInfo(sheetId, sheetName);

                          await Future.delayed(Duration(seconds: 2));

                          setState(() {
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Credentials added successfully!'),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        } else {
                          print('Please enter both Sheet ID and Sheet Name');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary:
                            Color.fromARGB(255, 0, 149, 0), // Background color
                        onPrimary: Colors.white, // Text color
                        padding: EdgeInsets.all(12), // Button padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ), // Button shape with rounded corners
                        minimumSize: Size(double.infinity,
                            50), // Set minimum width and height
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class displayCreds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the sheet info from the provider
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Credentials')),
      ),
      body: Center(
        child: Text(
          'Sheet ID: ${sheetInfo?.sheetId}\nSheet Name: ${sheetInfo?.sheetName}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
