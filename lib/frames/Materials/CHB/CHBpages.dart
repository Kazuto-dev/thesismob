import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:thesismob/frames/Materials/CHB/CHB.dart';
import 'package:thesismob/frames/Materials/CHB/DoF.dart';
import 'package:thesismob/frames/Materials/CHB/Solutions.dart';

class pages extends StatefulWidget {
  const pages({Key? key}) : super(key: key);

  @override
  _PagesState createState() => _PagesState();
}

class _PagesState extends State<pages> {
  int _selectedIndex = 0;

  void _navigateBot(int index) {
    if (index == 1) {
      // Open drawer when the first tab is clicked
      _openBottomDrawer();
    } else if (index == 2) {
      // Open drawer when the first tab is clicked
      _openBottomDrawer1();
    } else if (index == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text('Are you sure you want to go to the home page?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/mainpage');
                },
                child: Text(
                  'Confirm',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Navigate to other pages for the rest of the tabs
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  final List<Widget> pages = [
    CHB(),
    DoF(),
    Solutions(),
  ];

  void _openBottomDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // Customize the drawer content as needed
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            color: Colors.white,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 2,
                ),
                child: DoF(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openBottomDrawer1() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // Customize the drawer content as needed
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            height: MediaQuery.of(context).size.height / 2,
            color: Colors.white,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height / 2,
                ),
                child: Solutions(),
              ),
            ),
          ),
        );
      },
    );
  }

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
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateBot,
            padding: EdgeInsets.all(16),
            tabs: [
              GButton(
                icon: Icons.home,
                iconSize: 30,
              ),
              GButton(
                icon: Icons.article,
                iconSize: 30,
              ),
              GButton(
                icon: Icons.lightbulb,
                iconSize: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
