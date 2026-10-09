import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<String> architecturalMaterials = [
  "Paint",
  "Tiles",
  "Roof",
  "Carpet",
  "Wallpaper",
];

List<String> structuralMaterialImages = [
  'lib/assets/images/Paint.png',
  'lib/assets/images/Tiles.png',
  'lib/assets/images/roof.png',
  'lib/assets/images/Carpet.png',
  'lib/assets/images/Wallpaper.png',
];

class architectural extends StatefulWidget {
  const architectural({Key? key});

  @override
  State<architectural> createState() => _ArchitecturalState();
}

class _ArchitecturalState extends State<architectural> {
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
    return _isLoading
        ? Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            body: Center(
              child: Image.asset(
                'lib/assets/images/Arch.png',
                height: 100,
                width: 100,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Color.fromARGB(255, 255, 255, 255),
            appBar: AppBar(
              toolbarHeight: 150.0,
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
                      'lib/assets/logos/Z_Architectural.png',
                      height: 90,
                      width: 90,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      'Architectural Materials',
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
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/mainpage');
                  },
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [],
                ),
              ),
            ),
            body: Container(
              padding: EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: architecturalMaterials.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (index == 0) {
                          Navigator.pushNamed(context, '/paintPages');
                        } else if (index == 1) {
                          Navigator.pushNamed(context, '/tilesPages');
                        } else if (index == 2) {
                          Navigator.pushNamed(context, '/roofPages');
                        } else if (index == 3) {
                          Navigator.pushNamed(context, '/carpetPages');
                        } else if (index == 4) {
                          Navigator.pushNamed(context, '/wallpaperPages');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 255, 255, 255),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
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
                            width: 60,
                            height: 60,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
  }
}
