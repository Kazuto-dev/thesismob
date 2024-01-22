// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class roofSol extends StatelessWidget {
  const roofSol({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Solution"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How do I calculate the roof area?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "To calculate the area of your roof:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-  Begin with calculating the area of your house in a plane parallel to the ground.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-  Determine the size of the roof that you will use.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-    Once you know these values, you will be able to calculate the roof area.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-     Then, use the following equation to find the number of roof needed:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "roof needed = area of the house / roof size",
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "-  then last is the cost estimation and to get this we will use:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "cost = roof needed * Price per sheet",
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
