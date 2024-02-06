// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> electricalMaterials = [
  "Bulb",
  "Switch",
  "Junction Box",
  "Outlet",
  "Electrical Wires",
  "Utility Box",
];

// ignore: camel_case_types
class electrical extends StatefulWidget {
  const electrical({Key? key});

  @override
  State<electrical> createState() => _electricalState();
}

class _electricalState extends State<electrical> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Widget build(BuildContext context) {
    List<String> electricalMaterialImages = [
      'lib/assets/images/Bulb.png',
      'lib/assets/images/Swi.png',
      'lib/assets/images/Junction Box.png',
      'lib/assets/images/Outlet.png',
      'lib/assets/images/Electrical Wires.png',
      'lib/assets/images/Utility Box.png',
    ];

    Color _getButtonColor(int index) {
      List<Color> buttonColors = [
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
      ];

      return buttonColors[index % buttonColors.length];
    }

    return _isLoading
        ? Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            body: Center(
              child: Image.asset(
                'lib/assets/images/Elec.png',
                height: 100,
                width: 100,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            appBar: AppBar(
              toolbarHeight: 150.0, // Adjust the height as needed
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 255, 189, 32),
                      Color.fromARGB(255, 221, 115, 2),
                    ],
                  ),
                ),
              ),
              title: Column(
                children: [
                  Container(
                    child: Image.asset(
                      'lib/assets/logos/Z_Electrical.png',
                      height: 90,
                      width: 90,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      'Electrical Materials',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 22,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              centerTitle: true,
              leading: Container(
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/mainpage');
                  },
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add more widgets if needed
                  ],
                ),
              ),
            ),
            body: Container(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: ListView.builder(
                  itemCount: electricalMaterials.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        child: ElevatedButton(
                          onPressed: () {
                            if (index == 0) {
                              Navigator.pushNamed(context, '/bulbPages');
                            } else if (index == 1) {
                              Navigator.pushNamed(context, '/switchPages');
                            } else if (index == 2) {
                              Navigator.pushNamed(context, '/cbPages');
                            } else if (index == 3) {
                              Navigator.pushNamed(context, '/socketPages');
                            } else if (index == 4) {
                              Navigator.pushNamed(context, '/wiresPages');
                            } else if (index == 5) {
                              Navigator.pushNamed(context, '/boxPages');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            primary: _getButtonColor(index),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                electricalMaterials[index],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Image.asset(
                                electricalMaterialImages[index],
                                width: 60,
                                height: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
  }
}
