import 'package:flutter/material.dart';

// ignore: camel_case_types
class sinkdef extends StatelessWidget {
  const sinkdef({super.key});

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
              "Sink Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Sink refers to the number of sinks in a particular context, such as a building, room, or facility. A sink is a fixture designed for washing hands, dishes, or other items and is commonly found in kitchens, bathrooms, and utility areas.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Sink-type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "There are various types of sinks designed for different purposes and settings. The choice of sink type depends on the intended use, available space, and aesthetic preferences. Each type of sink has its advantages and is suitable for specific applications. You may select the type of sink based on architectural and engineering plans.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price of sink per piece.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://shop.wilcon.com.ph/products/plumbing/sink.html?p=3",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://citihardware.com/dasmarinas/kitchen/100625721-sink-bremen-zw-sbw0619-5045-sb-500x450x230-ss304-w-strainer.html",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
