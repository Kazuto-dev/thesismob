import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> architecturalMaterials = [
  "Paint",
  "Tiles",
  "Roof",
  "Marble",
];

// ignore: camel_case_types
class architectural extends StatelessWidget {
  const architectural({Key? key});

  @override
  Widget build(BuildContext context) {
    List<String> structuralMaterialImages = [
      'lib/assets/images/paint-bucket.png',
      'lib/assets/images/tile.png',
      'lib/assets/images/roof.png',
      'lib/assets/images/Arch.png',
    ];

    Color _getButtonColor(int index) {
      List<Color> buttonColors = [
        Color.fromARGB(255, 225, 160, 177),
        Color.fromARGB(255, 239, 182, 171),
        Color.fromARGB(255, 243, 223, 170),
        Color.fromARGB(255, 178, 216, 226),
      ];

      return buttonColors[index % buttonColors.length];
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 251, 248, 235),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 251, 248, 235),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "Architectural Calculators",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/mainpage');
            },
          ),
        ),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: ListView.builder(
            itemCount: architecturalMaterials.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  // ... your other settings ...
                  child: ElevatedButton(
                    onPressed: () {
                      if (index == 0) {
                        Navigator.pushNamed(context, '/paintPages');
                      } else if (index == 1) {
                        Navigator.pushNamed(context, '/tilesPages');
                      } else if (index == 2) {
                        Navigator.pushNamed(context, '/roofPages');
                      } else {
                        Navigator.pushNamed(context, '/error');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      primary: _getButtonColor(index),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          architecturalMaterials[index],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Image.asset(
                          structuralMaterialImages[index],
                          width: 100,
                          height: 100,
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
