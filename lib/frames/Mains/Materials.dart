// ignore: file_names
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, duplicate_ignore, empty_statements, camel_case_types

import 'package:flutter/material.dart';

List<String> materialNames = [
  "CHB",
  "Plywood",
  "Tiles",
  "Roof",
  "Bulb",
  "Socket",
  "Hose/Conduit",
  "Paint",
  "SNACKS",
  "LOTION",
  "IPAD",
  "IPHONE",
];

class materialPage extends StatelessWidget {
  const materialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      appBar: AppBar(title: Text("MATERIALS"), centerTitle: true),
      body: GridView.builder(
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        // Inside your GridView.builder:
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            switch (materialNames[index]) {
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
              case "Bulb":
                Navigator.pushNamed(context, '/laptop');
                break;
              case "Socket":
                Navigator.pushNamed(context, '/computer');
                break;
              case "Hose/Conduit":
                Navigator.pushNamed(context, '/mouse');
                break;
              case "Paint":
                Navigator.pushNamed(context, '/id');
                break;
              case "SNACKS":
                Navigator.pushNamed(context, '/snacks');
                break;
              case "LOTION":
                Navigator.pushNamed(context, '/lotion');
                break;
              case "IPAD":
                Navigator.pushNamed(context, '/ipad');
                break;
            }
            ;
          },
          child: Container(
            margin: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 87, 148, 239),
              borderRadius: BorderRadius.circular(20),
            ),
            height: 150.0, // Adjust the height as needed,
            width: 150.0, // Adjust the width as needed
            child: Center(
              child: Text(
                materialNames[index %
                    materialNames
                        .length], // Use index to access names from the list
                style: TextStyle(color: Colors.black, fontSize: 20.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
