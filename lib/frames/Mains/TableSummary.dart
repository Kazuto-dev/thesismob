import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';

class summary extends StatefulWidget {
  @override
  _summaryState createState() => _summaryState();
}

class _summaryState extends State<summary> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Calculation Summary"),
        ),
        centerTitle: true,
      ),
    );
  }
}
