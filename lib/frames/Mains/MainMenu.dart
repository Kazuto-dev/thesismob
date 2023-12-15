// ignore_for_file: file_names, use_super_parameters, unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/login.dart';

List<String> types = [
  "Structural",
  "Architectural",
  "Electrical",
  "Plumbing",
];

class FirstPage extends StatelessWidget {
  final String? displayName;

  const FirstPage({Key? key, this.displayName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/assets/logos/Logo3.png', // Replace with the path to your image asset
          height: 100,
          width: 500, // Adjust the height as needed
        ),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamed(context, '/materials');
          },
        ),
        centerTitle: true,
      ),
      // The rest of your widget tree
      endDrawer: Drawer(
        backgroundColor: Color.fromARGB(255, 96, 62, 142),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: DrawerHeader(
                child: Text(
                  "Hi $displayName",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 226, 226, 226),
                  ),
                ),
              ),
            ),
            // Add other ListTile items as needed
          ],
        ),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add the text at the top
          Container(
            padding: EdgeInsets.only(bottom: 100.0),
            child: Text(
              "Building Precision, Calculation one at a Time",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: GridView.builder(
                itemCount: 4,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    switch (types[index]) {
                      case "Structural":
                        Navigator.pushNamed(context, '/struc');
                        break;
                      case "Architectural":
                        Navigator.pushNamed(context, '/arch');
                        break;
                      case "Electrical":
                        Navigator.pushNamed(context, '/elec');
                        break;
                      case "Plumbing":
                        Navigator.pushNamed(context, '/plumb');
                        break;
                    }
                  },
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color.fromARGB(255, 148, 87, 239),
                      ),
                      margin: EdgeInsets.all(7.0),
                      height: 200.0,
                      width: 200.0,
                      child: Center(
                        child: Text(
                          types[index % types.length],
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 226, 226, 226),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          //home
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          //settings
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
            backgroundColor: Colors.blue,
          )
        ],
        onTap: (index) {
          // Handle the tap for each item
          if (index == 0) {
            Navigator.pushNamed(context, '/SolutionBox');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/DefenitionBox');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profilepage');
          }
        },
      ),
    );
  }
}
