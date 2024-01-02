// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

// ignore: camel_case_types
class Solutions extends StatelessWidget {
  const Solutions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Solution"),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate), // Corrected icon
            label: "Calculator",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark_rounded), // Corrected icon
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/CHBSolution');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/CHBDef');
          }
        },
      ),
    );
  }
}
