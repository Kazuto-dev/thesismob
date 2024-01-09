// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class roofDef extends StatelessWidget {
  const roofDef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              " A critical component of building construction, serving as the protective cover that shields structures from the elements and environmental factors. A well-designed and properly installed roof enhances energy efficiency, insulation, and overall structural integrity. Roofing materials vary widely, offering options that cater to different climates, styles, and budget considerations. Whether it's a residential home, commercial building, or industrial facility, the choice of roofing has lasting implications for the durability, comfort, and visual identity of the entire structure.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
