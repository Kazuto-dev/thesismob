import 'package:flutter/material.dart';

// ignore: camel_case_types
class faucetDef extends StatelessWidget {
  const faucetDef({super.key});

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
              "Faucet Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Faucet quantity refers to the number of faucet units installed in a particular building, area, or facility. A faucet is a device that controls the flow of water and is commonly found in kitchens, bathrooms, utility rooms, and other spaces where water access is required.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Faucet Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Faucet type refers to the specific design or style of a water delivery device used to control the flow of water in plumbing fixtures. Faucets come in various types, each designed for different purposes, preferences, and settings. The choice of faucet type depends on factors such as the style of the space, functionality requirements, and personal preferences. Different faucet types offer varying features and aesthetics to meet the needs of specific applications and design styles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price of faucet fixture or accessory per piece.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
