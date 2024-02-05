// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class roofDef extends StatelessWidget {
  const roofDef({super.key});

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
              "Roof",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " A roof is the uppermost covering of a building or structure, providing protection from weather elements such as rain, snow, sunlight, and wind. Roofs serve the essential function of sheltering the interior space beneath them and play a crucial role in the overall structure and design of a building. Roofs can be constructed using various materials, including shingles, tiles, metal, or concrete, and they come in different shapes and styles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Rib Roof",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " A rib roof typically refers to a type of roofing structure characterized by the use of ribs or raised ridges along the surface of the roof. These ribs can add strength and support to the roof structure while also creating a distinctive architectural appearance. Rib roofs are often associated with certain types of metal roofing systems or architectural designs that incorporate ribbed patterns for both functional and aesthetic purposes. The ribs can enhance the structural integrity of the roof and may also contribute to efficient water drainage.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
