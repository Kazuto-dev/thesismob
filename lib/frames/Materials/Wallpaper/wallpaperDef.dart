// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class wallpaperDef extends StatelessWidget {
  const wallpaperDef({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Definition of Terms"),
        centerTitle: true,
      ),
    );
  }
}
