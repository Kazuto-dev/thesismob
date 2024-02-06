// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class pipeDef extends StatelessWidget {
  const pipeDef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Definition of Terms"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Linear Meter",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Linear meter refers to the measurement of the length of pipes in a straight line. It is a unit of length used to quantify the amount of pipe needed for a project. The length is measured in meters, and it represents the total linear distance of the pipes, considering any bends, curves, or straight sections. To calculate the linear meterage of pipes, you need to measure the actual length of each pipe section, account for any twists and turns, and sum up the total length.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "PVC Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "PVC length refers to the various sizes and lengths of PVC (Polyvinyl Chloride) pipes that are commercially available for purchase. PVC pipes come in a range of dimensions to suit different applications and project requirements. The lengths of PVC pipes can vary, and they are typically available in standard measurements.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "PVC Diameter",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "PVC diameter refers to the size or width of a PVC (Polyvinyl Chloride) pipe, and it's a critical dimension that influences the pipe's applications and compatibility with various systems. PVC pipes come in a range of diameters, and the selection of the appropriate size depends on the specific requirements of the intended use.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price of PVC pipe per piece",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
