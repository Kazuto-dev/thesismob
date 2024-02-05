// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_final_fields, unused_import

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:thesismob/frames/Mains/Instructions.dart';
import 'package:thesismob/frames/Mains/MainMenu.dart';
import 'package:thesismob/frames/Mains/Plumbing.dart';
import 'package:thesismob/frames/Mains/sheetForm.dart';
import 'package:thesismob/frames/Mains/tableSummary.dart';
import 'package:thesismob/frames/Mains/Electrical.dart';
import 'package:thesismob/frames/Mains/displayHistory.dart';

class plumPages extends StatefulWidget {
  const plumPages({Key? key}) : super(key: key);

  @override
  _pagesState createState() => _pagesState();
}

class _pagesState extends State<plumPages> {
  int _selectedIndex = 0;

  void _navigateBot(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  final List<Widget> pages = [
    plumbing(),
    SheetInfoInput(),
    HistoryScreen(),
    Summary(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Color.fromARGB(255, 251, 248, 235),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 25.0,
            vertical: 5.0,
          ),
          child: GNav(
            backgroundColor: Color.fromARGB(255, 251, 248, 235),
            color: Color.fromARGB(255, 39, 39, 39),
            activeColor: const Color.fromARGB(255, 71, 71, 71),
            tabBackgroundColor: Color.fromARGB(255, 214, 214, 214),
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateBot,
            padding: EdgeInsets.all(16),
            tabs: [
              GButton(
                icon: Icons.home_filled,
                iconSize: 30,
              ),
              GButton(
                icon: Icons.file_copy_rounded,
                iconSize: 30,
              ),
              GButton(
                icon: Icons.history,
                iconSize: 30,
              ),
              GButton(
                icon: Icons.view_list_rounded, // Added a new button icon
                iconSize: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
