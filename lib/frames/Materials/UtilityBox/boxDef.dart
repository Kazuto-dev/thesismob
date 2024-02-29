// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class boxDef extends StatelessWidget {
  const boxDef({Key? key}) : super(key: key);

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
              "Utility Box Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Utility box is typically a container or enclosure used to house electrical components, such as switches, outlets, or circuit breakers. The quantity would depend on factors such as the size of the building, the number of electrical devices needed, and the layout of the electrical system.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece of utility box.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://shop.wilcon.com.ph/catalogsearch/result/?q=Utility%20Box",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
