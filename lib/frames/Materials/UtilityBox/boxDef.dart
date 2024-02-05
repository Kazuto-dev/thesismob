// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class boxDef extends StatelessWidget {
  const boxDef({Key? key}) : super(key: key);

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
