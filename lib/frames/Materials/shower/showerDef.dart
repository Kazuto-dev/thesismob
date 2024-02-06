// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class showerdef extends StatelessWidget {
  const showerdef({Key? key}) : super(key: key);

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
              "Shower Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Shower quantity refers to the number of shower units installed in a building or facility, determined by factors such as occupancy, usage needs, and building codes. It is crucial for efficient space utilization and meeting the requirements of the intended users in areas like bathrooms, gyms, or residential buildings.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Shower Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Shower type refers to the specific design or style of a shower unit, each catering to different preferences, spatial considerations, and functionalities. The term encompasses a variety of shower designs.Choosing a specific shower type depends on factors such as available space, aesthetic preferences, and desired features for an optimal showering experience.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "TPrice of shower fixture or accessory per piece.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
