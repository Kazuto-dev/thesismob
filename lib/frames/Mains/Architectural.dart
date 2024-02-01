import 'package:flutter/material.dart';

List<String> architecturalMaterials = [
  "Paint",
  "Tiles",
  "Roof",
  "Marble",
];

// ignore: camel_case_types
class architectural extends StatelessWidget {
  const architectural({Key? key});

  @override
  Widget build(BuildContext context) {
    List<String> structuralMaterialImages = [
      'lib/assets/images/Paint(noBG).png',
      'lib/assets/images/Tiles(noBG).png',
      'lib/assets/images/Roof(noBG).png',
      'lib/assets/images/Arch.png',
    ];

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 229, 240, 255),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 229, 240, 255),
        title: Text("Architectural Calculators"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: architecturalMaterials.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (architecturalMaterials[index]) {
              case "Paint":
                Navigator.pushNamed(context, '/paintPages');
                break;
              case "Tiles":
                Navigator.pushNamed(context, '/tilesPages');
                //
                break;
              case "Roof":
                Navigator.pushNamed(context, '/roofPages');
                break;
              case "?":
                Navigator.pushNamed(context, '/?');
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              structuralMaterialImages[index],
              width: 300, // Adjust the width as per your requirement
              height: 300, // Adjust the height as per your requirement
            ),
          ),
        ),
      ),
    );
  }
}
