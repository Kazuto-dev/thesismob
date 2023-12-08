// ignore_for_file: prefer_const_constructors, duplicate_ignore, unused_import

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Drawer.dart';
import 'package:thesismob/frames/Materials.dart';
import 'package:thesismob/frames/CHB/CHB.dart';
import 'package:thesismob/frames/Plywood/Plywood.dart';
import 'package:thesismob/frames/CHB/Solutions.dart';
import 'package:thesismob/frames/CHB/DoF.dart';

void main() {
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
        // ignore: prefer_const_constructors
        '/materials': (context) => SecondPage(),
        '/chb': (context) => test1(),
        '/ply': (context) => test2(),
        '/solution': (context) => Solutions(),
        '/Definition': (context) => DoF(),
      },
    );
  }
}
