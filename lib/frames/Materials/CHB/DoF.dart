// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

// ignore: camel_case_types
class DoF extends StatelessWidget {
  const DoF({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Definition of Terms"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/struc');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Concrete Hollow Blocks (CHB)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Concrete hollow blocks or CHBs are modular materials used in construction. They have a hollow core, usually more than 25% of their total area, hence they are called “hollow blocks.” The hollow area allows insulation against heat, moisture, and sound.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
