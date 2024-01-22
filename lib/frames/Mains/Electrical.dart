// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> electricalMaterials = [
  "Bulb",
  "Switch",
  "Conjunction \nBox",
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
            switch (electricalMaterials[index]) {
              case "Bulb":
                Navigator.pushNamed(context, '/bulbPages');
                break;
              case "Switch":
                Navigator.pushNamed(context, '/switchPages');
                //
                break;
              case "Conjunction \nBox":
                Navigator.pushNamed(context, '/cbPages');
                break;
              case "Roof":
                Navigator.pushNamed(context, '/');
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
