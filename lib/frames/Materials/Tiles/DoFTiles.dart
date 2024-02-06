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
            SizedBox(height: 15.0),
            Text(
              "Room Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Room length refers to the measurement of the longest dimension of a room, typically measured from one end to the other. It represents the linear distance along one of the walls and gives an indication of the overall size of the room in that particular direction.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Room Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Room width refers to the measurement of the distance between the two parallel walls that form the sides of a room. It is the dimension that runs perpendicular to the length of the room. The width, along with the length and height, contributes to the overall spatial characteristics of the room.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Tile Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Tile size refers to the physical dimensions of individual tiles used in flooring, wall covering, or other tiling applications. Tiles come in various sizes, and the choice of size depends on factors such as the intended use, design preferences, and the dimensions of the space.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Selection of tile size should be based on design specified on architectural plans or client’s design preference.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Tile Contingency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Tile contingency refers to an additional quantity of tiles that is ordered and kept in reserve during a tiling project. This extra amount is intended to account for potential mistakes, breakages, or unforeseen issues that may arise during the installation process. The purpose of having tile contingency is to ensure that there are enough tiles available to complete the project even if there are unexpected challenges.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Factors such as irregularities in the space, cutting errors, breakage during handling, or changes in design preferences can contribute to the need for extra tiles beyond the initially estimated quantity. By having a tile contingency, contractors or homeowners can avoid delays in the project and ensure that they have enough matching tiles to complete the installation without having to wait for additional orders.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per Piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price input of tile per piece.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
