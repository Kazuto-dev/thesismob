// ignore_for_file: prefer_const_constructors, duplicate_ignore, unused_import

//main components
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//Pages
import 'package:thesismob/frames/CHB/Output.dart';
import 'package:thesismob/frames/Mains/MainMenu.dart';
import 'package:thesismob/frames/Mains/Materials.dart';
import 'package:thesismob/frames/CHB/CHB.dart';
import 'package:thesismob/frames/Plywood/Plywood.dart';
import 'package:thesismob/frames/CHB/Solutions.dart';
import 'package:thesismob/frames/CHB/DoF.dart';
import 'package:thesismob/frames/Plywood/Solutions.dart';
import 'package:thesismob/frames/Plywood/DoF.dart';
import 'package:thesismob/frames/Tiles/DoFTiles.dart';
import 'package:thesismob/frames/Tiles/SolutionTiles.dart';
import 'package:thesismob/frames/Tiles/tiles.dart';
import 'package:thesismob/frames/Mains/overAllDoF.dart';
import 'package:thesismob/frames/Mains/overAllSolution.dart';
import 'package:thesismob/frames/Mains/Architectural.dart';
import 'package:thesismob/frames/Mains/Electrical.dart';
import 'package:thesismob/frames/Mains/Plumbing.dart';
import 'package:thesismob/frames/Mains/Structural.dart';
import 'package:thesismob/frames/Mains/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: prefer_const_constructors
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ignore: prefer_const_constructors
      home: FirstPage(),
      routes: {
        // ignore: prefer_const_constructors
        '/menu': (context) => FirstPage(),
        '/login': (context) => login(),
        // ignore: prefer_const_constructors
        '/materials': (context) => materialPage(),
        '/chb': (context) => CHB(),
        '/CHBoutput': (context) => chbOutput(),
        '/ply': (context) => plywood(),
        '/solution': (context) => Solutions(),
        '/definition': (context) => DoF(),
        '/solutionply': (context) => SolutionsPly(),
        '/definitionply': (context) => DoFPly(),
        '/solutiontiles': (context) => SolutionsTiles(),
        '/definitiontiles': (context) => DoFTiles(),
        '/tiles': (context) => tiles(),
        '/DefenitionBox': (context) => DOF(),
        '/SolutionBox': (context) => SOLUTION(),
        '/arch': (context) => architectural(),
        '/struc': (context) => structural(),
        '/plumb': (context) => plumbing(),
        '/elec': (context) => electrical(),
      },
    );
  }
}
