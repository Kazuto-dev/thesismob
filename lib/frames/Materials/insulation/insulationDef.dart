// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class insulationDef extends StatelessWidget {
  const insulationDef({super.key});

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
              "Foam Insulation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "   is made from polyethylene foam. An excellent material used as thermal insulation: roofs insulation, wall insulation, floor insulation, and air duct insulation.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Foil Laminated Insulation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "   Can be laminated with MPET reflective film or aluminum foil as an outer skin for increased durability and to reflect heat.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Adhesive Backed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "  Available with pressure sensitive adhesive for easy installation to air ducts and metal sheets.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Adhesive Backed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "  Available with pressure sensitive adhesive for easy installation to air ducts and metal sheets.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Area length refers to the measurement of the longest dimension of the ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Area width refers to the measurement of the shorter dimension of the ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Insulation Thickness",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Insulation thickness refers to the depth or thickness of the insulation material installed in a building's walls, ceilings, floors, or other areas to reduce heat transfer. The thickness of insulation is a critical factor in determining its effectiveness in providing thermal resistance (R-value).",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "To determine the required insulation thickness for a specific area, it's important to consider local building codes, energy efficiency standards, and the recommended R-values for the climate zone. You may refer to specifications indicated on your architectural or engineering plans.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Insulation Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Insulation size refers to the physical dimensions of insulation materials, such as the width and length of rolls. Common dimensions for insulation products include the width of rolls (e.g., 1 meter) and the length of batts (e.g., 50 meters).",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Insulation Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Insulation with aluminum sides typically refers to insulation materials that have a layer of aluminum on one or both sides. This aluminum layer serves various purposes, including enhancing the insulation's performance and providing additional features.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price per Roll",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price of insulation material per roll.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
