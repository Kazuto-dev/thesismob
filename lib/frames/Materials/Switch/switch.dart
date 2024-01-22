// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

// ignore: camel_case_types
class MySwitch extends StatefulWidget {
  const MySwitch({super.key});

  @override
  State<MySwitch> createState() => MySwitchState();
}

class MySwitchState extends State<MySwitch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Switch Calculator"),
        centerTitle: true,
      ),
    );
  }
}
