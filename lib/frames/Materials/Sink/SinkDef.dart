
import 'package:flutter/material.dart';

// ignore: camel_case_types
class sinkdef extends StatelessWidget {
  const sinkdef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Definition of Terms")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/plumb');
          },
        ),
      ),
    );
  }
}
