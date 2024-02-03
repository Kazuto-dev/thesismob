import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> structuralMaterials = [
  "Concrete Hollow\nBlocks",
  "Plywood",
  "Foam Insulation",
  "?",
];

class structural extends StatelessWidget {
  const structural({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color _getButtonColor(int index) {
      List<Color> buttonColors = [
        Color.fromARGB(255, 225, 160, 177),
        Color.fromARGB(255, 239, 182, 171),
        Color.fromARGB(255, 243, 223, 170),
        Color.fromARGB(255, 178, 216, 226),
      ];

      return buttonColors[index % buttonColors.length];
    }

    List<String> structuralMaterialImages = [
      'lib/assets/images/brick.png',
      'lib/assets/images/surface.png',
      'lib/assets/images/insulating.png',
      'lib/assets/images/Struc.png',
    ];

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 251, 248, 235),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 251, 248, 235),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            "Structural Calculators",
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
            itemCount: structuralMaterials.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  // ... your other settings ...
                  child: ElevatedButton(
                    onPressed: () {
                      if (index == 0) {
                        Navigator.pushNamed(context, '/CHBpages');
                      } else if (index == 1) {
                        Navigator.pushNamed(context, '/plywoodPages');
                      } else if (index == 2) {
                        Navigator.pushNamed(context, '/insulationPages');
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
                          structuralMaterials[index],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
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
