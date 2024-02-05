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
          ],
        ),
      ),
    );
  }
}
