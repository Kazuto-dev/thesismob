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
        Color.fromARGB(255, 225, 160, 177),
        Color.fromARGB(255, 239, 182, 171),
        Color.fromARGB(255, 243, 223, 170),
        Color.fromARGB(255, 178, 216, 226),
        // Add more colors here for each index
      ];

      return buttonColors[index % buttonColors.length];
    }

    return _isLoading
        ? Scaffold(
            body: Center(
              child: Image.asset(
                'lib/assets/logos/SLogo.png',
                height: 100,
                width: 100,
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Color.fromARGB(255, 251, 248, 235),
              leading: IconButton(
                icon: Icon(Icons.history, size: 30),
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.summarize, size: 30),
                  onPressed: () {
                    Navigator.pushNamed(context, '/summary');
                  },
                ),
              ],
              centerTitle: true,
            ),
            body: Container(
              padding: EdgeInsets.only(top: 0), // Add bottom padding here
              color: Color.fromARGB(
                  255, 251, 248, 235), // Set the background color here
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Column(
                      children: [
                        Image.asset(
                          'lib/assets/logos/Logo2.png',
                          height: 50,
                          width: 250,
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: Text(
                            "Building Precision, Calculation one at a Time",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) => InkWell(
                        onTap: () {
                          switch (index) {
                            case 0:
                              Navigator.pushNamed(context, '/struc');
                              break;
                            case 1:
                              Navigator.pushNamed(context, '/arch');
                              break;
                            case 2:
                              Navigator.pushNamed(context, '/elec');
                              break;
                            case 3:
                              Navigator.pushNamed(context, '/plumb');
                              break;
                          }
                        },
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getButtonColor(index),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(15), // Add padding here
                                    child: Image.asset(
                                      imagePaths[index],
                                      height:
                                          120, // Adjust the height as desired
                                      width: 100, // Adjust the width as desired
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getLabelText(index),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily:
                                              GoogleFonts.poppins().fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
