// ignore_for_file: file_names, prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class DoFTiles extends StatelessWidget {
  const DoFTiles({super.key});

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
              "Tiles",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Tiles are versatile and integral elements in construction and interior design, commonly employed for surfacing floors, walls, and various spaces. These thin, flat pieces of material, often made from ceramics, porcelain, natural stone, or glass, come in an extensive array of sizes, shapes, colors, and patterns. Whether used to enhance the functionality of a kitchen or bathroom, create intricate mosaic designs, or add a touch of sophistication to living spaces, tiles serve both practical and decorative purposes.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
