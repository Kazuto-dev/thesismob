// ignore: file_names
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, duplicate_ignore, empty_statements, camel_case_types

import 'package:flutter/material.dart';

class instructions extends StatelessWidget {
  const instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      appBar: AppBar(
        title: Text("BuildQuantify Instructions"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Instruction For Application:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "This application is used to calculate the quantity and estimate the cost of different construction materials.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "You can use this application offline if you just want to calculate materials and online if you want to save your result on google sheet to have your record.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Here are the steps in how you can save your result on Google Sheet:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Go to Google sheet on your mobile phone or devices.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/SHEET.jpg',
              width: 500,
              height: 600,
            ),
            SizedBox(height: 16.0),
            Text(
              "Create a new sheet on your google sheet or use an existing one just remember the name of the sheet.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Go to sheet form on the application: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Make sure you have an internet connection so you can save your work or result on Google sheet.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Now, Click the key icon on the bottom right.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/homeboq.jpg',
              width: 500,
              height: 600,
            ),
            SizedBox(height: 16.0),
            Text(
              "Enter the sheet id and the sheet name where you want to save your result.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/sheetid.jpg',
              width: 500,
              height: 600,
            ),
            SizedBox(height: 16.0),
            Text(
              "This where you can get your Sheet ID.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "And your Sheet Name.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/getsheetid.jpg',
              width: 500,
              height: 600,
            ),
            SizedBox(height: 16.0),
            Text(
              "Click Submit.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/submitsheet.jpg',
              width: 500,
              height: 600,
            ),
            SizedBox(height: 16.0),
            Text(
              "Then look for the key icon on top right and see if your information is saved in the credentials.",
              style: TextStyle(fontSize: 16),
            ),
            Image.asset(
              'lib/assets/images/credential.jpg',
              width: 500,
              height: 600,
            ),
          ],
        ),
      ),
    );
  }
}
