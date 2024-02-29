// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class wiresDef extends StatelessWidget {
  const wiresDef({Key? key}) : super(key: key);

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
              "Electrical Linear Meter",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Electrical wires linear meter refers to the measurement of the length of electrical wires in linear meters. In this context, 'linear meter' indicates the straight-line distance or length of the electrical wire. The linear meter measurement for electrical wires is a practical way to estimate the quantity needed, plan installations, and manage material costs in various electrical and construction projects.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Electrical Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Electrical wire types refer to the various categories and classifications of wires used in electrical systems based on their composition, insulation, and intended applications. Different wire types are designed to meet specific requirements in terms of electrical conductivity, insulation properties, and environmental conditions.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per lenght",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price of electrical per length.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.askmediy.com/electrical-wire-size-calculator/",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.affordablecebu.com/load/technology/list_of_common_types_of_wires_in_the_philippines/7-1-0-30112",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
