// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> electricalMaterials = [
  "Bulb",
  "Switch",
  "Conjunction Box",
  "Material 4",
];

// ignore: camel_case_types
class electrical extends StatelessWidget {
  const electrical({Key? key});

  @override
  Widget build(BuildContext context) {
    List<String> electricalMaterialImages = [
      'lib/assets/images/Bulb(noBG).png',
      'lib/assets/images/switch.png',
      'lib/assets/images/JB.png',
      'lib/assets/images/suck.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Electrical Calculators"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: electricalMaterials.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (electricalMaterials[index]) {
              case "Bulb":
                Navigator.pushNamed(context, '/bulbPages');
                break;
              case "Switch":
                Navigator.pushNamed(context, '/switchPages');
                break;
              case "Conjunction Box":
                Navigator.pushNamed(context, '/cbPages');
                break;
              case "Material 4":
                Navigator.pushNamed(context, '/socketpages');
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              electricalMaterialImages[index],
              width: 300, // Adjust the width as per your requirement
              height: 300, // Adjust the height as per your requirement
            ),
          ),
        ),
      ),
    );
  }
}
