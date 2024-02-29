import 'package:flutter/material.dart';

// ignore: camel_case_types
class toiletdef extends StatelessWidget {
  const toiletdef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: Text("Definition of Terms")),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Toilet Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Toilet quantity refers to the number of toilet units installed in a particular building, area, or facility. It is a crucial aspect of planning and designing spaces, such as restrooms or bathrooms, and is essential for providing adequate facilities for occupants.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Toilet Fixture",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Toilet fixture refers to the complete unit or assembly that includes the necessary components for the disposal of human waste. ",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price of toilet fixture or accessory per piece.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://shop.wilcon.com.ph/catalogsearch/result/?q=shower&product_list_order=relevance&product_list_dir=desc",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
