// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_final_fields, unused_import

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:thesismob/frames/insulation/insulation.dart';
import 'package:thesismob/frames/insulation/insulationOutput.dart';
import 'package:thesismob/frames/insulation/insulationDef.dart';
import 'package:thesismob/frames/insulation/insulationSolution.dart';

class insulationpages extends StatefulWidget {
  const insulationpages({Key? key}) : super(key: key);

  @override
  _pagesState createState() => _pagesState();
}

class _pagesState extends State<insulationpages> {
  int _selectedIndex = 0;

  void _navigateBot(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> pages = [
    insulation(),
    insulationDef(),
    insulationSol(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15.0,
            vertical: 20.0,
          ),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white,
            activeColor: Colors.white,
            tabBackgroundColor: Colors.grey.shade800,
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateBot,
            padding: EdgeInsets.all(16),
            tabs: [
              GButton(icon: Icons.calculate, text: 'Caculator'),
              GButton(icon: Icons.article, text: 'Definition'),
              GButton(icon: Icons.lightbulb, text: 'Solution'),
            ],
          ),
        ),
      ),
    );
  }
}
