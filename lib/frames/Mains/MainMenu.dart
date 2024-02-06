// ignore_for_file: file_names, use_super_parameters, unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstPage extends StatefulWidget {
  final String? displayName;

  const FirstPage({Key? key, this.displayName}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final List<String> imagePaths = [
    "lib/assets/images/Struc.png",
    "lib/assets/images/Arch.png",
    "lib/assets/images/Elec.png",
    "lib/assets/images/Plumbing.png",
  ];

  String _getLabelText(int index) {
    List<String> labels = [
      "Structural",
      "Architectural",
      "Electrical",
      "Plumbing"
    ];
    return labels[index % labels.length];
  }

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Color _getButtonColor(int index) {
      List<Color> buttonColors = [
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
      ];

      return buttonColors[index % buttonColors.length];
    }

    return _isLoading
        ? Scaffold(
            body: Center(
              child: Image.asset(
                'lib/assets/logos/Logo2.png',
                height: 200,
                width: 200,
              ),
            ),
          )
        : Scaffold(
            body: Stack(
              children: [
                Image.asset(
                  'lib/assets/images/BG1.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 30.0,
                  right: 5.0,
                  child: IconButton(
                    icon: Icon(
                      Icons.lightbulb,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/instructions');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 90.0),
                  child: Container(
                    color: Color.fromARGB(255, 251, 248, 235).withOpacity(
                        0.0), // Set the background color here with opacity
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Image.asset(
                                  'lib/assets/images/BQ2.png',
                                  height: 120,
                                  width: 350,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Text(
                                  "Building Precision,\n Calculation one at a Time",
                                  textAlign: TextAlign
                                      .center, // Add text alignment here
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily:
                                        GoogleFonts.poppins().fontFamily,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 10.0, right: 10.0),
                            child: GridView.builder(
                              itemCount: imagePaths.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 10.0,
                              ),
                              itemBuilder: (context, index) => InkWell(
                                onTap: () {
                                  switch (index) {
                                    case 0:
                                      Navigator.pushNamed(
                                          context, '/strucPages');
                                      break;
                                    case 1:
                                      Navigator.pushNamed(
                                          context, '/archPages');
                                      break;
                                    case 2:
                                      Navigator.pushNamed(
                                          context, '/elecPages');
                                      break;
                                    case 3:
                                      Navigator.pushNamed(
                                          context, '/plumbPages');
                                      break;
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(
                                      10.0), // Add padding to all sides
                                  decoration: BoxDecoration(
                                    color: _getButtonColor(index),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(
                                            0, 3), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        imagePaths[index],
                                        height: 120,
                                        width: 80,
                                      ),
                                      Text(
                                        _getLabelText(index),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily:
                                              GoogleFonts.poppins().fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
