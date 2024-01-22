// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class SolutionsTiles extends StatelessWidget {
  const SolutionsTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Solution"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "How many tile do I need? - Tile Estimator",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Just follow these steps using the tile calculator to estimate and to know the tiles needed in your project:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "- Enter the length and width of the tiles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "- Select your gap: Positive means there's a gap, zero means no gap, and a negative gap indicates overlapping tiles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-   Enter the dimensions of the space you want to tile (length and width or total area)",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-    Add your wastage to account for broken or problematic tiles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "-  Then you will know how many tiles you need.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Tiles Needed?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Returning to the mathematical aspect of tiling, let's determine the required number of tiles for your project is a straightforward process that revolves around the area you need to cover. Simply divide the total area to be tiled by the area of a single tile, and you're good to go. It's important to round up the result since tiles are not sold in fractions.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "number of tiles = area to tile / area of one tile",
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Even if you possess the know-how of tiling a floor, it's advisable to incorporate a margin of error in your calculations, considering the tendency of tiles to break during cutting. Our calculator accommodates this factor, factoring in extra tiles to determine the necessary number of boxes and the overall cost for tiling your show",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
