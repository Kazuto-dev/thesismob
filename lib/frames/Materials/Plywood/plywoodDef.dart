// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class plywoodDef extends StatelessWidget {
  const plywoodDef({super.key});

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
              "Plywood",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " A foundational and indispensable material in construction, renowned for its structural strength, versatility, and reliability. Plywood's inherent strength allows it to efficiently distribute loads, making it a preferred choice for structural components in residential, commercial, and industrial construction projects. Its ease of use, cost-effectiveness, and adaptability to different construction needs make plywood a key player in the construction industry, contributing to the stability and longevity of structures worldwide.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Area Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area length refers to the measurement of the longest dimension of a surface, such as a wall or ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Area Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area width refers to the measurement of the shorter dimension of a surface, such as a wall or a ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Plywood size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "The most common and standard size for plywood sheets is 4’ by 8’ used in construction and carpentry. It is the size always available in the Philippine market.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Plywood Contingency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Plywood contingency refers to an additional amount or provision set aside in a construction project to account for unforeseen circumstances or changes related to the quantity of plywood needed. This might involve allocating an extra percentage of plywood sheets beyond the initially estimated quantity. This extra allowance helps mitigate the risk of running short on materials and provides flexibility in adapting to any changes or unexpected events during the construction project.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price input of CHB per piece.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.theprojectestimate.com/plywood-price-list/",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
