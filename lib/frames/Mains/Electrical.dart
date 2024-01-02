// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> electricalMaterials = [
  "Bulb",
  "Material 2",
  "Material 3",
  "Material 4",
];

// ignore: camel_case_types
class electrical extends StatelessWidget {
  const electrical({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Electrical Calculators"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
            switch (electricalMaterials[index]) {
              case "Bulb":
                Navigator.pushNamed(context, '/bulb');
                break;
              case "Plywood":
                Navigator.pushNamed(context, '/plywood');
                //
                break;
              case "Tiles":
                Navigator.pushNamed(context, '/tiles');
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
                electricalMaterials[index],
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
