import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> structuralMaterials = [
  "Concrete Hollow\nBlocks",
  "Plywood",
  "Foam Insulation",
];

class structural extends StatefulWidget {
  const structural({Key? key}) : super(key: key);

  @override
  State<structural> createState() => _structuralState();
}

class _structuralState extends State<structural> {
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

  @override
  Widget build(BuildContext context) {
    Color _getButtonColor(int index) {
      List<Color> buttonColors = [
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
      ];

      return buttonColors[index % buttonColors.length];
    }

    List<String> structuralMaterialImages = [
      'lib/assets/images/CHB.png',
      'lib/assets/images/Plywood.png',
      'lib/assets/images/Insulation.png',
    ];

    return _isLoading
        ? Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            body: Center(
              child: Image.asset(
                'lib/assets/images/Struc.png',
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
                      'lib/assets/logos/Z_Structural.png',
                      height: 90,
                      width: 90,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      'Structural Materials',
                      style: TextStyle(
                        color: Color.fromARGB(255, 232, 232, 232),
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
                  icon: Icon(Icons.arrow_back),
                  color: Colors.white, // Add white color to the button
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
                  itemCount: structuralMaterials.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        child: ElevatedButton(
                          onPressed: () {
                            if (index == 0) {
                              Navigator.pushNamed(context, '/CHBpages');
                            } else if (index == 1) {
                              Navigator.pushNamed(context, '/plywoodPages');
                            } else if (index == 2) {
                              Navigator.pushNamed(context, '/insulationPages');
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
                                structuralMaterials[index],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Image.asset(
                                structuralMaterialImages[index],
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
