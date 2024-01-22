import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

class cBox extends StatefulWidget {
  const cBox({super.key});
  @override
  cBoxState createState() => cBoxState();
}

class cBoxState extends State<cBox> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conjunction Box Calculator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/elec');
          },
        ),
      ),
    );
  }
}
