// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

// ignore: camel_case_types
class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BuildQuantify"),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Color.fromARGB(255, 207, 175, 250),
        child: ListView(
          children: [
            DrawerHeader(
              child: Text(
                "BuildQuantify",
                style: TextStyle(
                  fontSize: 30,
                  color: const Color.fromARGB(255, 14, 14, 14),
                ),
              ),
            ),
            // Add other ListTile items as needed
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("M A T E R I A L S"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/materials');
              },
            ),
          ],
        ),
      ),
    );
  }
}
