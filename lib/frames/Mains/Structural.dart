// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

List<String> structuralMaterials = [
  "CHB",
  "Plywood",
  "Tiles",
  "Roof",
];

// ignore: camel_case_types
class structural extends StatelessWidget {
  const structural({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Structural Calculators"),
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
                switch (structuralMaterials[index]) {
                  case "CHB":
                    Navigator.pushNamed(context, '/chb');
                    break;
                  case "Plywood":
                    Navigator.pushNamed(context, '/ply');
                    break;
                  case "Tiles":
                    Navigator.pushNamed(context, '/tiles');
                    break;
                  case "Roof":
                    Navigator.pushNamed(context, '/box');
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
                    structuralMaterials[index],
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 226, 226, 226),
                    ),
                  ),
                ),
              ))),
    );
  }
}
