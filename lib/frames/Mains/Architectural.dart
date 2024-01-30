import 'package:flutter/material.dart';

List<String> architecturalMaterials = [
  "Paint",
  "Tiles",
  "Wood Floor",
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
      'lib/assets/images/Arch.png',
      'lib/assets/images/Arch.png',
    ];

    return Scaffold(
      appBar: AppBar(
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
              case "Wood Floor":
                Navigator.pushNamed(context, '/woodfloorPages');
                break;
              case "Marble":
                Navigator.pushNamed(context, '/marblePages');
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
