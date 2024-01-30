// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> structuralMaterials = [
  "CHB",
  "Plywood",
  "Insulation",
  "Roof",
];

// ignore: camel_case_types
class structural extends StatelessWidget {
  const structural({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> structuralMaterialImages = [
      'lib/assets/images/CHB(noBG).png',
      'lib/assets/images/Plywood(noBG).png',
      'lib/assets/images/Struc.png',
      'lib/assets/images/Roof(noBG).png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Structural Calculators"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: structuralMaterials.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (structuralMaterials[index]) {
              case "CHB":
                Navigator.pushNamed(context, '/CHBpages');
                break;
              case "Plywood":
                Navigator.pushNamed(context, '/plywoodPages');
                break;
              case "Insulation":
                Navigator.pushNamed(context, '/insulationPages');
                break;
              case "Roof":
                Navigator.pushNamed(context, '/roofPages');
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
