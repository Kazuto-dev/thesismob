// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> architecturalMaterials = [
  "Paint",
  "Foam Insulation",
  "Wood Floor",
  "Material 4",
];

// ignore: camel_case_types
class architectural extends StatelessWidget {
  const architectural({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: GridView.builder(
        itemCount: 4,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (architecturalMaterials[index]) {
              case "Paint":
                Navigator.pushNamed(context, '/paintPages');
                break;
              case "Foam Insulation":
                Navigator.pushNamed(context, '/insulationPages');
                //
                break;
              case "Wood Floor":
                Navigator.pushNamed(context, '/woodfloorPages');
                break;
              case "Roof":
                Navigator.pushNamed(context, '/roof');
                break;
            }
          },
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 87, 148, 239),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                architecturalMaterials[index],
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 226, 226, 226),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
