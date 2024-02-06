// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class paintDef extends StatelessWidget {
  const paintDef({super.key});

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
              "Paint",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "   Beyond its role in providing a protective layer to surfaces, such as walls and ceilings, paint contributes significantly to the overall design and ambiance of a space. It allows for personalization, creativity, and the expression of architectural style. The process of selecting paint involves considerations such as color, finish, and durability, ensuring that it aligns with both the practical requirements and the desired aesthetic of a construction project. Whether used to refresh the appearance of existing structures or to finalize the finishing touches on newly built spaces, paint stands as a versatile and essential component in the construction industry.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Area Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area length refers to the measurement of the longest dimension of a surface, such as a wall or ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Area Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Area width refers to the measurement of the shorter dimension of a surface, such as a wall or a ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Number of Coats",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "The number of coats required for paint coverage depends on factors like surface type, paint color, and desired finish. Primer is often recommended before applying two or more top coats. Darker colors, porous surfaces, or textured walls may need extra coats. Follow the manufacturer's instructions for the specific paint product to achieve optimal coverage and finish.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.0),
            Text(
              "Paint Coverage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              "Paint coverage refers to the area that a specific amount of paint can cover on a surface. It is usually measured in square feet or square meters per gallon or liter of paint. Understanding paint coverage is important when planning a painting project, as it helps determine how much paint you need to purchase based on the size of the surfaces you intend to paint.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Manufacturers typically provide an estimated coverage rate on the paint can or product data sheet. This information helps consumers determine how much paint to buy based on the size of the area to be painted. However, it's important to note that these estimates are general guidelines, and actual coverage may vary based on several factors (surface porosity, texture, color, sheen, and paint quality) and the application method.",
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
