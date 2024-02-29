// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class DoF extends StatelessWidget {
  const DoF({Key? key}) : super(key: key);

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
              "CHB",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Concrete hollow blocks are construction materials commonly used in building walls.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "Wall Height",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Wall height refers to the vertical measurement from the floor to the ceiling or the top of the wall. It represents the distance along the upright structure of a wall, indicating how tall the wall is. Wall height can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "Wall Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Wall width refers to the horizontal measurement from a wall to another. It is usually described in terms of linear feet or meters, representing the horizontal distance between two endpoints or the total span of the wall. Wall width can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "CHB Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "The size of concrete hollow blocks can vary, but they are typically identified by their width, height, and length. Common sizes include:\n"
              "4 inches: This is a standard width for smaller applications.\n"
              "5 inches: A commonly used size for both residential and commercial construction.\n"
              "6 inches: Larger and heavier blocks, often used for load-bearing walls or firewalls.\n"
              "The length and height of CHBs can also vary, and they may have one or more hollow cores running through them, providing insulation and reducing the overall weight. The specific dimensions of concrete hollow blocks depend on regional standards, construction requirements, and the intended use in a building project.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "CHB Contingency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "CHB contingency refers to an additional amount or provision set aside to address unforeseen circumstances or changes in project requirements. It’s an extra allocation of CHBs beyond the initially estimated quantity. This allowance could account for potential changes in design, unexpected construction challenges, or variations in the actual number of blocks needed. It is a practical approach to mitigate the risk of running short on materials during the construction process.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24.0), // Adjust the spacing as needed
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
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
              "https://www.google.com/maps/uv?pb=!1s0x32fff3630267848b%3A0x9394e7120eb15b2c!3m1!7e131!4s!5sNEW%20ROCKS%20INC.!15sCgIgAQ&hl=en&imagekey=!1e10!2sAF1QipNO3DEL4l-e1igfzEg0dHT3CiGQT1uA1kL30b0C",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
