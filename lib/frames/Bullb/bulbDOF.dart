// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class bulbDef extends StatelessWidget {
  const bulbDef({super.key});

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
              "Bulb",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " 	In construction, the term 'bulb' typically refers to a light bulb, an essential element in both residential and commercial buildings. Modern construction incorporates a variety of bulb types, including incandescent, fluorescent, LED, and others, each with distinct characteristics such as color temperature, brightness, and energy consumption. Properly planned lighting design not only enhances visibility and safety within a construction but also contributes to the mood and functionality of different areas. The selection of bulbs in construction is, therefore, a thoughtful consideration, aligning with the architectural and functional requirements of the space while also addressing energy efficiency and sustainability concerns.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
