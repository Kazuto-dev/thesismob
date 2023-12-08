// ignore: file_names
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, duplicate_ignore, empty_statements

import 'package:flutter/material.dart';

List<String> materialNames = [
  "CHB",
  "PLYWOOD",
  "STEEL",
  "BOX",
  "LAPTOP",
  "COMPUTER",
  "MOUSE",
  "ID",
  "SNACKS",
  "LOTION",
  "IPAD",
  "IPHONE",
];

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

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
              case "PLYWOOD":
                Navigator.pushNamed(context, '/ply');
                break;
              case "STEEL":
                Navigator.pushNamed(context, '/steel');
                break;
              case "BOX":
                Navigator.pushNamed(context, '/box');
                break;
              case "LAPTOP":
                Navigator.pushNamed(context, '/laptop');
                break;
              case "COMPUTER":
                Navigator.pushNamed(context, '/computer');
                break;
              case "MOUSE":
                Navigator.pushNamed(context, '/mouse');
                break;
              case "ID":
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
            color: Colors.blue,
            margin: EdgeInsets.all(5.0),
            height: 150.0, // Adjust the height as needed
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

      // ignore: prefer_const_constructors
      bottomNavigationBar: BottomNavigationBar(
        items: [
          //home
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: Colors.blue,
          ),
          //profile
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
            backgroundColor: Colors.blue,
          ),
          //settings
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
