// ignore_for_file: file_names, use_super_parameters, unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

List<String> types = [
  "Structural",
  "Architectural",
  "Electrical",
  "Plumbing",
];

class FirstPage extends StatefulWidget {
  final String? displayName;

  const FirstPage({Key? key, this.displayName}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/assets/logos/Logo3.png', // Replace with the path to your image asset
          height: 100,
          width: 500, // Adjust the height as needed
        ),
        centerTitle: true,
      ),
      // The rest of your widget tree
      endDrawer: Drawer(
        backgroundColor: Color.fromARGB(255, 3, 124, 9),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: DrawerHeader(
                child: Text(
                  "History",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 226, 226, 226),
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(
                "January 1, 2023",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Handle the tap on January 1, 2023
              },
            ),
            ListTile(
              title: Text(
                "February 15, 2023",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Handle the tap on February 15, 2023
              },
            ),
            ListTile(
              title: Text(
                "March 30, 2023",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Handle the tap on March 30, 2023
              },
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
    );
  }
}
