// ignore_for_file: use_key_in_widget_constructors, camel_case_types, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';

class chbOutput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed by Navigator
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Extract values
    final double area = args['area'];
    final int totalCHB = args['totalCHB'];

    void insertSheet() {
      // TODO: Implement your logic for inserting a sheet
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Output Calculation"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logos/Logo4.png',
              width: 250,
              height: 250,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20), // Adjust the spacing as needed
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text(
                "Area: $area",
                style:
                    TextStyle(fontSize: 20), // Adjust the font size as needed
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Text(
                "CHB Needed: $totalCHB",
                style:
                    TextStyle(fontSize: 20), // Adjust the font size as needed
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chb');
              },
              child: Container(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'BACK',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Container(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'INSERT SHEET',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
