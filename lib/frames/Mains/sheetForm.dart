// ignore_for_file: file_names, prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Color.fromARGB(255, 251, 248, 235),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            "Sheet Details",
            style: TextStyle(
              color: const Color.fromARGB(255, 241, 240, 240),
              fontSize: 22,
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
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
      // The rest of your Scaffold body goes here

      body: Container(
        child: SingleChildScrollView(
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
                        decoration:
                            InputDecoration(labelText: 'Enter Sheet ID'),
                        style: TextStyle(
                          color: Color.fromARGB(255, 29, 29, 29),
                          fontSize: 18,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: sheetNameController,
                        decoration:
                            InputDecoration(labelText: 'Enter Sheet Name'),
                        style: TextStyle(
                          color: Color.fromARGB(255, 33, 33, 33),
                          fontSize: 18,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
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
                            Provider.of<SheetInfoProvider>(context,
                                    listen: false)
                                .setSheetInfo(sheetId, sheetName);

                            await Future.delayed(Duration(seconds: 2));

                            setState(() {
                              isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Credentials added successfully!'),
                                duration: Duration(seconds: 5),
                              ),
                            );
                          } else {
                            print('Please enter both Sheet ID and Sheet Name');
                          }
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    fontSize: 20,
                                    fontFamily:
                                        GoogleFonts.poppins().fontFamily,
                                    fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}
