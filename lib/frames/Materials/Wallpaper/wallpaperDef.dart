// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class wallpaperDef extends StatelessWidget {
  const wallpaperDef({Key? key}) : super(key: key);

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
              "Wall Area Height",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Wall height refers to the vertical measurement from the floor to the ceiling or the top of the wall. It represents the distance along the upright structure of a wall, indicating how tall the wall is. Wall height can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Wall Area Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Wall width refers to the horizontal measurement from a wall to another. It is usually described in terms of linear feet or meters, representing the horizontal distance between two endpoints or the total span of the wall. Wall width can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Wallpaper Coverage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Wallpaper coverage refers to the area that a specific quantity of wallpaper can cover on a wall or surface, typically measured in square feet or square meters per roll or package. It considers factors like wall dimensions, pattern repeats, and a waste factor to determine the amount needed for a project. Manufacturers provide coverage information to help consumers estimate the quantity of wallpaper required based on the size of the area to be covered.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Price per gallon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Price input of tile per gallon.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
