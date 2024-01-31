// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> plumbingMaterials = [
  "PVC Pipes",
  "Lavatory Sink",
  "Toilet",
  "Material 4",
];

// ignore: camel_case_types
class plumbing extends StatelessWidget {
  const plumbing({Key? key});

  @override
  Widget build(BuildContext context) {
    List<String> plumbingMaterialImages = [
      'lib/assets/images/Hose(noBG).png',
      'lib/assets/images/sink.png',
      'lib/assets/images/toilet.png',
      'lib/assets/images/faucet.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Plumbing Calculators"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: plumbingMaterials.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (plumbingMaterials[index]) {
              case "PVC Pipes":
                Navigator.pushNamed(context, '/pvcpages');
                break;
              case "Lavatory Sink":
                Navigator.pushNamed(context, '/Sinkpages');
                break;
              case "Toilet":
                Navigator.pushNamed(context, '/toiletpages');
                break;
              case "Material 4":
                Navigator.pushNamed(context, '/faucetpages');
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              plumbingMaterialImages[index],
              width: 300, // Adjust the width as per your requirement
              height: 300, // Adjust the height as per your requirement
            ),
          ),
        ),
      ),
    );
  }
}
